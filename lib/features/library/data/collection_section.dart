import 'package:book_adapter/features/library/data/item.dart';
import 'package:sticky_and_expandable_list/sticky_and_expandable_list.dart';

///Section model example
///
///Section model must implements ExpandableListSection<T>, each section has
///expand state, sublist. "T" is the model of each item in the sublist.
class CollectionSection implements ExpandableListSection<Item> {

  CollectionSection({required this.expanded, required this.items, required this.header});

  //store expand state.
  bool expanded;

  // Return item model list.
  List<Item> items;

  // Header text, optional
  String header;

  @override
  List<Item> getItems() {
    return items;
  }

  @override
  bool isSectionExpanded() {
    return expanded;
  }

  @override
  void setSectionExpanded(bool expanded) {
    this.expanded = expanded;
  }
}
