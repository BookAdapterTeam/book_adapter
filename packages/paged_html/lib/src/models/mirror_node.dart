import 'package:html/dom.dart' as dom;
import 'package:uuid/uuid.dart';

import '../html_utils.dart';

const uuid = Uuid();

class MirrorNode<T extends dom.Node> {
  MirrorNode({
    required this.id,
    required this.node,
    this.parent,
    this.indexInParent = -1,
    List<MirrorNode>? nodes,
  }) {
    this.nodes = nodes ?? [];
  }

  factory MirrorNode.id({
    required T node,
    MirrorNode? parent,
    int indexInParent = -1,
    List<MirrorNode>? nodes,
  }) {
    return MirrorNode<T>(
      id: uuid.v4(),
      node: node,
      nodes: nodes ?? [],
      parent: parent,
      indexInParent: indexInParent,
    );
  }

  static MirrorNode<dom.Document> documentId({
    required dom.Document node,
    List<MirrorNode>? nodes,
  }) {
    return MirrorNode.id(
      node: node,
      nodes: nodes ?? [],
    );
  }

  static MirrorNode<dom.DocumentFragment> fragmentId({
    required dom.DocumentFragment node,
    List<MirrorNode>? nodes,
  }) {
    return MirrorNode.id(
      node: node,
      nodes: nodes ?? [],
    );
  }

  final String id;

  /// The node that this mirror is reflecting.
  T node;

  /// The parent of this node.
  ///
  /// Returns null if this is the root node.
  MirrorNode? parent;

  /// The parent element of this node.
  ///
  /// Returns null if this node either does not have a parent or its parent is
  /// not [dom.Element].
  MirrorNode<dom.Element>? get parentElement {
    if (parent == null) return null;

    final parentNode = parent!;
    return parentNode.node is dom.Element
        ? MirrorNode(
            id: parentNode.id,
            node: parentNode.node as dom.Element,
            indexInParent: parentNode.indexInParent,
            parent: parentNode.parent,
          )
        : null;
  }

  // /// Returns a copy of this node.
  // ///
  // /// If [deep] is `true`, then all of this node's children and decendents are
  // /// copied as well. If [deep] is `false`, then only this node is copied.
  // ///
  // /// TODO: Fix clone
  // MirrorNode clone({final bool deep = false}) {
  //   final result = MirrorNode(
  //     id: id,
  //     node: node.clone(deep)..parentNode = node.parentNode,
  //     parent: parent,
  //     indexInParent: indexInParent,
  //   );
  //   result.node.nodes.clear();
  //   return _clone(result, deep);
  // }

  // K _clone<K extends MirrorNode>(K shallowClone, bool deep) {
  //   if (deep) {
  //     for (var child in nodes) {
  //       shallowClone.append(child.clone(deep: true));
  //     }
  //   }
  //   return shallowClone;
  // }

  /// Returns a deep copy of this.
  ///
  /// This clones the entire tree, including all parents and children
  MirrorNode deepClone() {
    final rootNode = HtmlUtils.getRootMirrorNode(this);

    // Clone the mirror tree. This disconnects the dom.Node tree and needs to be fixed
    final clonedRootNode = _deepClone(rootNode);

    // Reconnect the dom.Node tree
    HtmlUtils.reconnectMirrorNodes(clonedRootNode);

    final clonedNode = clonedRootNode.findDecendentWithId(id);

    return clonedNode!;
  }

  MirrorNode _deepClone(MirrorNode mirrorNode) {
    final MirrorNode node = MirrorNode(
      id: mirrorNode.id,
      node: mirrorNode.node.clone(false),
      parent: mirrorNode.parent,
      indexInParent: mirrorNode.indexInParent,
    );

    for (final child in mirrorNode.nodes) {
      node.append(_deepClone(child)..parent = node);
    }

    return node;
  }

  /// Returns the first child node with [tag]
  MirrorNode? findChildElement(String tag) {
    try {
      return elements.firstWhere((node) => node.node.localName == tag);
    } on StateError catch (_) {
      return null;
    }
  }

  MirrorNode? findDecendentWithId(String id) {
    if (this.id == id) return this;

    try {
      return nodes.firstWhere(
        (node) => node.id == id,
      );
    } on StateError catch (_) {
      for (final node in nodes) {
        final result = node.findDecendentWithId(id);
        if (result != null) {
          return result;
        }
      }

      return null;
    }
  }

  /// The index of this node in [parent]'s children nodes
  final int indexInParent;

  /// The children of this node.
  late List<MirrorNode> nodes;

  /// Returns `true` if this node has child [nodes].
  bool hasChildNodes() => nodes.isNotEmpty;

  bool contains(MirrorNode node) => nodes.contains(node);

  /// Remove this node from its parent.
  ///
  /// If this node has no parent, then this method does nothing.
  MirrorNode remove() {
    node.parentNode?.nodes.remove(node);
    parent?.nodes.remove(this);
    return this;
  }

  /// Insert [node] as a child of the current node, before [refNode] in the
  void insertBefore(MirrorNode node, MirrorNode? refNode) {
    if (refNode == null) {
      nodes.add(node);
    } else {
      nodes.insert(nodes.indexOf(refNode), node);
    }
  }

  /// Replaces this node with another node.
  MirrorNode replaceWith(MirrorNode otherNode) {
    if (parent == null) {
      throw UnsupportedError('Node must have a parent to replace it.');
    }
    parent!.nodes[parent!.nodes.indexOf(this)] = otherNode;
    return this;
  }

  void append(MirrorNode node) => nodes.add(node);

  MirrorNode? get firstChild => nodes.isNotEmpty ? nodes[0] : null;

  /// Returns the children [nodes] which are of type [dom.Element]
  List<MirrorNode<dom.Element>> get elements => nodes
      .where(
        (mirrorNode) => mirrorNode.node is dom.Element,
      )
      .map((e) => MirrorNode(
            id: e.id,
            node: e.node as dom.Element,
            parent: e.parent,
            indexInParent: e.indexInParent,
            nodes: e.nodes,
          ))
      .toList();

  MirrorNode<T> copyWith({
    String? id,
    T? node,
    MirrorNode? parent,
    int? indexInParent,
    List<MirrorNode>? nodes,
  }) {
    return MirrorNode(
      id: id ?? this.id,
      node: node ?? this.node,
      parent: parent ?? this.parent,
      indexInParent: indexInParent ?? this.indexInParent,
      nodes: nodes ?? this.nodes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MirrorNode &&
      id == other.id &&
      indexInParent == other.indexInParent;

  @override
  String toString() {
    return 'MirrorNode(node: $node, parent: $parent, indexInParent: $indexInParent, nodes: $nodes)';
  }

  @override
  int get hashCode => id.hashCode;
}
