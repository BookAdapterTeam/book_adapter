import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parseFragment;

import 'models/mirror_node.dart';

class Pair<T, K> {
  const Pair(this.first, this.second);

  final T first;
  final K second;
}

class HtmlUtils {
  /// Returns the parsed [html]
  static dom.DocumentFragment parseHtml(String html) {
    return parseFragment(html);
  }

  /// Returns children of [elements] using depth first traversal
  ///
  /// Each element is returned as a [Pair] with the element as [Pair.first]
  /// and its index in its parent as [Pair.second].
  static Iterable<Pair<dom.Node, int>> getNodes(dom.NodeList elements) sync* {
    for (var i = 0; i < elements.length; i++) {
      final element = elements[i];
      if (element.hasChildNodes()) {
        yield* getNodes(element.nodes);
      }
      yield Pair(element, i);
    }
  }

  /// Parse [fragment] and return the nodes using depth first traversal
  static Iterable<Pair<dom.Node, int>> getNodesFromFragment(
    dom.DocumentFragment fragment,
  ) sync* {
    yield* getNodes(fragment.nodes);
  }

  /// Parse [html] and return the nodes using depth first traversal
  static Iterable<Pair<dom.Node, int>> getNodesFromHtml(String html) sync* {
    final fragment = parseHtml(html);

    yield* getNodesFromFragment(fragment);
  }

  /// Returns the siblings of [node] that are before it
  ///
  /// If [node] is the first element in the list, or [node] has no parent,
  /// a list with only [node] will be returned.
  static List<dom.Node> getSiblingNodesBefore(dom.Node node) {
    final parent = node.parent;
    if (parent == null) {
      return [node];
    }

    final siblings = parent.nodes;
    final index = siblings.indexOf(node);

    return siblings.sublist(0, index);
  }

  /// Returns the parent of [node] with the siblings after it removed
  ///
  /// Returns null if [node] has no parent.
  static Pair<dom.Node, int>? getParentNodeWithoutSiblingsAfterElement(
    dom.Node node, {
    required int indexInParent,
  }) {
    final parentNode = node.parentNode;
    if (parentNode == null) {
      return null;
    }

    // Find parent's index in parent's children
    // TODO: Fix when nested 4 levels deep
    // div-1 > div-2 > cloned-p > cloned-a
    final parentIndex = parentNode.parent?.nodes.indexOf(parentNode) ?? -1;

    // final index = indexOfNode(node, parentNode);
    final index = indexInParent;

    if (index == -1) {
      // TODO: Should probably be an error
      return null;
    }

    final clonedParent = parentNode.clone(true);
    clonedParent.parentNode = parentNode.parentNode;
    final clonedSiblings = clonedParent.nodes;

    // Remove siblings after index
    for (final dom.Node sibling in clonedSiblings.sublist(index + 1)) {
      sibling.remove();
    }

    return Pair(clonedParent, parentIndex);
  }

  /// Returns the root ancestor of [node] with the siblings after it removed
  static dom.Node getNodeWithAncestors(
    dom.Node node, {
    required int indexInParent,
  }) {
    final parent = getParentNodeWithoutSiblingsAfterElement(node,
        indexInParent: indexInParent);
    if (parent == null) {
      return node;
    }

    return getNodeWithAncestors(parent.first, indexInParent: parent.second);
  }

  /// Returns the html representation of [element], including itself
  static String elementToHtml(dom.Element element) {
    return element.outerHtml;
  }

  /// Finds the index of [node] in [parent]
  static int indexOfNode(dom.Node node, dom.Node parent) {
    final siblings = parent.nodes;

    for (int i = 0; i < siblings.length; i++) {
      final sibling = siblings[i];
      if (nodeDeepEquals(sibling, node)) {
        return i;
      }
    }

    return -1;
  }

  /// Returns true if the contents of [a] and [b] are equal
  static bool nodeDeepEquals(dom.Node a, dom.Node b) {
    if (a == b) {
      return true;
    }

    final attributesEqual = ((a.parentNode == null && b.parentNode == null) ||
            (a.parentNode != null && b.parentNode != null)) &&
        a.text == b.text &&
        a.nodeType == b.nodeType;

    final childrenEqual = nodeListEquals(a.children, b.children);

    return attributesEqual && childrenEqual;
  }

  /// Returns true if the contents of [a] and [b] are equal
  static bool nodeListEquals(List<dom.Node> a, List<dom.Node> b) {
    if (a.length != b.length) {
      return false;
    }

    for (var i = 0; i < a.length; i++) {
      if (!nodeDeepEquals(a[i], b[i])) {
        return false;
      }
    }

    return true;
  }

  /// Parses the [node] and returns a mirror of the tree
  static MirrorNode getMirrorNode(dom.Node node, {MirrorNode? parent}) {
    final parentNode = node.parent;
    final indexInParent = parentNode?.nodes.indexOf(node) ?? -1;

    final mirrorNode = MirrorNode(
      node: node,
      parent: parent ?? (parentNode != null ? getMirrorNode(parentNode) : null),
      indexInParent: indexInParent,
    );

    return mirrorNode.copyWith(
      nodes: node.nodes
          .map((node) => getMirrorNode(node, parent: mirrorNode))
          .toList(),
    );
  }
}

/// A class which holds html, the current position in the html, the html before the current position, and the html after the current position
class HtmlReader {
  HtmlReader({required this.htmlString})
      : elements =
            HtmlUtils.getNodesFromHtml(htmlString).whereType<dom.Element>() {
    currentElement = elements.first;
  }

  final String htmlString;

  final Iterable<dom.Element> elements;

  /// The current index in [elements]
  int currentPosition = 0;

  late dom.Node currentElement;

  String get currentHtml => elements.elementAt(currentPosition).innerHtml;

  String get previousHtml =>
      (elements.take(currentPosition) as dom.NodeList).join();

  String get nextHtml =>
      (elements.skip(currentPosition) as dom.NodeList).join();

  void moveToNextPosition() {
    currentPosition++;
  }

  void moveToPreviousPosition() {
    currentPosition--;
  }

  void moveToPosition(int position) {
    currentPosition = position;
  }

  void moveToEnd() {
    currentPosition = elements.length;
  }

  void moveToStart() {
    currentPosition = 0;
  }

  bool isAtEnd() {
    return currentPosition == elements.length;
  }

  bool isAtStart() {
    return currentPosition == 0;
  }

  bool isAtPosition(int position, [int offset = 0]) {
    return currentPosition == position + offset;
  }
}
