import 'package:equatable/equatable.dart';
import 'package:html/dom.dart' as dom;
import 'package:uuid/uuid.dart';

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

  /// The index of this node in [parent]'s children nodes
  final int indexInParent;

  /// The children of this node.
  final List<MirrorNode> nodes;

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
  List<Object> get props => [node, parent ?? 'no parent', indexInParent, nodes];

  @override
  String toString() {
    return 'MirrorNode(node: $node, parent: $parent, indexInParent: $indexInParent, nodes: $nodes)';
  }
}
