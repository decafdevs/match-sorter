import 'dart:core';
import 'package:diacritic/diacritic.dart';

enum Ranking {
  noMatch,
  matches,
  acronym,
  contains,
  wordStartsWith,
  startsWith,
  equal,
  caseSensitiveEqual
}

class Key {
  String key;
  Ranking? threshold;
  Ranking maxRanking;
  Ranking minRanking;

  Key(
    this.key, {
    this.threshold,
    this.maxRanking = Ranking.caseSensitiveEqual,
    this.minRanking = Ranking.noMatch,
  });
}

typedef Item = Map<String, String>;

List<Item> matchSorter({
  required String searchQuery,
  required List<Item> items,
  required List<Key> keys,
  Ranking threshold = Ranking.matches,
  bool keepDiacritics = false,
  BaseSortFn baseSort = _defaultBaseSort,
  SorterFn sorter = _defaultSorter,
}) {
  List<_RankedItem> _reduceItemsToRanked(List<_RankedItem> matches, Item item) {
    var rankingInfo = _getHighestRanking(
        searchQuery: searchQuery,
        item: item,
        keys: keys,
        threshold: threshold,
        keepDiacritics: keepDiacritics);
    if (rankingInfo.rank.index >= rankingInfo.keyThreshold.index) {
      matches.add(_RankedItem(item: item, rankingInfo: rankingInfo));
    }
    return matches;
  }

  Item _mapToItem(_RankedItem rankedItem) {
    return rankedItem.item;
  }

  var matchedItems = items.fold([] as List<_RankedItem>, _reduceItemsToRanked);
  return sorter(matchedItems).map(_mapToItem).toList();
}

class _RankingInfo {
  String rankedValue;
  Ranking rank;
  int keyIndex;
  Ranking keyThreshold;

  _RankingInfo(
      {required this.rankedValue,
      required this.rank,
      required this.keyIndex,
      required this.keyThreshold});
}

class _ItemInfo {
  String itemValue;
  Key keyAttributes;
  int keyIndex;

  _ItemInfo(
      {required this.itemValue,
      required this.keyAttributes,
      required this.keyIndex});
}

class _RankedItem {
  Item item;
  _RankingInfo rankingInfo;

  _RankedItem({required this.item, required this.rankingInfo});
}

typedef BaseSortFn = int Function(_RankedItem a, _RankedItem b);
int _defaultBaseSort(_RankedItem a, _RankedItem b) {
  return a.rankingInfo.rankedValue.compareTo(b.rankingInfo.rankedValue);
}

typedef SortRankedFn = int Function(
    _RankedItem a, _RankedItem b, BaseSortFn baseSort);
int _sortRankedValues(_RankedItem a, _RankedItem b, BaseSortFn baseSort) {
  var aFirst = -1;
  var bFirst = 1;

  var same = a.rankingInfo.rank.index == b.rankingInfo.rank.index;

  if (same) {
    if (a.rankingInfo.keyIndex == b.rankingInfo.keyIndex) {
      // use the base sort function as a tie-breaker
      return baseSort(a, b);
    } else {
      return a.rankingInfo.keyIndex < b.rankingInfo.keyIndex ? aFirst : bFirst;
    }
  } else {
    return a.rankingInfo.rank.index > b.rankingInfo.rank.index
        ? aFirst
        : bFirst;
  }
}

typedef SorterFn = List<_RankedItem> Function(List<_RankedItem> items);
List<_RankedItem> _defaultSorter(List<_RankedItem> items) {
  List<_RankedItem> sortedItems = List.from(items);

  int _compare(_RankedItem a, _RankedItem b) {
    return _sortRankedValues(a, b, _defaultBaseSort);
  }

  sortedItems.sort(_compare);
  return sortedItems;
}

List<_ItemInfo> _getAllValuesToRank({
  required Item item,
  required List<Key> keys,
  required Ranking threshold,
}) {
  List<_ItemInfo> _itemInfo = [];
  for (var keyIndex = 0; keyIndex < keys.length; keyIndex++) {
    Key key = keys[keyIndex];
    Key keyAttributes = Key(key.key,
        threshold: key.threshold ?? threshold,
        maxRanking: key.maxRanking,
        minRanking: key.minRanking);

    for (var itemIndex = 0; itemIndex < item.length; itemIndex++) {
      if (item.containsKey(key.key)) {
        String itemValue = item[key.key]!;
        _itemInfo.add(_ItemInfo(
            itemValue: itemValue,
            keyAttributes: keyAttributes,
            keyIndex: keyIndex));
      }
    }
  }
  return _itemInfo;
}

