import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/localization/app.i18n.dart';
import 'package:flutter/material.dart';

/// Displays detailed information about a BookItem.
class BookReaderView extends StatelessWidget {
  const BookReaderView({Key? key}) : super(key: key);

  static const routeName = '/book_reader';

  @override
  Widget build(BuildContext context) {
    // Convert the passed in book back to a book object
    final Map<String, dynamic> bookMap = ModalRoute.of(context)!.settings.arguments! as Map<String, dynamic>;
    final book = Book.fromMapSerializable(bookMap);
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: Center(
        child: Text('This is the reader in the future'.i18n),
      ),
    );
  }
}
