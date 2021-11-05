import 'package:book_adapter/controller/storage_controller.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/reader/book_reader_view_controller.dart';
import 'package:book_adapter/features/reader/epub_controller.dart';
import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:url_launcher/url_launcher.dart';

/// Displays detailed information about a BookItem.
class BookReaderView extends HookConsumerWidget {
  const BookReaderView({Key? key}) : super(key: key);

  static const routeName = '/book_reader';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = Logger();
    // Convert the passed in book back to a book object
    final Map<String, dynamic> bookMap =
        ModalRoute.of(context)!.settings.arguments! as Map<String, dynamic>;
    final storageController = ref.watch(storageControllerProvider);
    final book = Book.fromMapSerializable(bookMap);
    log.i(book.lastReadCfiLocation);
    final epubReaderController = useEpubController(
      document: EpubReader.readBook(storageController.getBookData(book)),
      epubCfi: book.lastReadCfiLocation,
    );

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
        onExternalLinkPressed: (link) async {
          log.i('Attempting to open link: ' + link);

          await launch(link);
          log.i('Launched link: ' + link);
        },
        onChange: (value) => onChange(
          context,
          epubChapterViewValue: value,
          bookId: book.id,
          epubReaderController: epubReaderController,
          read: ref.read,
        ),
      ),
    );
  }

  Future<void> onChange(
    BuildContext context, {
    EpubChapterViewValue? epubChapterViewValue,
    required String bookId,
    required EpubController epubReaderController,
    required Reader read,
  }) async {
    // print('change');
    if (epubChapterViewValue == null) return;

    final paragraphNum = epubChapterViewValue.paragraphNumber;

    // Only update the firebase last read cfi location every few paragraphs
    final updateFrequency = getValueForScreenType<int>(
      context: context,
      mobile: 3,
      tablet: 5,
      desktop: 7,
      watch: 1,
    );
    if (paragraphNum % updateFrequency == 0) {
      final cfi = epubReaderController.generateEpubCfi();
      if (cfi == null) return;
      final fail = await read(readerViewControllerProvider.notifier)
          .saveLastReadLocation(cfi, bookId: bookId);

      // Show snackbar with error if there is an error
      if (fail == null) return;
      final snackBar = SnackBar(
        content: Text(fail.message),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
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
