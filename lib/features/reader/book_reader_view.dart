import 'package:book_adapter/controller/storage_controller.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/reader/epub_controller.dart';
import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

/// Displays detailed information about a BookItem.
class BookReaderView extends HookConsumerWidget {
  const BookReaderView({Key? key}) : super(key: key);

  static const routeName = '/book_reader';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Convert the passed in book back to a book object
    final Map<String, dynamic> bookMap =
        ModalRoute.of(context)!.settings.arguments! as Map<String, dynamic>;
    final storageController = ref.watch(storageControllerProvider);
    final book = Book.fromMapSerializable(bookMap);
    final epubReaderController = useEpubController(
        document: EpubReader.readBook(storageController.getBookData(book)));
    final log = Logger();

    return Scaffold(
      appBar: AppBar(
        title: EpubActualChapter(
          controller: epubReaderController,
          builder: (chapterValue) => Text(
            (chapterValue?.chapter?.Title?.trim() ?? '').replaceAll('\n', ''),
            textAlign: TextAlign.start,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.save_alt),
            color: Colors.white,
            onPressed: () => _showCurrentEpubCfi(
                context: context, controller: epubReaderController),
          ),
        ],
      ),
      drawer: Drawer(
        child: EpubReaderTableOfContents(controller: epubReaderController),
      ),
      body: EpubView(
        controller: epubReaderController,
        onDocumentLoaded: (document) {
          log.i('isLoaded: $document');
        },
        onExternalLinkPressed: (link) {
          // TODO: Implement url_launcher package
          // print(link);
        },
        // itemBuilder: (context, chapters, paragraphs, paragraphIndex) {
        //   if (paragraphs.isEmpty) {
        //     return Container();
        //   }

        //   return Html(
        //     data: paragraphs[paragraphIndex].element.outerHtml,
        //     onLinkTap: ,
        //   );

        //   // return Column(
        //   //   children: [
        //   //     // if (paragraphs[paragraphIndex].chapterIndex >= 0 && )
        //   //     //   ChapterDivider(chapter: chapters[paragraphIndex],),
        //   //     SelectableText('''
        //   //         ${paragraphs[paragraphIndex].chapterIndex}
        //   //         ${paragraphs[paragraphIndex].element.outerHtml}
        //   //         '''),
        //   //   ],
        //   // );
        // },
      ),
    );
  }

  void _showCurrentEpubCfi({
    required BuildContext context,
    required EpubController controller,
  }) {
    final cfi = controller.generateEpubCfi();

    if (cfi != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cfi),
          action: SnackBarAction(
            label: 'GO',
            onPressed: () {
              controller.gotoEpubCfi(cfi);
            },
          ),
        ),
      );
    }
  }
}
