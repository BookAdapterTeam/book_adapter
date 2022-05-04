import 'package:flutter/material.dart';

class PagedHtmlController {
  final PageController _pageController;
  final Duration pageTurnDuration;
  final Curve nextPageCurve;
  final Curve previousPageCurve;

  PageController get pageController => _pageController;

  PagedHtmlController({
    this.pageTurnDuration = const Duration(milliseconds: 300),
    this.nextPageCurve = Curves.easeInOut,
    this.previousPageCurve = Curves.easeInOut,
  }) : _pageController = PageController();

  Future<void> nextPage() => _pageController.nextPage(
        duration: pageTurnDuration,
        curve: nextPageCurve,
      );

  Future<void> prevPage() => _pageController.previousPage(
        duration: pageTurnDuration,
        curve: previousPageCurve,
      );

  /// Discards any resources used by the object. After this is called,
  /// the object is not in a usable state and should be discarded.
  ///
  /// This method should only be called by the object's owner.
  void dispose() {
    _pageController.dispose();
  }
}