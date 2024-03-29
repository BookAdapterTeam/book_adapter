import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:epubx/epubx.dart';
// ignore: implementation_imports
import 'package:epubx/src/ref_entities/epub_byte_content_file_ref.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../features/library/data/book_item.dart';
import '../../service/isolate_service.dart';

final epubServiceProvider = Provider<EPUBParseController>((ref) => EPUBParseController());

/// A utility class to handle all Firebase calls
class EPUBParseController {
  EPUBParseController();

  static const _uuid = Uuid();

  /// Open an EPUB book and return [Book] with the following entered
  ///
  /// - id
  /// - userId
  /// - title
  /// - subtitle (authors)
  /// - addedDate
  /// - filepath
  /// - filesize
  /// - collectionIds
  Future<Book> parseDetails(
    Uint8List bytes, {
    required String cacheFilePath,
    required String userId,
    required String collectionName,
    String? id,
  }) async {
    final idValue = id ?? _uuid.v4();

    final file = io.File(cacheFilePath);
    final openedBook = await EpubReader.openBook(bytes);

    final title = openedBook.Title ?? '';
    final subtitle = openedBook.AuthorList?.join(', ') ?? openedBook.Author ?? '';
    final filesize = await file.length();

    // Filename: Max filename is 127 characters
    final cutFilename = _getFilename(cacheFilePath, idValue);

    final firebaseFilePath = '$userId/$cutFilename';

    return Book(
      id: idValue,
      userId: userId,
      title: title,
      subtitle: subtitle,
      addedDate: DateTime.now().toUtc(),
      filepath: firebaseFilePath,
      filesize: filesize,
      collectionIds: {
        '$userId-$collectionName',
      },
    );
  }

  String _getFilename(String cacheFilePath, String id) {
    final ioFilename = cacheFilePath.split('/').last;

    // No extension
    final splitFilename = ioFilename.split('.');
    if (splitFilename.length == 1) return '$ioFilename-$id';

    // Put the ID before the extension
    final extension = splitFilename.last;
    final filename = '${_removeExtension(ioFilename)}-$id.$extension';

    // Make sure the filename is not too long for android
    final startingIndex = max(0, filename.length - 127);
    final cutFilename = filename.substring(startingIndex, filename.length);
    return cutFilename;
  }

  /// Remove file extension from a string
  String _removeExtension(String filePath) {
    final splitString = filePath.split('.');

    // No extension
    if (splitString.length == 1) return filePath;

    splitString.removeLast();
    final stringWithoutExtension = splitString.join('.');

    return stringWithoutExtension;
  }

  /// Create filename for cover image
  String getCoverFilename(String cacheFilePath, String id, String extension) {
    final ioFilename = cacheFilePath.split('/').last;

    // Put the ID before the extension
    final filename = '${_removeExtension(ioFilename)}-$id.$extension';

    // Make sure the filename is not too long for android
    final startingIndex = max(0, filename.length - 127);
    final cutFilename = filename.substring(startingIndex, filename.length);
    return cutFilename;
  }

  /// Get the relative filepath that can be used for Firestore or
  /// inside the app's local storage folder
  String getRelativeFilepath({
    required String userId,
    required String cacheFilePath,
    required String id,
  }) {
    final filename = _getFilename(cacheFilePath, id);
    final firebaseFilePath = '$userId/$filename';
    return firebaseFilePath;
  }

  /// Read the cover image of an EPUB into memory. If one cannot be found,
  /// null is returned.
  Future<Uint8List?> getCoverImage(Uint8List bookBytes) async {
    final log = Logger();
    final openedBook = await EpubReader.openBook(bookBytes);
    var coverImage = await openedBook.readCover();

    if (coverImage == null) {
      // No cover image, use the first image instead
      final imagesRef = openedBook.Content?.Images;

      if (imagesRef == null) {
        // No images found in book
        return null;
      }

      // Use the first image that has a height greater than width
      // to avoid using banners and copyright notices
      log.i('Decoding Images');
      final imageFuture = IsolateService.sendListAndReceiveSingle<EpubByteContentFileRef, Image?>(
        imagesRef.values.toList(),
        receiveAndReturnService: IsolateService.readAndDecodeImageService,
      );

      coverImage = await imageFuture;

      log.i('Decoding Images Done');

      if (coverImage == null) {
        final firstImageFuture =
            IsolateService.sendSingleAndReceive<EpubByteContentFileRef, Image?>(
          imagesRef.values.first,
          receiveAndReturnService: IsolateService.readAndDecodeImageService,
        );
        log.i('Decoding First Image');
        coverImage = await firstImageFuture;
        log.i('Decoding First Image Done');
      }
    }

    // Could not get cover image for upload
    if (coverImage == null) return null;

    final encodeImageFuture = IsolateService.sendSingleAndReceive<Image, Uint8List>(
      coverImage,
      receiveAndReturnService: IsolateService.readAndEncodeImageService,
    );
    log.i('Encoding Image');
    final imageBytes = await encodeImageFuture;
    log.i('Encoding Image Done');

    return imageBytes;
  }
}
