import 'package:flutter/material.dart';
import 'package:paged_html/paged_html.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PagedHtmlExample(),
    );
  }
}

class PagedHtmlExample extends StatelessWidget {
  const PagedHtmlExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PagedHtml Example')),
      body: PagedHtml(
        key: const ValueKey('HtmlReader'),
        scrollDirection: Axis.horizontal,
        physics: const PageScrollPhysics(),
        html: '''
<div>
  <h1>PagedHtml</h1>
  <p>A Widget that displays the html in horizontal or verticle pages</p>
  <p>
    <a href="https://pub.dev/packages/paged_html">
      https://pub.dev/packages/paged_html
    </a>
  </p>
  <p>
    <a href="https://pub.dev/packages/paged_html#readme">
      https://pub.dev/packages/paged_html#readme
    </a>
  </p>
  <p>
    <a href="https://pub.dev/packages/paged_html#example">
      https://pub.dev/packages/paged_html#example
    </a>
  </p>
</div>
''' *
            5,
      ),
    );
  }
}
