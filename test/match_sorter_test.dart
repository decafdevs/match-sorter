import 'package:test/test.dart';
import 'package:match_sorter/match_sorter.dart';

void main() {
  group('matchSorter test suite', () {
    setUp(() {
      // Additional setup goes here.
    });

    test('returns an empty array with a string that matches no items', () {
      var items = stringsToItems(['Chakotay', 'Charzard']);
      var searchQuery = 'nomatch';

      var expectedItems = <Item>[];

      expect(
          matchSorter(
            searchQuery: searchQuery,
            items: items,
          ),
          expectedItems);
    });

    test('returns the items that match', () {
      var items = stringsToItems(['Chakotay', 'Brunt', 'Charzard']);
      var searchQuery = 'Ch';

      var expectedItems = stringsToItems(['Chakotay', 'Charzard']);

      expect(
          matchSorter(
            searchQuery: searchQuery,
            items: items,
          ),
          expectedItems);
    });

    // this test expectation is different from the original match-sorter because we are using compareNatural for baseSort
    // while the original match-sorter uses String.toLocalCompare() which can not be replicated as is in Dart
    test('returns items that match in the best order', () {
      var items = stringsToItems([
        'The Tail of Two Cities 1', // acronym
        'tTOtc', // equal
        'ttotc', // case-sensitive-equal
        'The 1-ttotc-2 container', // contains
        'The Tail of Forty Cities', // match
        'The Tail of Two Cities', // acronym2
        'kebab-ttotc-case', // case string
        'Word starts with ttotc-first right?', // wordStartsWith
        'The Tail of Fifty Cities', // match2
        'no match', // no match
        'The second 3-ttotc-4 container', // contains2
        'ttotc-starts with', // startsWith
        'Another word starts with ttotc-second, super!', // wordStartsWith2
        'ttotc-2nd-starts with', // startsWith2
        'TTotc', // equal2,
      ]);
      var searchQuery = 'ttotc';

      var expectedItems = stringsToItems([
        'ttotc', // case-sensitive-equal
        'tTOtc', // equal
        'TTotc', // equal2
        'ttotc-2nd-starts with', // startsWith
        'ttotc-starts with', // startsWith2
        'Another word starts with ttotc-second, super!', // wordStartsWith
        'Word starts with ttotc-first right?', // wordStartsWith2
        'kebab-ttotc-case', // case string
        'The 1-ttotc-2 container', // contains
        'The second 3-ttotc-4 container', // contains2
        'The Tail of Two Cities', // acronym
        'The Tail of Two Cities 1', // acronym2
        'The Tail of Fifty Cities', // match
        'The Tail of Forty Cities', // match2
      ]);

      expect(
          matchSorter(
            searchQuery: searchQuery,
            items: items,
          ),
          expectedItems);
    });

    test('no match for single character inputs that are not equal', () {
      var items = stringsToItems([
        'abc',
      ]);
      var searchQuery = 'd';

      var expectedItems = stringsToItems([]);

      expect(
          matchSorter(
            searchQuery: searchQuery,
            items: items,
          ),
          expectedItems);
    });

    test('can handle objects when specifying a key', () {
      var items = [
        {'name': 'baz'},
        {'name': 'bat'},
        {'name': 'foo'}
      ];
      var searchQuery = 'ba';
      var keys = [Key('name')];

      var expectedItems = [
        {'name': 'bat'},
        {'name': 'baz'},
      ];

      expect(
          matchSorter(
            searchQuery: searchQuery,
            items: items,
            keys: keys,
          ),
          expectedItems);
    });

    test('can handle multiple keys specified', () {
      var items = [
        {'name': 'baz', 'reverse': 'zab'},
        {'name': 'bat', 'reverse': 'tab'},
        {'name': 'foo', 'reverse': 'oof'},
        {'name': 'bag', 'reverse': 'gab'},
      ];
      var searchQuery = 'ab';
      var keys = [Key('name'), Key('reverse')];

      var expectedItems = [
        {'name': 'bag', 'reverse': 'gab'},
        {'name': 'bat', 'reverse': 'tab'},
        {'name': 'baz', 'reverse': 'zab'},
      ];

      expect(
          matchSorter(
            searchQuery: searchQuery,
            items: items,
            keys: keys,
          ),
          expectedItems);
    });

    test(
        'with multiple keys specified, all other things being equal, it prioritizes key index over alphabetizing',
        () {
      var items = [
        {'first': 'not', 'second': 'not', 'third': 'match'},
        {'first': 'not', 'second': 'not', 'third': 'not', 'fourth': 'match'},
        {'first': 'not', 'second': 'match'},
        {'first': 'match', 'second': 'not'},
      ];
      var searchQuery = 'match';
      var keys = [Key('first'), Key('second'), Key('third'), Key('fourth')];

      var expectedItems = [
        {'first': 'match', 'second': 'not'},
        {'first': 'not', 'second': 'match'},
        {'first': 'not', 'second': 'not', 'third': 'match'},
        {'first': 'not', 'second': 'not', 'third': 'not', 'fourth': 'match'}
      ];

      expect(matchSorter(searchQuery: searchQuery, items: items, keys: keys),
          expectedItems);
    });

    test('can handle keys with a maxRanking', () {
      var items = [
        {'tea': 'Earl Grey', 'alias': 'A'},
        {'tea': 'Assam', 'alias': 'B'},
        {'tea': 'Black', 'alias': 'C'},
      ];
      var searchQuery = 'A';
      var keys = [Key('tea'), Key('alias', maxRanking: Ranking.startsWith)];

      var expectedItems = [
        {'tea': 'Assam', 'alias': 'B'},
        {'tea': 'Earl Grey', 'alias': 'A'},
        {'tea': 'Black', 'alias': 'C'},
      ];

      expect(matchSorter(searchQuery: searchQuery, items: items, keys: keys),
          expectedItems);
    });

    test('can handle keys with a minRanking', () {
      var items = [
        {'tea': 'Milk', 'alias': 'moo'},
        {'tea': 'Oolong', 'alias': 'B'},
        {'tea': 'Green', 'alias': 'C'},
      ];
      var searchQuery = 'oo';
      var keys = [Key('tea'), Key('alias', minRanking: Ranking.equal)];

      var expectedItems = [
        {'tea': 'Milk', 'alias': 'moo'},
        {'tea': 'Oolong', 'alias': 'B'},
      ];

      expect(matchSorter(searchQuery: searchQuery, items: items, keys: keys),
          expectedItems);
    });

    // expected response is not the same as that of the JS version
    test(
        'when providing a rank threshold of NO_MATCH, it returns all of the items',
        () {
      var items = stringsToItems(['orange', 'apple', 'grape', 'banana']);
      var searchQuery = 'ap';

      var expectedItems =
          stringsToItems(['apple', 'grape', 'orange', 'banana']);

      expect(
          matchSorter(
              searchQuery: searchQuery,
              items: items,
              threshold: Ranking.noMatch),
          expectedItems);
    });

    test(
        'when providing a rank threshold of EQUAL, it returns only the items that are equal',
        () {
      var items = stringsToItems(['google', 'airbnb', 'apple', 'apply', 'app']);
      var searchQuery = 'app';

      var expectedItems = stringsToItems(['app']);

      expect(
          matchSorter(
              searchQuery: searchQuery, items: items, threshold: Ranking.equal),
          expectedItems);
    });

    test(
        'when providing a rank threshold of CASE_SENSITIVE_EQUAL, it returns only case-sensitive equal matches',
        () {
      var items = stringsToItems(
          ['google', 'airbnb', 'apple', 'apply', 'app', 'aPp', 'App']);
      var searchQuery = 'app';

      var expectedItems = stringsToItems(['app']);

      expect(
          matchSorter(
              searchQuery: searchQuery,
              items: items,
              threshold: Ranking.caseSensitiveEqual),
          expectedItems);
    });

    test(
        'when providing a rank threshold of WORD_STARTS_WITH, it returns only the items that are equal',
        () {
      var items = stringsToItems(
          ['fiji apple', 'google', 'app', 'crabapple', 'apple', 'apply']);
      var searchQuery = 'app';

      var expectedItems =
          stringsToItems(['app', 'apple', 'apply', 'fiji apple']);

      expect(
          matchSorter(
              searchQuery: searchQuery,
              items: items,
              threshold: Ranking.wordStartsWith),
          expectedItems);
    });

    test(
        'when providing a rank threshold of ACRONYM, it returns only the items that meet the rank',
        () {
      var items = stringsToItems(['apple', 'atop', 'alpaca', 'vamped']);
      var searchQuery = 'ap';

      var expectedItems = stringsToItems(['apple']);

      expect(
          matchSorter(
              searchQuery: searchQuery,
              items: items,
              threshold: Ranking.acronym),
          expectedItems);
    });

    test('defaults to ignore diacritics', () {
      var items = stringsToItems(
          ['jalapeño', 'à la carte', 'café', 'papier-mâché', 'à la mode']);
      var searchQuery = 'aa';

      var expectedItems = stringsToItems(
          ['jalapeño', 'à la carte', 'à la mode', 'papier-mâché']);

      expect(
          matchSorter(
            searchQuery: searchQuery,
            items: items,
          ),
          expectedItems);
    }, skip: true);

    test('takes diacritics in account when keepDiacritics specified as true',
        () {
      var items = stringsToItems(
          ['jalapeño', 'à la carte', 'café', 'papier-mâché', 'à la mode']);
      var searchQuery = 'aa';

      var expectedItems = stringsToItems(['jalapeño', 'à la carte']);

      expect(
          matchSorter(
              searchQuery: searchQuery, items: items, keepDiacritics: true),
          expectedItems);
    });

    test('sorts items based on how closely they match', () {
      var items = stringsToItems([
        'Antigua and Barbuda',
        'India',
        'Bosnia and Herzegovina',
        'Indonesia'
      ]);
      var searchQuery = 'Ina';

      var expectedItems = stringsToItems([
        'Bosnia and Herzegovina',
        'India',
        'Indonesia',
        'Antigua and Barbuda',
      ]);

      expect(
          matchSorter(searchQuery: searchQuery, items: items), expectedItems);
    }, skip: true);

    test('sort when search value is absent', () {
      var items = [
        {'tea': 'Milk', 'alias': 'moo'},
        {'tea': 'Oolong', 'alias': 'B'},
        {'tea': 'Green', 'alias': 'C'},
      ];
      var searchQuery = '';
      var keys = [Key('tea')];

      var expectedItems = [
        {'tea': 'Green', 'alias': 'C'},
        {'tea': 'Milk', 'alias': 'moo'},
        {'tea': 'Oolong', 'alias': 'B'}
      ];

      expect(matchSorter(searchQuery: searchQuery, items: items, keys: keys),
          expectedItems);
    });

    test('only match when key meets threshold', () {
      var items = [
        {'name': 'Fred', 'color': 'Orange'},
        {'name': 'Jen', 'color': 'Red'},
      ];
      var searchQuery = 'ed';
      var keys = [Key('name', threshold: Ranking.startsWith), Key('color')];

      var expectedItems = [
        {'name': 'Jen', 'color': 'Red'}
      ];

      expect(matchSorter(searchQuery: searchQuery, items: items, keys: keys),
          expectedItems);
    });

    test('should match when key threshold is lower than the default threshold',
        () {
      var items = [
        {'name': 'Fred', 'color': 'Orange'},
        {'name': 'Jen', 'color': 'Red'},
      ];
      var searchQuery = 'ed';
      var keys = [
        Key(
          'name',
        ),
        Key('color', threshold: Ranking.contains)
      ];

      var expectedItems = [
        {'name': 'Jen', 'color': 'Red'}
      ];

      expect(
          matchSorter(
              searchQuery: searchQuery,
              items: items,
              keys: keys,
              threshold: Ranking.startsWith),
          expectedItems);
    });

    test('case insensitive cyrillic match', () {
      var items = stringsToItems(['Привет', 'Лед']);
      var searchQuery = 'л';

      var expectedItems = stringsToItems(['Лед']);

      expect(
          matchSorter(
            searchQuery: searchQuery,
            items: items,
          ),
          expectedItems);
    }, skip: true);

    test(
        'should sort same ranked items alphabetically while when mixed with diacritics',
        () {
      var items = stringsToItems([
        'jalapeño',
        'anothernodiacritics',
        'à la carte',
        'nodiacritics',
        'café',
        'papier-mâché',
        'à la mode',
      ]);
      var searchQuery = 'z';

      var expectedItems = stringsToItems([
        'à la carte',
        'à la mode',
        'anothernodiacritics',
        'café',
        'jalapeño',
        'nodiacritics',
        'papier-mâché',
      ]);

      expect(
          matchSorter(
              searchQuery: searchQuery,
              items: items,
              threshold: Ranking.noMatch),
          expectedItems);
    }, skip: true);

    test('returns objects in their original order', () {
      var items = [
        {'country': 'Italy', 'counter': 3},
        {'country': 'Italy', 'counter': 2},
        {'country': 'Italy', 'counter': 1},
      ];
      var searchQuery = 'Italy';
      var keys = [Key('country'), Key('counter')];

      var expectedItems = [
        {'country': 'Italy', 'counter': 3},
        {'country': 'Italy', 'counter': 2},
        {'country': 'Italy', 'counter': 1},
      ];

      expect(matchSorter(searchQuery: searchQuery, items: items, keys: keys),
          expectedItems);
    });

    test('supports a custom baseSort function for tie-breakers', () {
      var items = stringsToItems(
          ['appl', 'C apple', 'B apple', 'A apple', 'app', 'applebutter']);
      var searchQuery = 'apple';

      var expectedItems =
          stringsToItems(['applebutter', 'C apple', 'B apple', 'A apple']);

      expect(
          matchSorter(
              searchQuery: searchQuery,
              items: items,
              baseSort: (a, b) {
                return a.itemIndex < b.itemIndex ? -1 : 1;
              }),
          expectedItems);
    });

    test('sorts simple items alphabetically', () {
      var items = stringsToItems(["a'd", 'a-c', 'a_b', 'a a']);
      var searchQuery = '';

      var expectedItems = stringsToItems(['a a', 'a_b', 'a-c', "a'd"]);

      expect(
          matchSorter(
            searchQuery: searchQuery,
            items: items,
          ),
          expectedItems);
    }, skip: true);

    test(
        'support a custom sortRankedValues function to overriding all sorting functionality',
        () {
      var items = stringsToItems(
          ['appl', 'C apple', 'B apple', 'A apple', 'app', 'applebutter']);
      var searchQuery = '';

      var expectedItems = stringsToItems(
          ['applebutter', 'app', 'A apple', 'B apple', 'C apple', 'appl']);

      expect(
          matchSorter(
              searchQuery: searchQuery,
              items: items,
              sorter: (rankedItems) {
                return rankedItems.reversed.toList();
              }),
          expectedItems);
    });
  });
}
