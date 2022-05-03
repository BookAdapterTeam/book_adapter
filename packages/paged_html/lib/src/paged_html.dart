import 'package:boxy/boxy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}

/// A Widget that displays the html in horizontal or verticle pages
class PagedHtml extends StatefulWidget {
  const PagedHtml({
    Key? key,
    required this.html,
    this.physics,
    this.scrollDirection = Axis.horizontal,
    this.scrollBehavior,
    this.pageTurnDuration = const Duration(milliseconds: 300),
    this.nextPageCurve = Curves.easeInOut,
    this.previousPageCurve = Curves.easeInOut,
  }) : super(key: key);

  final Axis scrollDirection;
  final String html;
  final ScrollPhysics? physics;
  final ScrollBehavior? scrollBehavior;
  final Duration pageTurnDuration;
  final Curve nextPageCurve;
  final Curve previousPageCurve;

  @override
  State<PagedHtml> createState() => _PagedHtmlState();
}

class _PagedHtmlState extends State<PagedHtml> {
  late PageController _pageController;
  int currentPage = 0;

  @override
  void initState() {
    _pageController = PageController();
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _handlePanGesture,
      // onTap: () => _nextPage(),
      // onDoubleTap: () => _prevPage(),
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
          return HtmlPage(html: widget.html, page: index);
        },
      ),
    );
  }

  Future<void> _nextPage() => _pageController.animateToPage(
        currentPage + 1,
        duration: widget.pageTurnDuration,
        curve: widget.nextPageCurve,
      );

  Future<void> _prevPage() => _pageController.animateToPage(
        currentPage - 1,
        duration: widget.pageTurnDuration,
        curve: widget.previousPageCurve,
      );

  void _handlePanGesture(DragUpdateDetails details) {
    // TODO: Improve gesture handling
    if (widget.scrollDirection == Axis.horizontal) {
      if (details.delta.dx > 0) {
        // right
        _prevPage();
      } else {
        // left
        _nextPage();
      }
    } else {
      if (details.delta.dy > 0) {
        // down
        _prevPage();
      } else {
        // up
        _nextPage();
      }
    }
  }
}

class HtmlPage extends StatelessWidget {
  const HtmlPage({
    Key? key,
    required this.html,
    required this.page,
  }) : super(key: key);

  final String html;
  final int page;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: CustomBoxy(
            delegate: _HtmlPageDelegate(html: html),
            children: const [],
          ),
        ),
      ],
    );
  }
}

class _HtmlPageDelegate extends BoxyDelegate {
  _HtmlPageDelegate({required this.html});

  final String html;

  @override
  Size layout() {
    final htmlWidget = Container(
      color: Colors.grey,
      child: HtmlWidget(
        // '<h1>Hello World</h1>',
        html,
        enableCaching: true,
        renderMode: const ListViewMode(shrinkWrap: true),
      ),
    );

    final htmlChild = inflate(htmlWidget, id: #html);

    final actualSize = htmlChild.layout(constraints);
    // print('Html Height: ${actualSize.height}');
    // print('Max Height: ${constraints.maxHeight}');

    // TODO: if actual height == max height, rebuild with less html

    return actualSize;
  }
}
