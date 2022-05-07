import 'package:equatable/equatable.dart';
import 'package:html/dom.dart' as dom;

class MirrorNode<T extends dom.Node> extends Equatable {
  const MirrorNode({
    required this.id,
    required this.node,
    required this.parent,
    required this.indexInParent,
    this.nodes = const [],
  });

  final String id;

  /// The node that this mirror is reflecting.
  final T node;

  /// The parent of this node.
  ///
  /// Returns null if this is the root node.
  final MirrorNode? parent;

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

  /// The index of this node in [parent]'s children nodes
  final int indexInParent;

  /// The children of this node.
  final List<MirrorNode> nodes;

  bool hasChildNodes() => nodes.isNotEmpty;

  bool contains(MirrorNode node) => nodes.contains(node);

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

  MirrorNode copyWith({
    String? id,
    dom.Node? node,
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
  List<Object> get props => [id, indexInParent];

  @override
  String toString() {
    return 'MirrorNode(node: $node, parent: $parent, indexInParent: $indexInParent, nodes: $nodes)';
  }
}
