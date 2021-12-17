import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:epubx/epubx.dart';
// ignore: implementation_imports
import 'package:epubx/src/ref_entities/epub_byte_content_file_ref.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../service/isolate_service.dart';
import '../library/data/book_item.dart';

final epubServiceProvider = Provider<EPUBParseController>((ref) {
  return EPUBParseController();
});

/// A utility class to handle all Firebase calls
class EPUBParseController {
  EPUBParseController();

  static const _uuid = Uuid();

  Future<Book> parseDetails(
    Uint8List bytes, {
    required String cacheFilePath,
    required String userId,
    required String collectionName,
    String? id,
  }) async {
    final String _id = id ?? _uuid.v4();

    final file = io.File(cacheFilePath);
    final openedBook = await EpubReader.openBook(bytes);

    final title = openedBook.Title ?? '';
    final subtitle =
        openedBook.AuthorList?.join(', ') ?? openedBook.Author ?? '';
    final filesize = await file.length();

    // Filename: Max filename is 127 characters
    final cutFilename = _getFilename(cacheFilePath, _id);

    final firebaseFilePath = '$userId/$cutFilename';

    return Book(
      id: _id,
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
    final extension = ioFilename.split('.').last;

    final String filename;
    if (extension == ioFilename) {
      // No file extension
      filename = '$ioFilename-$id';
    } else {
      // has file extension
      filename = '${ioFilename.replaceAll(extension, '')}-$id.$extension';
    }

    final startingIndex = max(0, filename.length - 127);
    final cutFilename = filename.substring(startingIndex, filename.length);
    return cutFilename;
  }

  String getCoverFilename(String cacheFilePath, String id, String ext) {
    final ioFilename = cacheFilePath.split('/').last;
    final extension = ioFilename.split('.').last;

    final String filename;
    if (extension == ioFilename) {
      // No file extension, add new one
      filename = '$ioFilename-$id.$ext';
    } else {
      // has file extension, remove it and add new one
      filename = '${ioFilename.replaceAll('.$extension', '')}-$id.$ext';
    }

    final startingIndex = max(0, filename.length - 127);
    final cutFilename = filename.substring(startingIndex, filename.length);
    return cutFilename;
  }

  String getFirebaseFilepath({
    required String userId,
    required String cacheFilePath,
    required String id,
  }) {
    final filename = _getFilename(cacheFilePath, id);
    final firebaseFilePath = '$userId/$filename';
    return firebaseFilePath;
  }

  Future<Uint8List?> getCoverImage(Uint8List bookBytes) async {
    final log = Logger();
    final openedBook = await EpubReader.openBook(bookBytes);
    Image? coverImage = await openedBook.readCover();

    if (coverImage == null) {
      // No cover image, use the first image instead
      final imagesRef = openedBook.Content?.Images;

      if (imagesRef == null) {
        // No images found in book
        return null;
      }

      // Use the first image that has a height greater than width to avoid using banners and copyright notices
      log.i('Decoding Images');
      final imagesFuture =
          IsolateService.sendListAndReceiveList<EpubByteContentFileRef, Image?>(
        imagesRef.values.toList(),
        receiveAndReturnService: IsolateService.readAndDecodeImageService,
      );

      final images = await imagesFuture;

      for (final cover in images) {
        if (coverImage == null && cover != null && cover.height > cover.width) {
          coverImage = cover;
        }
      }

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

    final encodeImageFuture =
        IsolateService.sendSingleAndReceive<Image, Uint8List>(
      coverImage,
      receiveAndReturnService: IsolateService.readAndEncodeImageService,
    );
    log.i('Encoding Image');
    final imageBytes = await encodeImageFuture;
    log.i('Encoding Image Done');

    return imageBytes;
  }
}
