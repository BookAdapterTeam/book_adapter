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
  }) : super(key: key);

  final Axis scrollDirection;
  final String html;
  final ScrollPhysics? physics;
  final ScrollBehavior? scrollBehavior;
  final PagedHtmlController? controller;

  @override
  State<PagedHtml> createState() => _PagedHtmlState();
}

class _PagedHtmlState extends State<PagedHtml> {
  late PagedHtmlController _pagedHtmlController;
  int _currentPage = 0;
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
      child: PageView(
        scrollDirection: widget.scrollDirection,
        controller: _pagedHtmlController.pageController,
        scrollBehavior: widget.scrollBehavior,
        physics: widget.physics,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          for (int index = 0; _hasMorePages; index++)
            _HtmlPage(
              html: widget.html,
              previousAction: _previousAction,
              previousEvent: _previousEvent,
              page: index,
              onRequestedRebuild: (event, removeAction, addAction) {
                switch (removeAction.amount) {
                  case HtmlPageChangeAmount.paragraph:
                    // TODO: Remove a paragraph
                    break;
                  case HtmlPageChangeAmount.sentence:
                    // TODO: Remove a sentence
                    break;
                  case HtmlPageChangeAmount.word:
                    // TODO: Remove a word
                    break;
                  case HtmlPageChangeAmount.none:
                    // Remove nothing
                    break;
                }

                switch (addAction.amount) {
                  case HtmlPageChangeAmount.paragraph:
                    // TODO: Add a paragraph
                    break;
                  case HtmlPageChangeAmount.sentence:
                    // TODO: Add a sentence
                    break;
                  case HtmlPageChangeAmount.word:
                    // TODO: Add a word
                    break;
                  case HtmlPageChangeAmount.none:
                    // Add nothing
                    break;
                }

                SchedulerBinding.instance?.addPostFrameCallback((_) {
                  print('previousAction: $_previousAction');
                  print('removeAction: $removeAction');
                  print('addAction: $addAction\n');
                  setState(() {});
                });

                _previousAction =
                    addAction == const HtmlPageAction.none() ? _previousAction : addAction;
                _previousEvent = event;

                // TODO: Set to false when all html is displayed
                _hasMorePages = false;
              },
            )
        ],
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
    this.previousAction,
    this.previousEvent,
  }) : super(key: key);

  /// The html to display in the page
  ///
  /// Must start with one paragraph
  final String html;
  final int page;
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
                      physics: NeverScrollableScrollPhysics(),
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
    final HtmlPageAction? previousAction = const HtmlPageAction.addParagraph(),
    final HtmlPageEvent? previousEvent = HtmlPageEvent.hasExtraSpace,
  })  : previousAction = previousAction ?? const HtmlPageAction.addParagraph(),
        previousEvent = previousEvent ?? HtmlPageEvent.hasExtraSpace;

  final String html;
  final RebuildRequestCallback requestRebuild;
  final HtmlPageAction previousAction;
  final HtmlPageEvent previousEvent;
  final int page;

  @override
  Size layout() {
    final htmlChild = getChild('html_$page');
    final actualSize = htmlChild.layout(constraints);
    final actualHeight = actualSize.height;
    final maxHeight = constraints.maxHeight;

    final event = actualHeight < maxHeight
        ? HtmlPageEvent.hasExtraSpace
        : HtmlPageEvent.hasNoExtraSpace;

    // ** Has extra space, add more content **
    if (event == HtmlPageEvent.hasExtraSpace) {
      requestRebuild(
        HtmlPageEvent.hasExtraSpace,
        const HtmlPageAction.none(),
        HtmlPageAction(
          amount: previousAction.amount,
          type: HtmlPageActionType.add,
        ),
      );

      return actualSize;
    }

    // ** Can not fit all content, remove extra **

    // TODO: Previously removed content and still has too much content
    if (previousAction.isRemove) {
      requestRebuild(
        event,
        previousAction,
        const HtmlPageAction.none(),
      );

      // TODO: Fix problem where previousAction.amount is always none after above

      return actualSize;
    }

    // Previously added content and now has too much content
    if (previousAction.isAdd) {
      switch (previousAction.amount) {
        case HtmlPageChangeAmount.paragraph:
          requestRebuild(
            event,
            const HtmlPageAction.removeParagraph(),
            const HtmlPageAction.addSentence(),
          );
          break;
        case HtmlPageChangeAmount.sentence:
          requestRebuild(
            event,
            const HtmlPageAction.removeSentence(),
            const HtmlPageAction.addWord(),
          );
          break;
        case HtmlPageChangeAmount.word:
          requestRebuild(
            event,
            const HtmlPageAction.removeWord(),
            const HtmlPageAction.none(),
          );
          break;
        case HtmlPageChangeAmount.none:
          break;
      }

      return actualSize;
    }

    return actualSize;
  }
}
