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
            currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          return _HtmlPage(
            html: widget.html,
            previousAction: previousAction,
            page: index,
            onRequestedRebuild: (removeAction, addAction) {
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
                  break;
              }

              SchedulerBinding.instance?.addPostFrameCallback((_) {
                print('previousAction: $previousAction');
                print('addAction: $addAction');
                setState(() {
                  previousAction = addAction;
                });
              });
            },
          );
        },
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
  }) : super(key: key);

  /// The html to display in the page
  ///
  /// Must start with one paragraph
  final String html;
  final int page;
  final RebuildRequestCallback onRequestedRebuild;
  final HtmlPageAction? previousAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: CustomBoxy(
            delegate: _HtmlPageDelegate(
              html: html,
              requestRebuild: onRequestedRebuild,
              previousAction: previousAction,
            ),
            children: const [],
          ),
        ),
      ],
    );
  }
}

class _HtmlPageDelegate extends BoxyDelegate {
  _HtmlPageDelegate({
    required final this.html,
    required final this.requestRebuild,
    final HtmlPageAction? previousAction = HtmlPageAction.paragraph,
  }) : previousAction = previousAction ?? HtmlPageAction.paragraph;

  final String html;
  final RebuildRequestCallback requestRebuild;
  final HtmlPageAction previousAction;

  @override
  Size layout() {
    // final htmlChild = getChild(#html);

    final htmlWidget = Container(
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
    );

    final htmlChild = inflate(htmlWidget, id: #html);

    final actualSize = htmlChild.layout(constraints);
    // print('Html Height: ${actualSize.height}');
    // print('Max Height: ${constraints.maxHeight}');

    final actualHeight = actualSize.height;
    final maxHeight = constraints.maxHeight;

    if (actualHeight < maxHeight) {
      // Add content
      requestRebuild(
        HtmlPageAction.none,
        previousAction,
      );
    } else {
      // Remove extra content
      switch (previousAction) {
        case HtmlPageAction.paragraph:
          requestRebuild(
            previousAction,
            HtmlPageAction.sentence,
          );
          break;
        case HtmlPageAction.sentence:
          requestRebuild(
            previousAction,
            HtmlPageAction.word,
          );
          break;
        case HtmlPageAction.word:
          requestRebuild(
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
  HtmlPageAction removeAction,
  HtmlPageAction addAction,
);

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
