import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;

final epubServiceProvider = Provider<EPUBService>((ref) {
  return EPUBService();
});

/// A utility class to handle all Firebase calls
class EPUBService {
  EPUBService();

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
