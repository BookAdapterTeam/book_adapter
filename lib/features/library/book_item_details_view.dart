import 'package:book_adapter/features/library/book_item.dart';
import 'package:book_adapter/localization/app.i18n.dart';
import 'package:flutter/material.dart';

/// Displays detailed information about a BookItem.
class BookItemDetailsView extends StatelessWidget {
  const BookItemDetailsView({Key? key}) : super(key: key);

  static const routeName = '/book_details';

  @override
  Widget build(BuildContext context) {
    // Convert the passed in book back to a book object
    final Map<String, dynamic> bookMap = ModalRoute.of(context)!.settings.arguments! as Map<String, dynamic>;
    final book = BookItem.fromMap(bookMap);
    return Scaffold(
      appBar: AppBar(
        title: Text('${book.name} Book Details'.i18n),
      ),
      body: Center(
        child: Text('More Information Here'.i18n),
      ),
    );
  }
}
