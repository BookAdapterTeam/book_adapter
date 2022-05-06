import 'package:boxy/boxy.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import 'html_page_action.dart';
import 'paged_html_controller.dart';

/// A Widget that displays the html in horizontal or verticle pages
class PagedHtml extends StatefulWidget {
  const PagedHtml({
    Key? key,
    required this.html,
    this.physics,
    this.reverse = false,
    this.pageSnapping = true,
    this.dragStartBehavior = DragStartBehavior.start,
    this.allowImplicitScrolling = true,
    this.scrollBehavior,
    this.controller,
    this.maxRebuilds = 20,
    this.onPageChanged,
    this.showEndPage = true,
    this.endPage = const Scaffold(
      body: Center(
        child: Text('No more pages'),
      ),
    ),
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.padEnds = true,
  }) : super(key: key);

  /// The HTML content to display.
  final String html;

  /// How the page view should respond to user input.
  ///
  /// For example, determines how the page view continues to animate after the
  /// user stops dragging the page view.
  ///
  /// The physics are modified to snap to page boundaries using
  /// [PageScrollPhysics] prior to being used.
  ///
  /// If an explicit [ScrollBehavior] is provided to [scrollBehavior], the
  /// [ScrollPhysics] provided by that behavior will take precedence after
  /// [physics].
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? physics;

  final PagedHtmlController? controller;

  /// The maximum number of rebuilds allowed to fit the html on one page
  ///
  /// If the max rebuilds is reached and the HTML is too much to fit on
  /// one page, the screen will be scrollable.
  final int maxRebuilds;

  /// Called whenever the page in the center of the viewport changes.
  final void Function(int index)? onPageChanged;

  /// The widget shown when the user scrolls past the last page
  final Widget endPage;

  /// Shows [endPage] when the user scrolls past the last page
  ///
  /// Defaults to true
  final bool showEndPage;

  /// Whether the page view scrolls in the reading direction.
  ///
  /// For example, if the reading direction is left-to-right, then the page
  /// view scrolls from left to right when [reverse] is false and from right
  /// to left when [reverse] is true.
  ///
  /// Defaults to false.
  final bool reverse;

  /// Set to false to disable page snapping, useful for custom scroll behavior.
  ///
  /// If the [padEnds] is false and [PageController.viewportFraction] < 1.0,
  /// the page will snap to the beginning of the viewport; otherwise, the page
  /// will snap to the center of the viewport.
  final bool pageSnapping;

  /// Controls whether the widget's pages will respond to
  /// [RenderObject.showOnScreen], which will allow for implicit accessibility
  /// scrolling.
  ///
  /// With this flag set to false, when accessibility focus reaches the end of
  /// the current page and the user attempts to move it to the next element, the
  /// focus will traverse to the next widget outside of the page view.
  ///
  /// With this flag set to true, when accessibility focus reaches the end of
  /// the current page and user attempts to move it to the next element, focus
  /// will traverse to the next page in the page view.
  final bool allowImplicitScrolling;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.widgets.scrollable.restorationId}
  final String? restorationId;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// {@macro flutter.widgets.shadow.scrollBehavior}
  ///
  /// [ScrollBehavior]s also provide [ScrollPhysics]. If an explicit
  /// [ScrollPhysics] is provided in [physics], it will take precedence,
  /// followed by [scrollBehavior], and then the inherited ancestor
  /// [ScrollBehavior].
  ///
  /// The [ScrollBehavior] of the inherited [ScrollConfiguration] will be
  /// modified by default to not apply a [Scrollbar].
  final ScrollBehavior? scrollBehavior;

  /// Whether to add padding to both ends of the list.
  ///
  /// If this is set to true and [PageController.viewportFraction] < 1.0, padding will be added
  /// such that the first and last child slivers will be in the center of
  /// the viewport when scrolled all the way to the start or end, respectively.
  ///
  /// If [PageController.viewportFraction] >= 1.0, this property has no effect.
  ///
  /// This property defaults to true and must not be null.
  final bool padEnds;

  @override
  State<PagedHtml> createState() => _PagedHtmlState();
}

