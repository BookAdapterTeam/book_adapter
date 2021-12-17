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
      filename = '${ioFilename.replaceAll(extension, '')}-$id.$ext';
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

  Future<List<int>?> getCoverImage(Uint8List data) async {
    final log = Logger();
    final openedBook = await EpubReader.openBook(List.from(data));
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
      final imagesStream =
          IsolateService.sendAndReceive<EpubByteContentFileRef, Image?>(
        imagesRef.values.toList(),
        receiveAndReturnService: IsolateService.readAndDecodeImageService,
      );
      await for (final cover in imagesStream) {
        // final imageContent = await imageRef.readContent();
        // final img.Image? cover = img.decodeImage(imageContent);
        if (cover != null && cover.height > cover.width) {
          coverImage = cover;
          break;
        }
      }
      log.i('Decoding Images Done');

      final firstImageStream =
          IsolateService.sendAndReceive<EpubByteContentFileRef, Image?>(
        [imagesRef.values.first],
        receiveAndReturnService: IsolateService.readAndDecodeImageService,
      );
      log.i('Decoding Image');
      await for (final cover in firstImageStream) {
        coverImage = cover;
      }
      log.i('Decoding Image Done');
    }

    if (coverImage == null) {
      // Could not get cover image for upload
      return null;
    }

    final firstImageStream = IsolateService.sendAndReceive<Image, List<int>>(
      [coverImage],
      receiveAndReturnService: IsolateService.readAndEncodeImageService,
    );
    log.i('Encoding Image');
    final bytes = await firstImageStream.first;
    log.i('Encoding Image Done');

    return bytes;
  }
}
