import 'dart:async';

import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Creates a controller for [DragSelectGridView].
///
/// The initial selection is [Selection.empty], unless a
/// different one is provided.
EpubController useEpubController({
  required Future<EpubBook> document,
  String? epubCfi,
  FutureOr<void> Function(String? lastReadCfiLocation)? beforeDispose,
}) =>
    use(
      _EpubControllerHook(
        document: document,
        epubCfi: epubCfi,
        beforeDispose: beforeDispose,
      ),
    );

class _EpubControllerHook extends Hook<EpubController> {
  const _EpubControllerHook({
    required this.document,
    this.epubCfi,
    this.beforeDispose,
  });
  final Future<EpubBook> document;
  final String? epubCfi;
  final FutureOr<void> Function(String? lastReadCfiLocation)? beforeDispose;

  @override
  _EpubControllerHookState createState() => _EpubControllerHookState();
}

class _EpubControllerHookState extends HookState<EpubController, _EpubControllerHook> {
  late final EpubController _controller;

  void rebuild() => setState(() {});

  @override
  void initHook() {
    _controller = EpubController(document: hook.document, epubCfi: hook.epubCfi);
    super.initHook();
  }

  @override
  Future<void> dispose() async {
    final lastCfi = _controller.generateEpubCfi();
    await hook.beforeDispose?.call(lastCfi);
    _controller.dispose();
    super.dispose();
  }

  @override
  EpubController build(BuildContext context) => _controller;

  @override
  String get debugLabel => 'useEpubController';
}

// class _EpubControllerHookCreator {
//   const _EpubControllerHookCreator({
//     required this.document,
//     this.epubCfi,
//   });
//   final Future<EpubBook> document;
//   final String? epubCfi;

//   /// Creates a [EpubController] that will be disposed automatically.
//   ///
//   /// The [text] parameter can be used to set the initial value of the
//   /// controller.
//   EpubController call() {
//     return use(_EpubControllerHook(document: document));
//   }
// }
