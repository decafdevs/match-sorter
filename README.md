# match-sorter

A dart adaptation of the [match-sorter](https://github.com/kentcdodds/match-sorter) package for javascript

## Examples

### Basic Usage

```dart
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
```

### Multiple keys

```dart
import 'package:match_sorter/match_sorter.dart';

void main() {
  var items = [
    {'name': 'baz', 'reverse': 'zab'},
    {'name': 'bat', 'reverse': 'tab'},
    {'name': 'foo', 'reverse': 'oof'},
    {'name': 'bag', 'reverse': 'gab'},
  ];
  var searchQuery = 'ab';
  var keys = [Key('name'), Key('reverse')];


  List<Item> matchedItems = matchSorter(
    searchQuery: searchQuery,
    items: items,
    keys: keys
  );

  print(matchedItems);
  // [ {'name': 'bag', 'reverse': 'gab'}, {'name': 'bat', 'reverse': 'tab'}, {'name': 'baz', 'reverse': 'zab'} ]
}
```

---

> More examples coming soon. In the meantime you can browser the test suite to explore advanced usecases
