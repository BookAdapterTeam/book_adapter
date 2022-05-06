import 'package:flutter/material.dart';

/// A page controller for [PagedHtml]
/// 
/// This is a wrapper of [PageController] which provides the methods
/// which would be useful for [PagedHtml].
class PagedHtmlController {
  final PageController pageController;
  final Duration pageTurnDuration;
  final Curve nextPageCurve;
  final Curve previousPageCurve;

  PagedHtmlController({
    this.pageTurnDuration = const Duration(milliseconds: 300),
    this.nextPageCurve = Curves.easeInOut,
    this.previousPageCurve = Curves.easeInOut,
  }) : pageController = PageController();

  Future<void> nextPage() => pageController.nextPage(
        duration: pageTurnDuration,
        curve: nextPageCurve,
      );

  Future<void> prevPage() => pageController.previousPage(
        duration: pageTurnDuration,
        curve: previousPageCurve,
      );

  /// Discards any resources used by the object. After this is called,
  /// the object is not in a usable state and should be discarded.
  ///
  /// This method should only be called by the object's owner.
  void dispose() {
    pageController.dispose();
  }
}
