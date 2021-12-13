import 'package:sticky_and_expandable_list/sticky_and_expandable_list.dart';

import 'book_collection.dart';
import 'item.dart';

///Section model example
///
///Section model must implements ExpandableListSection<T>, each section has
///expand state, sublist. "T" is the model of each item in the sublist.
class CollectionSection implements ExpandableListSection<Item> {
  CollectionSection({
    required bool expanded,
    required this.items,
    required this.header,
    required this.collection,
  }) : _expanded = expanded;

  // Store expanded state.
  bool _expanded;

  // Return item model list.
  final List<Item> items;

  // Header text, optional
  final String header;

  // Collection associated with this section
  final AppCollection collection;

  @override
  List<Item> getItems() {
    return items;
  }

  @override
  bool isSectionExpanded() {
    return _expanded;
  }

  @override
  void setSectionExpanded(bool expanded) {
    _expanded = expanded;
  }
}
