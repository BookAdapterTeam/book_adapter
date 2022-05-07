import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parseFragment;

class HtmlUtils {
  static dom.DocumentFragment parseHtml(String html) {
    return parseFragment(html);
  }

  /// Returns the elements using depth first search
  static Iterable<dom.Element> getNodes(dom.NodeList elements) sync* {
    for (final element in elements) {
      if (element is dom.Element) {
        yield element;
      }
      if (element.hasChildNodes()) {
        yield* getNodes(element.nodes);
      }
    }
  }

  static Iterable<dom.Node> getNodesFromFragment(
    dom.DocumentFragment fragment,
  ) sync* {
    yield* getNodes(fragment.nodes);
  }

  static Iterable<dom.Node> getNodesFromHtml(String html) sync* {
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
  static dom.Element? getParentNodeWithoutSiblingsAfterElement(
    dom.Node node,
  ) {
    final parent = node.parent;
    if (parent == null) {
      return null;
    }

    final siblings = parent.nodes;
    final index = siblings.indexOf(node);

    // Remove siblings after index
    for (final dom.Node sibling in siblings.sublist(index + 1)) {
      sibling.remove();
    }

    return parent;
  }

  static dom.Node getNodeWithAncestors(dom.Node node) {
    final parent = getParentNodeWithoutSiblingsAfterElement(node);
    if (parent == null) {
      return node;
    }

    return getNodeWithAncestors(parent);
  }

  static String elementToHtml(dom.Element element) {
    return element.outerHtml;
  }
}

