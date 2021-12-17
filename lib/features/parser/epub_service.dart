import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

import '../library/data/book_item.dart';

final epubServiceProvider = Provider<EPUBService>((ref) {
  return EPUBService();
});

/// A utility class to handle all Firebase calls
class EPUBService {
  EPUBService();

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
      for (final imageRef in imagesRef.values) {
        final imageContent = await imageRef.readContent();
        final img.Image? cover = img.decodeImage(imageContent);
        if (cover != null && cover.height > cover.width) {
          coverImage = cover;
          break;
        }
      }

      // If no applicable image found above, use the first image
      if (coverImage == null) {
        final imageContent = await imagesRef.values.first.readContent();
        coverImage = img.decodeImage(imageContent);
      }
    }

    if (coverImage == null) {
      // Could not get cover image for upload
      return null;
    }

    final bytes = img.encodeJpg(coverImage);

    return bytes;
  }
}
