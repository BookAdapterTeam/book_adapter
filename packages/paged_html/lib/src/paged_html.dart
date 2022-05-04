import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
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
  late PageController _pageController;
  int currentPage = 0;

  @override
  void initState() {
    _pageController = widget.controller?.pageController ?? PageController();
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
        controller: _pageController,
        scrollBehavior: widget.scrollBehavior,
        physics: widget.physics,
        onPageChanged: (index) {
          setState(() {
            currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          return HtmlPage(
            html: widget.html,
            page: index,
            onRequestedRebuild: (event, action) {},
          );
        },
      ),
    );
  }
}

class HtmlPage extends StatelessWidget {
  const HtmlPage({
    Key? key,
    required this.html,
    required this.page,
    required this.onRequestedRebuild,
  }) : super(key: key);

  final String html;
  final int page;
  final RebuildRequestCallback onRequestedRebuild;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: CustomBoxy(
            delegate: _HtmlPageDelegate(
              html: html,
              requestRebuild: onRequestedRebuild,
            ),
            children: const [],
          ),
        ),
      ],
    );
  }
}

class _HtmlPageDelegate extends BoxyDelegate {
  _HtmlPageDelegate({required this.html, required this.requestRebuild});

  final String html;
  final RebuildRequestCallback requestRebuild;

  @override
  Size layout() {
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

    // TODO: if actual height == max height, rebuild with less html
    // Note: THIS IS NOT WORKING YET
    // This loop should be in the PageView.builder widget
    HtmlPageAction action = HtmlPageAction.paragraph;
    while (action != HtmlPageAction.none) {
      if (actualHeight < maxHeight) {
        requestRebuild(HtmlPageEvent.hasExtraSpace, action);
      } else {
        switch (action) {
          case HtmlPageAction.paragraph:
            requestRebuild(HtmlPageEvent.hasNoExtraSpace, action);
            action = HtmlPageAction.sentence;
            break;
          case HtmlPageAction.sentence:
            requestRebuild(HtmlPageEvent.hasNoExtraSpace, action);
            action = HtmlPageAction.word;
            break;
          case HtmlPageAction.word:
            requestRebuild(HtmlPageEvent.hasNoExtraSpace, action);
            action = HtmlPageAction.none;
            break;
          case HtmlPageAction.none:
            break;
        }
      }
    }

    return actualSize;
  }
}

typedef RebuildRequestCallback = void Function(HtmlPageEvent, HtmlPageAction);

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

  /// Do nothing, rebuild should be ignored
  none,
}
