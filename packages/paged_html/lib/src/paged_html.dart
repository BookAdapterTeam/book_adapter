import 'package:boxy/boxy.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

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
  int currentPage = 0;
  HtmlPageAction? previousAction;
  HtmlPageEvent? previousEvent;

  // TODO: True when all html is displayed
  bool get hasMorePages => true;

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
            currentPage = index;
          });
        },
        children: [
          for (int index = 0; hasMorePages; index++)
            _HtmlPage(
              html: widget.html,
              previousAction: previousAction,
              previousEvent: previousEvent,
              page: index,
              onRequestedRebuild: (event, removeAction, addAction) {
                switch (removeAction) {
                  case HtmlPageAction.paragraph:
                    // TODO: Remove a paragraph
                    break;
                  case HtmlPageAction.sentence:
                    // TODO: Remove a sentence
                    break;
                  case HtmlPageAction.word:
                    // TODO: Remove a word
                    break;
                  case HtmlPageAction.none:
                    // Remove nothing
                    break;
                }

                switch (addAction) {
                  case HtmlPageAction.paragraph:
                    // TODO: Add a paragraph
                    break;
                  case HtmlPageAction.sentence:
                    // TODO: Add a sentence
                    break;
                  case HtmlPageAction.word:
                    // TODO: Add a word
                    break;
                  case HtmlPageAction.none:
                    // Add nothing
                    break;
                }

                SchedulerBinding.instance?.addPostFrameCallback((_) {
                  print('previousAction: $previousAction');
                  print('removeAction: $removeAction');
                  print('addAction: $addAction\n');
                  setState(() {});
                });

                previousAction = addAction;
                previousEvent = event;

                // TODO: Set to false when all html is displayed
                hasMorePages = false;
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
    final HtmlPageAction? previousAction = HtmlPageAction.paragraph,
    final HtmlPageEvent? previousEvent = HtmlPageEvent.hasExtraSpace,
  })  : previousAction = previousAction ?? HtmlPageAction.paragraph,
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

    if (event == HtmlPageEvent.hasExtraSpace) {
      // Add content
      requestRebuild(
        HtmlPageEvent.hasExtraSpace,
        HtmlPageAction.none,
        previousAction,
      );
    } else {
      // Remove extra content

      // Handle when still too much content after removing some
      if (previousEvent == event) {
        requestRebuild(
          event,
          previousAction,
          HtmlPageAction.none,
        );
      }

      switch (previousAction) {
        case HtmlPageAction.paragraph:
          requestRebuild(
            event,
            previousAction,
            HtmlPageAction.sentence,
          );
          break;
        case HtmlPageAction.sentence:
          requestRebuild(
            event,
            previousAction,
            HtmlPageAction.word,
          );
          break;
        case HtmlPageAction.word:
          requestRebuild(
            event,
            previousAction,
            HtmlPageAction.none,
          );
          break;
        case HtmlPageAction.none:
          break;
      }
    }

    return actualSize;
  }
}

typedef RebuildRequestCallback = void Function(
  HtmlPageEvent event,
  HtmlPageAction removeAction,
  HtmlPageAction addAction,
);

enum HtmlPageEvent {
  /// The html page has extra space available, so extra content can be added.
  hasExtraSpace,

  /// The html is too long for the page, so some content should be removed.
  hasNoExtraSpace,
}

enum HtmlPageAction {
  /// Add or remove a paragraph from the html content, depending on the event.
  paragraph,

  /// Add or remove a sentence from the html content, depending on the event.
  sentence,

  /// Add or remove a word from the html content, depending on the event.
  word,

  /// No action is required.
  none,
}