class _PagedHtmlState extends State<PagedHtml> {
  final List<Widget> _pages = <Widget>[];
  late PagedHtmlController _pagedHtmlController;
  final List<int> _rebuildCount = [0];
  HtmlPageAction? _previousAction;
  HtmlPageEvent? _previousEvent;

  // TODO: False when all html is displayed
  bool _hasMorePages = true;

  set hasMorePages(bool value) {
    if (_hasMorePages == value) {
      return;
    }
    _hasMorePages = value;
    setState(() {});
  }

  // TODO: Add handle to current position in html

  Widget _buildHtmlPage(String html, int page) {
    return _HtmlPage(
      key: ValueKey('HtmlPage-$page'),
      html: html,
      previousAction: _previousAction,
      previousEvent: _previousEvent,
      page: page,
      maxRebuilds: widget.maxRebuilds,
      currentRebuildCount: _rebuildCount[page],
      onRequestedRebuild: (event, action) =>
          _onRequestedRebuild(event, action, page),
    );
  }

  @override
  void initState() {
    _pagedHtmlController = widget.controller ?? PagedHtmlController();
    _pages.add(_buildHtmlPage(widget.html, 0));
    super.initState();
  }

  @override
  void dispose() {
    _pagedHtmlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
        ...ScrollConfiguration.of(context).dragDevices,
        ...const {PointerDeviceKind.mouse, PointerDeviceKind.stylus},
      }),
      child: PageView.builder(
        key: const ValueKey('PagedHtml'),
        reverse: widget.reverse,
        pageSnapping: widget.pageSnapping,
        dragStartBehavior: widget.dragStartBehavior,
        allowImplicitScrolling: widget.allowImplicitScrolling,
        restorationId: widget.restorationId,
        clipBehavior: widget.clipBehavior,
        padEnds: widget.padEnds,
        controller: _pagedHtmlController.pageController,
        scrollBehavior: widget.scrollBehavior,
        physics: widget.physics,
        onPageChanged: widget.onPageChanged,
        itemCount: widget.showEndPage ? _pages.length + 1 : _pages.length,
        itemBuilder: (context, index) {
          if (_rebuildCount.length - 1 == index) {
            _rebuildCount.add(0);
          }

          if (widget.showEndPage && !_hasMorePages && index == _pages.length) {
            return widget.endPage;
          }

          // TODO: Get remaining html from html handler
          final remainingHtml = widget.html;

          // Get page from list if it already exists
          if (_pages.length > index) {
            return _pages[index];
          }

          final newPage = _buildHtmlPage(remainingHtml, index);
          _pages.add(newPage);
          return newPage;
        },
      ),
    );
  }

  void _onRequestedRebuild(
    HtmlPageEvent event,
    HtmlPageAction action,
    int index,
  ) {
    if (action.isTypeAdd) {
      switch (action.amount) {
        case HtmlPageChangeAmount.paragraph:
          // TODO: Add a paragraph
          break;
        case HtmlPageChangeAmount.sentence:
          // TODO: Add a sentence
          break;
        case HtmlPageChangeAmount.word:
          // TODO: Add a word
          break;
      }
    } else if (action.isTypeRemove) {
      switch (action.amount) {
        case HtmlPageChangeAmount.paragraph:
          // TODO: Remove a paragraph
          break;
        case HtmlPageChangeAmount.sentence:
          // TODO: Remove a sentence
          break;
        case HtmlPageChangeAmount.word:
          // TODO: Remove a word
          break;
      }
    }

    SchedulerBinding.instance?.addPostFrameCallback((_) {
      // print('previousAction: $_previousAction');
      // print('action: $action');
      setState(() {});
    });

    _previousAction = action;
    _previousEvent = event;
    if (_rebuildCount.length > index) {
      _rebuildCount[index]++;
    } else {
      _rebuildCount.add(1);
    }

    // TODO: Set to false when all html is displayed
    _hasMorePages = false;
  }
}

class _HtmlPage extends StatefulWidget {
  const _HtmlPage({
    Key? key,
    required this.html,
    required this.page,
    required this.onRequestedRebuild,
    required this.maxRebuilds,
    required this.currentRebuildCount,
    this.onDone,
    this.previousAction,
    this.previousEvent,
  }) : super(key: key);

