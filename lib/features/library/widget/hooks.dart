

import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Creates a controller for [DragSelectGridView].
///
/// The initial selection is [Selection.empty], unless a different one is provided.
DragSelectGridViewController useDragSelectGridViewController([Selection? selection]) {
  return use(_DragSelectGridViewControllerHook(selection));
}


class _DragSelectGridViewControllerHook extends Hook<DragSelectGridViewController> {
  const _DragSelectGridViewControllerHook([this.selection]);
  final Selection? selection;

  @override
  _DragSelectGridViewControllerHookState createState() => _DragSelectGridViewControllerHookState();
}

class _DragSelectGridViewControllerHookState extends HookState<DragSelectGridViewController, _DragSelectGridViewControllerHook> {
  late final _controller = DragSelectGridViewController(hook.selection);

  void rebuild() => setState(() {});

  @override
  void initHook() {
    super.initHook();
    _controller.addListener(rebuild);
  }

  @override
  void dispose() {
    _controller.removeListener(rebuild);
    super.dispose();
  }

  @override
  DragSelectGridViewController build(BuildContext context) => _controller;

  @override
  String get debugLabel => 'useDragSelectGridViewController';
}

// class _DragSelectGridViewControllerHookCreator {
//   const _DragSelectGridViewControllerHookCreator();

//   /// Creates a [TextEditingController] that will be disposed automatically.
//   ///
//   /// The [text] parameter can be used to set the initial value of the
//   /// controller.
//   DragSelectGridViewController call([Selection? selection]) {
//     return use(_DragSelectGridViewControllerHook(selection));
//   }
// }