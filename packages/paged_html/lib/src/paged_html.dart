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
    this.scrollDirection = Axis.horizontal,
    this.scrollBehavior,
    this.controller,
    this.maxRebuilds = 20,
  }) : super(key: key);

  final Axis scrollDirection;
  final String html;
  final ScrollPhysics? physics;
  final ScrollBehavior? scrollBehavior;
  final PagedHtmlController? controller;
  final int maxRebuilds;

  @override
  State<PagedHtml> createState() => _PagedHtmlState();
}

class _PagedHtmlState extends State<PagedHtml> {
  final List<Widget> _pages = <Widget>[];
  late PagedHtmlController _pagedHtmlController;
  int _currentPage = 0;
  final List<int> _rebuildCount = [0];
  HtmlPageAction? _previousAction;
  HtmlPageEvent? _previousEvent;

  // TODO: True when all html is displayed
  bool _hasMorePages = true;

  // TODO: Handle to current position in html

  Widget buildHtmlPage(String html, int page) {
    return _HtmlPage(
      html: html,
      previousAction: _previousAction,
      previousEvent: _previousEvent,
      page: page,
      maxRebuilds: widget.maxRebuilds,
      currentRebuildCount: _rebuildCount[page],
      onDone: () {
        // TODO: Only add more pages if it has more html not shown
        if (!_hasMorePages) {
          return;
        }

        // TODO: Get remaining html from html handler
        final remainingHtml = html;

        _pages.add(buildHtmlPage(remainingHtml, page + 1));
        SchedulerBinding.instance?.addPostFrameCallback((_) {
          setState(() {});
        });
      },
      onRequestedRebuild: (event, action) =>
          _onRequestedRebuild(event, action, page),
    );
  }

  @override
  void initState() {
    _pagedHtmlController = widget.controller ?? PagedHtmlController();
    _pages.add(buildHtmlPage(0));
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
        scrollDirection: widget.scrollDirection,
        controller: _pagedHtmlController.pageController,
        scrollBehavior: widget.scrollBehavior,
        physics: widget.physics,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          // TODO: Add pages to items list lazily
          if (_rebuildCount.length == index) {
            _rebuildCount.add(0);
          }

          return _pages[index];
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

class _HtmlPage extends StatelessWidget {
  const _HtmlPage({
    Key? key,
    required this.html,
    required this.page,
    required this.onRequestedRebuild,
    required this.maxRebuilds,
    required this.currentRebuildCount,
    required this.onDone,
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
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: CustomBoxy(
            delegate: _HtmlPageDelegate(
              html: html,
              page: page,
              requestRebuild: onRequestedRebuild,
              previousAction: previousAction,
              previousEvent: previousEvent,
              maxRebuilds: maxRebuilds,
              currentRebuildCount: currentRebuildCount,
              onDone: onDone,
            ),
            children: [
              BoxyId(
                id: 'html_$page',
                child: Container(
                  color: Colors.grey,
                  child: HtmlWidget(
                    // '<h1>Hello World</h1>',
                    html,
                    enableCaching: true,
                    renderMode: const ListViewMode(
                      shrinkWrap: true,
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
