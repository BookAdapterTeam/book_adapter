import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parseFragment;

import 'models/mirror_node.dart';

class HtmlUtils {
  const HtmlUtils._();

  /// Returns the parsed [html]
  static MirrorNode<dom.DocumentFragment> parseHtml(String html) {
    final fragment = parseFragment(html);
    return getMirrorNode(fragment) as MirrorNode<dom.DocumentFragment>;
  }

  /// Returns children of [elements] using depth first traversal
  static Iterable<MirrorNode> getNodes(List<MirrorNode> elements) sync* {
    for (var i = 0; i < elements.length; i++) {
      final element = elements[i];
      if (element.hasChildNodes()) {
        yield* getNodes(element.nodes);
      }
      yield element;
    }
  }

  /// Parse [fragment] and return the nodes using depth first traversal
  static Iterable<MirrorNode> getNodesFromFragment(
    MirrorNode<dom.DocumentFragment> fragment,
  ) sync* {
    yield* getNodes(fragment.nodes);
  }

  /// Parse [html] and return the nodes using depth first traversal
  static Iterable<MirrorNode> getNodesFromHtml(String html) sync* {
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
  static MirrorNode? getParentNodeWithoutSiblingsAfterElement(MirrorNode node) {
    final parentNode = node.parent;
    if (parentNode == null) {
      return null;
    }

    // node's index in parent's children
    final index = node.indexInParent;

    if (index == -1) {
      // TODO: Should probably be an error
      return null;
    }

    final clonedParent = parentNode.deepClone();
    final clonedSiblings = clonedParent.nodes;

    if (index >= parentNode.nodes.length - 1) {
      return clonedParent;
    }

    // Remove siblings after index
    for (final sibling in clonedSiblings.sublist(index + 1)) {
      sibling.remove();
    }

    return clonedParent;
  }

  /// Returns the root node of [node]
  ///
  /// Returns itself if [node] has no parent.
  static MirrorNode getRootMirrorNode(MirrorNode node) {
    final parent = node.parent;
    if (parent == null) {
      return node;
    }

    return getRootMirrorNode(parent);
  }

  /// Returns the root ancestor of [node] with the siblings after it removed
  static MirrorNode getNodeWithAncestors(
    MirrorNode node,
  ) {
    // Find root node of node
    final rootNode = getRootMirrorNode(node);

    final rootNodeClone = rootNode.deepClone();

    // Remove siblings after index
    final clonedNode = rootNodeClone.findDecendentWithId(node.id);
    removeSiblingsAfterNodeForAllParents(clonedNode!);

    return rootNodeClone;
    // final parent = getParentNodeWithoutSiblingsAfterElement(node);
    // if (parent == null) {
    //   return node;
    // }

    // return getNodeWithAncestors(parent);
  }

  /// Removes siblings after [node]
  ///
  /// If [node] is the last element in the list, or [node] has no parent,
  /// nothing will be removed.
  static void removeSiblingsAfterNode(MirrorNode node) {
    final parent = node.parent;
    if (parent == null) {
      return;
    }

    final siblings = parent.nodes;
    final index = siblings.indexOf(node);

    for (final sibling in siblings.sublist(index + 1)) {
      sibling.remove();
    }
  }

  /// Removes siblings after [node] for all parents
  ///
  /// If [node] is the last element in the list, or [node] has no parent,
  /// nothing will be removed.
  static void removeSiblingsAfterNodeForAllParents(MirrorNode node) {
    final parent = node.parent;
    if (parent == null) {
      return;
    }

    removeSiblingsAfterNode(node);

    removeSiblingsAfterNodeForAllParents(parent);
  }

  /// Reconnect the [dom.Node] tree
  static void reconnectMirrorNodes(MirrorNode mirrorNode) {
    if (!mirrorNode.hasChildNodes()) {
      return;
    }

    // Reconnect the dom.Node tree with its children
    mirrorNode.node.nodes.clear();
    for (final node in mirrorNode.nodes) {
      mirrorNode.node.append(node.node..parentNode = mirrorNode.node);
      reconnectMirrorNodes(node);
    }
  }

  /// Returns the html representation of [element], including itself
  static String elementToHtml(dom.Element element) {
    return element.outerHtml;
  }

  /// Returns the html representation of [document], including itself
  static String documentToHtml(dom.Document document) {
    return document.outerHtml;
  }

  /// Returns the html representation of [fragment], including itself
  static String fragmentToHtml(dom.DocumentFragment fragment) {
    return fragment.outerHtml;
  }

  /// Parses the [node] and returns a mirror of the tree
  static MirrorNode getMirrorNode(dom.Node node, {MirrorNode? parent}) {
    if (node is dom.Document) {
      final mirrorNode = MirrorNode.id(
        node: node,
      );

      mirrorNode.nodes = node.nodes
          .map((node) => getMirrorNode(node, parent: mirrorNode))
          .toList();

      return mirrorNode;
    } else if (node is dom.DocumentFragment) {
      final mirrorNode = MirrorNode.id(
        node: node,
      );

      mirrorNode.nodes = node.nodes
          .map((node) => getMirrorNode(node, parent: mirrorNode))
          .toList();

      return mirrorNode;
    } else if (node is dom.Element) {
      final parentNode = node.parentNode;
      final indexInParent = parentNode?.nodes.indexOf(node) ?? -1;

      final mirrorNode = MirrorNode.id(
        node: node,
        parent:
            parent ?? (parentNode != null ? getMirrorNode(parentNode) : null),
        indexInParent: indexInParent,
      );

      mirrorNode.nodes = node.nodes
          .map((node) => getMirrorNode(node, parent: mirrorNode))
          .toList();

      return mirrorNode;
    }

    final parentNode = node.parentNode;
    final indexInParent = parentNode?.nodes.indexOf(node) ?? -1;

    final mirrorNode = MirrorNode.id(
      node: node,
      parent: parent ?? (parentNode != null ? getMirrorNode(parentNode) : null),
      indexInParent: indexInParent,
    );

    mirrorNode.nodes = node.nodes
        .map((node) => getMirrorNode(node, parent: mirrorNode))
        .toList();

    return mirrorNode;
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