  /// The html to display in the page
  ///
  /// Must start with one paragraph
  final String html;
  final int page;
  final int maxRebuilds;
  final int currentRebuildCount;
  final RebuildRequestCallback onRequestedRebuild;
  final HtmlPageAction? previousAction;
  final HtmlPageEvent? previousEvent;
  final VoidCallback? onDone;

  @override
  State<_HtmlPage> createState() => _HtmlPageState();
}

class _HtmlPageState extends State<_HtmlPage> {
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('HtmlPage-${widget.page}'),
      children: [
        Flexible(
          key: ValueKey('HtmlPage-${widget.page}-Flexible'),
          child: CustomBoxy(
            key: ValueKey('HtmlPage-${widget.page}-CustomBoxy'),
            delegate: _HtmlPageDelegate(
              html: widget.html,
              page: widget.page,
              requestRebuild: widget.onRequestedRebuild,
              previousAction: widget.previousAction,
              previousEvent: widget.previousEvent,
              maxRebuilds: widget.maxRebuilds,
              currentRebuildCount: widget.currentRebuildCount,
              onDone: widget.onDone ?? () {},
            ),
            children: [
              BoxyId(
                id: 'html_${widget.page}',
                key: ValueKey('HtmlPage-${widget.page}-BoxyId'),
                child: Container(
                  key: ValueKey('HtmlPage-${widget.page}-Container'),
                  color: Colors.grey,
                  child: HtmlWidget(
                    // '<h1>Hello World</h1>',
                    widget.html,
                    key: ValueKey('HtmlWidget-${widget.page}'),
                    enableCaching: true,
                    renderMode: ListViewMode(
                      shrinkWrap: true,
                      controller: _controller,
                      restorationId: 'html_${widget.page}',
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class _HtmlPageDelegate extends BoxyDelegate {
  _HtmlPageDelegate({
    required final this.html,
    required final this.page,
    required final this.requestRebuild,
    required final this.onDone,
    required this.maxRebuilds,
    required this.currentRebuildCount,
    final HtmlPageAction? previousAction = const HtmlPageAction.addParagraph(),
    final HtmlPageEvent? previousEvent = HtmlPageEvent.hasExtraSpace,
  }) : previousAction = previousAction ?? const HtmlPageAction.addParagraph();

  final String html;
  final RebuildRequestCallback requestRebuild;
  final HtmlPageAction previousAction;
  final int page;
  final int maxRebuilds;
  final int currentRebuildCount;
  final VoidCallback onDone;

  @override
  Size layout() {
    final htmlChild = getChild('html_$page');
    final actualSize = htmlChild.layout(constraints);
    final actualHeight = actualSize.height;
    final maxHeight = constraints.maxHeight;

    final event = actualHeight < maxHeight
        ? HtmlPageEvent.hasExtraSpace
        : HtmlPageEvent.hasNoExtraSpace;

    if (currentRebuildCount >= maxRebuilds) {
      onDone();
      return actualSize;
    }

    // ** Has extra space, add more content **
    if (event == HtmlPageEvent.hasExtraSpace) {
      // Previously added content and still has extra space
      if (previousAction.isTypeAdd) {
        // Add the same
        requestRebuild(event, previousAction);
        return actualSize;
      }

      // Previous removed content and now has extra space
      switch (previousAction.amount) {
        case HtmlPageChangeAmount.paragraph:
          requestRebuild(event, const HtmlPageAction.addSentence());
          break;
        case HtmlPageChangeAmount.sentence:
          requestRebuild(event, const HtmlPageAction.addWord());
          break;
        case HtmlPageChangeAmount.word:
          onDone();
          break;
      }

      return actualSize;
    }

    // ** Can not fit all content, remove extra **

    // Previously removed content and still has too much content
    if (previousAction.isTypeRemove) {
      requestRebuild(event, previousAction);
      return actualSize;
    }

    // Previously added content and now has too much content
    switch (previousAction.amount) {
      case HtmlPageChangeAmount.paragraph:
        requestRebuild(event, const HtmlPageAction.removeParagraph());
        break;
      case HtmlPageChangeAmount.sentence:
        requestRebuild(event, const HtmlPageAction.removeSentence());
        break;
      case HtmlPageChangeAmount.word:
        requestRebuild(event, const HtmlPageAction.removeWord());
        break;
    }

    return actualSize;
  }
}
