import 'package:boxy/boxy.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;

import 'html_page_action.dart';
import 'html_utils.dart';
import 'models/mirror_node.dart';
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
    this.maxRebuilds = 100,
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
    this.backgroundColor,
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

  /// Controller for going to the next and previous page.
  ///
  /// This is a wrapper of PageController to provide custom behavior,
  /// and hide methods of [PageController] not intended to be used
  /// (though it can still be accessed).
  final PagedHtmlController? controller;

  /// The maximum number of rebuilds allowed to fit the html on one page
  ///
  /// If the max rebuilds is reached and the HTML is too much to fit on
  /// one page, the html will flow below the screen and be cut off.
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

  /// The background color of the this widget
  final Color? backgroundColor;

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

    final document = HtmlUtils.parseHtml(widget.html);

    final elements = document.findFirstDecendentWithTag('body')?.elements ?? [];
    final childElements = HtmlUtils.getNodes(elements)
        .whereType<MirrorNode<dom.Element>>()
        .toList();

    for (final item in childElements) {
      final ancestor = HtmlUtils.getNodeWithAncestors(item);
      final ancestorNode = ancestor.node;
      if (ancestorNode is dom.DocumentFragment) {
        final html = HtmlUtils.fragmentToHtml(ancestorNode);
        print('${item.node.localName}: $html');
      } else if (ancestorNode is dom.Document) {
        final html = HtmlUtils.documentToHtml(ancestorNode);
        print('${item.node.localName}: $html');
      } else if (ancestorNode is dom.Element) {
        final html = HtmlUtils.elementToHtml(ancestorNode);
        print('${item.node.localName}: $html');
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    _pagedHtmlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: ScrollConfiguration(
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

            if (widget.showEndPage &&
                !_hasMorePages &&
                index == _pages.length) {
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

    SchedulerBinding.instance.addPostFrameCallback((_) {
      // print('previousAction: $_previousAction');
      // print('action: $action');
      // TODO: Need to handle when page build is interupted due to navigation and pages are cached
      if (mounted) {
        setState(() {});
      }
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
              page: widget.page,
              requestRebuild: widget.onRequestedRebuild,
              previousAction: widget.previousAction,
              previousEvent: widget.previousEvent,
              maxRebuilds: widget.maxRebuilds,
              currentRebuildCount: widget.currentRebuildCount,
            ),
            children: [
              BoxyId(
                id: 'html_${widget.page}',
                key: ValueKey('HtmlPage-${widget.page}-BoxyId'),
                child: Container(
                  key: ValueKey('HtmlPage-${widget.page}-Container'),
                  color: Colors.grey[300],
                  child:

                      // HtmlWidget(
                      //   // '<h1>Hello World</h1>',
                      //   widget.html,
                      //   key: ValueKey('HtmlWidget-${widget.page}'),
                      //   enableCaching: true,
                      //   renderMode: ListViewMode(
                      //     shrinkWrap: true,
                      //     controller: _controller,
                      //     restorationId: 'html_${widget.page}',
                      //   ),
                      //   customStylesBuilder: (element) {
                      //     Map<String, String>? styles;
                      //     if (element.classes.contains('italic')) {
                      //       styles ??= {};
                      //       styles.addAll({'font-style': 'italic'});
                      //     }
                      //     if (element.classes.contains('bold')) {
                      //       styles ??= {};
                      //       styles.addAll({'font-weight': 'bold'});
                      //     }

                      //     return styles;
                      //   },
                      //   customWidgetBuilder: (element) {
                      //     if (element.styles
                      //         .where((style) => style.hasDartStyle)
                      //         .map((style) => style.property)
                      //         .contains('text-indent')) {
                      //       return Text.rich(
                      //         TextSpan(
                      //           children: [
                      //             const WidgetSpan(child: SizedBox(width: 40)),
                      //             TextSpan(text: element.text),
                      //           ],
                      //         ),
                      //       );
                      //     }
                      //     return null;
                      //   },
                      // ),

                      Html(
                    key: ValueKey('HtmlWidget-${widget.page}'),
                    data: widget.html,
                    shrinkWrap: false, // Restricts width
                    customRenders: {
                      spanMatcher(): CustomRender.inlineSpan(
                          inlineSpan: (context, buildChildren) {
                        final isItalic =
                            context.tree.elementClasses.contains('italic');
                        final isBold =
                            context.tree.elementClasses.contains('bold');
                        return TextSpan(
                          text: context.tree.element?.text ?? '',
                          style: Theme.of(context.buildContext)
                              .textTheme
                              .bodyText2
                              ?.copyWith(
                                fontStyle: isItalic ? FontStyle.italic : null,
                                fontWeight: isBold ? FontWeight.bold : null,
                              ),
                        );
                      }),
                      // 'p': (context, parsedChild) {
                      //   if (context.tree.element?.styles
                      //           .map((style) => style.property)
                      //           .contains('text-indent') ??
                      //       false) {
                      //     // final style = context.tree.element?.styles
                      //     //     .where((style) => style.property == 'text-indent')
                      //     //     .first;
                      //     // print(style?.value?.span);
                      //     return TextSpan(
                      //       children: [
                      //         const WidgetSpan(child: SizedBox(width: 40.0)),
                      //         TextSpan(
                      //             children: [WidgetSpan(child: parsedChild)]),
                      //       ],
                      //     );
                      //   }
                      // }
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  CustomRenderMatcher spanMatcher() =>
      (context) => context.tree.element?.localName == 'span';
}

class _HtmlPageDelegate extends BoxyDelegate {
  _HtmlPageDelegate({
    required final this.page,
    required final this.requestRebuild,
    required this.maxRebuilds,
    required this.currentRebuildCount,
    final HtmlPageAction? previousAction = const HtmlPageAction.addParagraph(),
    final HtmlPageEvent? previousEvent = HtmlPageEvent.hasExtraSpace,
  }) : previousAction = previousAction ?? const HtmlPageAction.addParagraph();

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
