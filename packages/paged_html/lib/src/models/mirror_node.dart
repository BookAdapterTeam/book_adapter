import 'package:equatable/equatable.dart';
import 'package:html/dom.dart' as dom;

class MirrorNode extends Equatable {
  const MirrorNode({
    required this.node,
    required this.parent,
    required this.indexInParent,
    this.nodes = const [],
  });

  /// The node that this mirror is reflecting.
  final dom.Node node;

  /// The parent of this node.
  ///
  /// Returns null if this is the root node.
  final MirrorNode? parent;

  /// The index of this node in [parent]'s children nodes
  final int indexInParent;

  /// The children of this node.
  final List<MirrorNode> nodes;

  MirrorNode copyWith({
    dom.Node? node,
    MirrorNode? parent,
    int? indexInParent,
    List<MirrorNode>? nodes,
  }) {
    return MirrorNode(
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
