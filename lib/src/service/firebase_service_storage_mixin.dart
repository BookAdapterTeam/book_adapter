import 'dart:io' as io;
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

import '../exceptions/app_exception.dart';

mixin FirebaseServiceStorageMixin {
  FirebaseStorage get storage;

  final _log = Logger();

  // Storage *******************************************************************

  /// List the files the user has uploaded to their folder
  Future<List<String>> listFilenames(String userId) async {
    final firebaseUploadedBooks = await storage.ref(userId).list();
    return firebaseUploadedBooks.items.map((listedItem) => listedItem.name).toList();
  }

  /// Upload a book to Firebase Storage
  Future<UploadTask?> uploadBookDataToFirebaseStorage({
    required String firebaseFilePath,
    required Uint8List bytes,
    Map<String, String>? customMetadata,
  }) async {
    const epubContentType = 'application/epub+zip';

    final uploadTask = await uploadBytes(
      contentType: epubContentType,
      firebaseFilePath: firebaseFilePath,
      bytes: bytes,
      customMetadata: customMetadata,
    );

    return uploadTask;
  }

  /// Upload a book to Firebase Storage
  Future<UploadTask?> uploadBookFileToFirebaseStorage({
    required String firebaseFilePath,
    required String localFilePath,
    Map<String, String>? customMetadata,
  }) async {
    const epubContentType = 'application/epub+zip';

    final uploadTask = await uploadFile(
      contentType: epubContentType,
      firebaseFilePath: firebaseFilePath,
      localFilePath: localFilePath,
      customMetadata: customMetadata,
    );

    return uploadTask;
  }

  /// Upload a book cover photo to Firebase Storage
  Future<UploadTask?> uploadCoverPhoto({
    required Uint8List bytes,
    required String uploadToPath,
  }) async {
    const imageContentType = 'image/jpeg';

    final uploadTask = await uploadBytes(
      bytes: bytes,
      contentType: imageContentType,
      firebaseFilePath: uploadToPath,
    );

    return uploadTask;
  }

  Future<UploadTask?> uploadBytes({
    required String contentType,
    required String firebaseFilePath,
    required Uint8List bytes,
    Map<String, String>? customMetadata,
  }) async {
    try {
      // Check if file exists, return null if it does
      await storage.ref(firebaseFilePath).getDownloadURL();
      return null;
    } on FirebaseException catch (e, st) {
      if (e.code != 'unauthorized') {
        _log.e('${e.code} + ${e.message ?? ''}', e, st);
        rethrow;
      }

      try {
        // File does not exist, continue uploading
        return storage.ref(firebaseFilePath).putData(
              bytes,
              SettableMetadata(
                contentType: contentType,
                customMetadata: customMetadata,
              ),
            );
      } on FirebaseException catch (e, st) {
        _log.e('${e.code} + ${e.message ?? ''}', e, st);
        rethrow;
      }
    }
  }

  /// Upload a file to FirebaseStorage
  Future<UploadTask?> uploadFile({
    required String contentType,
    required String firebaseFilePath,
    required String localFilePath,
    Map<String, String>? customMetadata,
  }) async {
    try {
      // Check if file exists, exit if it does
      await storage.ref(firebaseFilePath).getDownloadURL();

      return null;
    } on FirebaseException catch (e, st) {
      if (e.code != 'unauthorized') {
        _log.e('${e.code} + ${e.message ?? ''}', e, st);
        rethrow;
      }

      // File does not exist, continue uploading
      try {
        final task = storage.ref(firebaseFilePath).putFile(
              io.File(localFilePath),
              SettableMetadata(
                contentType: contentType,
                customMetadata: customMetadata,
              ),
            );

        return task;
      } on FirebaseException catch (e, st) {
        _log.e('${e.code} + ${e.message ?? ''}', e, st);
        rethrow;
      }
    }
  }

  Future<String> getFileDownloadUrl(String storagePath) =>
      storage.ref(storagePath).getDownloadURL();

  /// Download a file to memory
  ///
  /// Thorws `AppException` if it fails
  DownloadTask downloadFile({
    required String firebaseFilePath,
    required String downloadToLocation,
  }) {
    final downloadToFile = io.File(downloadToLocation);

    try {
      final fileRef = storage.ref(firebaseFilePath);
      return fileRef.writeToFile(downloadToFile);
    } on FirebaseException catch (e, st) {
      _log.e(e.message, e, st);
      throw AppException(e.message, e.code);
    }
  }

  /// Check if a file exists on the server
  Future<bool> fileExists(String firebaseFilePath) async {
    try {
      await storage.ref(firebaseFilePath).getDownloadURL();
      return true;
    } on FirebaseException catch (e, st) {
      if (e.code == 'unauthorized') {
        _log.e(e.message, e, st);
        return false;
      }
      rethrow;
    }
  }

  Future<void> deleteFile(String firebaseFilePath) => storage.ref(firebaseFilePath).delete();
}