_RankingInfo _getHighestRanking({
  required String searchQuery,
  required Item item,
  required List<Key> keys,
  required Ranking threshold,
  required bool keepDiacritics,
}) {
  var rankedValues =
      _getAllValuesToRank(item: item, keys: keys, threshold: threshold);

  var initialValue = _RankingInfo(
      rankedValue: '',
      rank: Ranking.noMatch,
      keyIndex: -1,
      keyThreshold: threshold);

  _RankingInfo combine(_RankingInfo previousValue, _ItemInfo element) {
    var rank = previousValue.rank;
    var keyIndex = previousValue.keyIndex;
    var keyThreshold = previousValue.keyThreshold;
    var newRank = _getMatchRanking(
        searchQuery: searchQuery,
        itemValue: element.itemValue,
        threshold: threshold,
        keepDiacritics: keepDiacritics);
    var newRankedValue = previousValue.rankedValue;

    if (newRank.index < element.keyAttributes.minRanking.index &&
        newRank.index >= Ranking.noMatch.index) {
      newRank = element.keyAttributes.minRanking;
    } else if (newRank.index > element.keyAttributes.maxRanking.index) {
      newRank = element.keyAttributes.maxRanking;
    }
    if (newRank.index > previousValue.rank.index) {
      rank = newRank;
      keyIndex = element.keyIndex;
      keyThreshold = element.keyAttributes.threshold ?? threshold;
      newRankedValue = element.itemValue;
    }
    return _RankingInfo(
      rankedValue: newRankedValue,
      rank: rank,
      keyIndex: keyIndex,
      keyThreshold: keyThreshold,
    );
  }

  return rankedValues.fold(initialValue, combine);
}

Ranking _getMatchRanking({
  required String searchQuery,
  required String itemValue,
  required Ranking threshold,
  required bool keepDiacritics,
}) {
  var testString = _prepareValueForComparison(
      value: itemValue, keepDiacritics: keepDiacritics);
  var stringToRank = _prepareValueForComparison(
      value: searchQuery, keepDiacritics: keepDiacritics);

  // too long
  if (stringToRank.length > testString.length) {
    return Ranking.noMatch;
  }

  // case sensitive equals
  if (testString == stringToRank) {
    return Ranking.caseSensitiveEqual;
  }

  // lower casing before further comparison
  testString = testString.toLowerCase();
  stringToRank = stringToRank.toLowerCase();

  // case insensitive equals
  if (testString == stringToRank) {
    return Ranking.equal;
  }

  // starts with
  if (testString.startsWith(stringToRank)) {
    return Ranking.startsWith;
  }

  // word starts with
  if (testString.contains(' $stringToRank')) {
    return Ranking.wordStartsWith;
  }

  // contains
  if (testString.contains(stringToRank)) {
    return Ranking.contains;
  } else if (stringToRank.length == 1) {
    // If the only character in the given stringToRank
    //   isn't even contained in the testString, then
    //   it's definitely not a match.
    return Ranking.noMatch;
  }

  // acronym
  if (_getAcronym(testString) == stringToRank) {
    return Ranking.acronym;
  }

  // will return a number between rankings.MATCHES and
  // rankings.MATCHES + 1 depending  on how close of a match it is.
  return _getClosenessRanking(
      testString: testString, stringToRank: stringToRank);
}

String _getAcronym(String string) {
  String acronym = '';
  var wordsInString = string.split(' ');

  for (var i = 0, wordsInStringLength = wordsInString.length;
      i < wordsInStringLength;
      i++) {
    var wordInString = wordsInString[i];
    var splitByHyphenWords = wordInString.split('-');
    for (var j = 0, splitByHyphenWordsLength = splitByHyphenWords.length;
        j < splitByHyphenWordsLength;
        j++) {
      var splitByHyphenWord = splitByHyphenWords[j];
      acronym += splitByHyphenWord.substring(0, 1);
    }
  }
  return acronym;
}

Ranking _getClosenessRanking({
  required String testString,
  required String stringToRank,
}) {
  int matchingInOrderCharCount = 0;
  int charNumber = 0;
  findMatchingCharacter(String matchChar, String string, int index) {
    for (var i = index, stringLength = string.length; i < stringLength; i++) {
      var stringChar = string[i];
      if (stringChar == matchChar) {
        matchingInOrderCharCount += 1;
        return i + 1;
      }
    }
    return -1;
  }

  Ranking getRanking(int spread) {
    var spreadPercentage = 1 / spread;
    var inOrderPercentage = matchingInOrderCharCount / stringToRank.length;
    var ranking =
        Ranking.matches.index + (inOrderPercentage * spreadPercentage);
    return Ranking.values[ranking.round()];
  }

  var firstIndex = findMatchingCharacter(stringToRank[0], testString, 0);
  if (firstIndex < 0) {
    return Ranking.noMatch;
  }
  charNumber = firstIndex;
  for (var i = 1, stringToRankLength = stringToRank.length;
      i < stringToRankLength;
      i++) {
    var matchChar = stringToRank[i];
    charNumber = findMatchingCharacter(matchChar, testString, charNumber);
    bool found = charNumber > -1;
    if (!found) {
      return Ranking.noMatch;
    }
  }

  var spread = charNumber - firstIndex;
  return getRanking(spread);
}

String _prepareValueForComparison({
  required String value,
  required bool keepDiacritics,
}) {
  if (!keepDiacritics) {
    value = removeDiacritics(value);
  }
  return value;
}
