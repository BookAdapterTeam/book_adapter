import 'dart:io' as io;
import 'dart:typed_data';

import 'package:book_adapter/data/app_exception.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:epub_view/epub_view.dart';
import 'package:epubx/epubx.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';

mixin FirebaseServiceStorageMixin {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  final _log = Logger();

  // Storage *****************************************************************************************

  /// List the files the user has uploaded to their folder
  Future<List<String>> listFilenames(String userId) async {
    final firebaseUploadedBooks = await _firebaseStorage.ref(userId).list();
    return firebaseUploadedBooks.items
        .map((listedItem) => listedItem.name)
        .toList();
  }

  /// Upload a book to Firebase Storage
  Future<Either<Failure, String>> uploadBookToFirebaseStorage({
    required String firebaseFilePath,
    required String localFilePath,
  }) async {
    const String epubContentType = 'application/epub+zip';

    try {
      final res = await uploadFile(
        contentType: epubContentType,
        firebaseFilePath: firebaseFilePath,
        localFilePath: localFilePath,
      );

      return res;
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(
          e.message ?? 'Unknown Firebase Exception, Could Not Upload Book',
          e.code));
    } on Exception catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Upload a book cover photo to Firebase Storage
  Future<Either<Failure, String>> uploadCoverPhoto({
    required EpubBookRef openedBook,
    required String uploadToPath,
  }) async {
    const imageContentType = 'image/jpeg';
    try {
      Image? image = await openedBook.readCover();

      if (image == null) {
        // No cover image, use the first image instead
        final imagesRef = openedBook.Content?.Images;

        if (imagesRef == null) {
          // images from epub is null
          return Left(Failure('Book has no images'));
        }

        // Use the first image that has a height greater than width to avoid using banners and copyright notices
        for (final imageRef in imagesRef.values) {
          final imageContent = await imageRef.readContent();
          final img.Image? cover = img.decodeImage(imageContent);
          if (cover != null && cover.height > cover.width) {
            image = cover;
            break;
          }
        }

        // If no applicable image found above, use the first image
        if (image == null) {
          final imageContent = await imagesRef.values.first.readContent();
          image = img.decodeImage(imageContent);
        }
      }

      if (image == null) {
        return Left(Failure('Could not get cover image for upload'));
      }

      final bytes = img.encodeJpg(image);

      final res = await uploadBytes(
        bytes: Uint8List.fromList(bytes),
        contentType: imageContentType,
        firebaseFilePath: uploadToPath,
      );

      return res;
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(
          e.message ?? 'Unknown Firebase Exception, Could Not Upload Book',
          e.code));
    } on Exception catch (e) {
      return Left(Failure(e.toString()));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, String>> uploadBytes({
    required String contentType,
    required String firebaseFilePath,
    required Uint8List bytes,
  }) async {
    try {
      // Check if file exists, exit if it does
      await _firebaseStorage.ref(firebaseFilePath).getDownloadURL();
      return Left(Failure('File already exists'));
    } on FirebaseException catch (_) {
      // File does not exist, continue uploading
      await _firebaseStorage.ref(firebaseFilePath).putData(
            bytes,
            SettableMetadata(contentType: contentType),
          );
      final url = await _firebaseStorage.ref(firebaseFilePath).getDownloadURL();
      return Right(url);
    }
  }

  /// Upload a file to FirebaseStorage
  ///
  /// Thorws `AppException` if it fails
  Future<Either<Failure, String>> uploadFile({
    required String contentType,
    required String firebaseFilePath,
    required String localFilePath,
  }) async {
    try {
      // Check if file exists, exit if it does
      await _firebaseStorage.ref(firebaseFilePath).getDownloadURL();
      return Left(Failure('File already exists'));
    } on FirebaseException catch (_) {
      // File does not exist, continue uploading
      final UploadTask task = _firebaseStorage.ref(firebaseFilePath).putFile(
            io.File(localFilePath),
            SettableMetadata(contentType: contentType),
          );

      // TODO: Somehow expose this to UI for upload progress
      /*final TaskSnapshot snapshot = */ await task;

      final url = await _firebaseStorage.ref(firebaseFilePath).getDownloadURL();
      return Right(url);
    }
  }

  /// Download a file to memory
  ///
  /// Thorws `AppException` if it fails
  DownloadTask downloadFile({
    required String firebaseFilePath,
    required String downloadToLocation,
  }) {
    final io.File downloadToFile = io.File(downloadToLocation);

    try {
      final fileRef = _firebaseStorage.ref(firebaseFilePath);
      final DownloadTask task = fileRef.writeToFile(downloadToFile);
      return task;
    } on FirebaseException catch (e, st) {
      _log.e(e.message, e, st);
      throw AppException(e.message, e.code);
    }
  }

  /// Check if a file exists on the server
  Future<bool> fileExists(String firebaseFilePath) async {
    try {
      await _firebaseStorage.ref(firebaseFilePath).getDownloadURL();
      return true;
    } on FirebaseException catch (e, _) {
      return false;
    }
  }

  Future<void> deleteFile(String firebaseFilePath) async {
    await _firebaseStorage.ref(firebaseFilePath).delete();
  }
}
