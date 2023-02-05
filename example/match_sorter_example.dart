import 'package:match_sorter/match_sorter.dart';

void main() {
  List<Item> items = stringsToItems(['Chakotay', 'Brunt', 'Charzard']);
  var searchQuery = 'Ch';

  List<Item> matchedItems = matchSorter(
    searchQuery: searchQuery,
    items: items,
  );

  print(matchedItems);
  // [{ value: Chakotay }, { value: Charzard }]
}
