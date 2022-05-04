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
  late PagedHtmlController _pagedHtmlController;
  int _currentPage = 0;
  int _rebuildCount = 0;
  HtmlPageAction? _previousAction;
  HtmlPageEvent? _previousEvent;

  // TODO: True when all html is displayed
  bool _hasMorePages = true;

  // TODO: Handle to current position in html

  @override
  void initState() {
    _pagedHtmlController = widget.controller ?? PagedHtmlController();
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
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
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
        itemCount: 3,
        itemBuilder: (context, index) {
          return _HtmlPage(
            html: widget.html,
            previousAction: _previousAction,
            previousEvent: _previousEvent,
            page: index,
            maxRebuilds: widget.maxRebuilds,
            currentRebuildCount: _rebuildCount,
            onRequestedRebuild: (event, action) {
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

              // SchedulerBinding.instance?.addPostFrameCallback((_) {
              //   print('previousAction: $_previousAction');
              //   print('action: $action');
              //   setState(() {});
              // });

              // _previousAction = action;
              // _previousEvent = event;
              _rebuildCount++;

              // TODO: Set to false when all html is displayed
              _hasMorePages = false;
            },
          );
        },
        // children: [
        //   for (int index = 0; _hasMorePages; index++)

        // ],
      ),
    );
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
      return actualSize;
    }

    // ** Has extra space, add more content **
    if (event == HtmlPageEvent.hasExtraSpace) {
      // Previously added content and still has extra space
      if (previousAction.isTypeAdd) {
        // Add more content
        requestRebuild(event, previousAction);
      }
      // Previous removed content and now has extra space
      else if (previousAction.isTypeRemove) {
        // Remove content
        if (previousAction.amount == HtmlPageChangeAmount.paragraph) {
          requestRebuild(event, const HtmlPageAction.addSentence());
        } else if (previousAction.amount == HtmlPageChangeAmount.sentence) {
          requestRebuild(event, const HtmlPageAction.addWord());
        }
      }

      return actualSize;
    }

    // ** Can not fit all content, remove extra **

    // Previously removed content and still has too much content
    if (previousAction.isTypeRemove) {
      requestRebuild(event, previousAction);
    }

    // Previously added content and now has too much content
    else if (previousAction.isTypeAdd) {
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
    }

    return actualSize;
  }
}
