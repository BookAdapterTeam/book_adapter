import 'dart:async';

import 'package:book_adapter/data/app_exception.dart';
import 'package:book_adapter/data/constants.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/series_item.dart';
import 'package:book_adapter/service/firebase_service_auth_mixin.dart';
import 'package:book_adapter/service/firebase_service_storage_mixin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Provider to easily get access to the [FirebaseService] functions
final firebaseServiceProvider = Provider.autoDispose<FirebaseService>((ref) {
  return FirebaseService();
});

/// A utility class to handle all Firebase calls
class FirebaseService
    with FirebaseServiceAuthMixin, FirebaseServiceStorageMixin {
  FirebaseService() : super();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const uuid = Uuid();

  String getDefaultCollectionName(String userUid) => '$userUid-Default';

  // Database ************************************************************************************************

  /// Firestore BookCollections reference
  CollectionReference<AppCollection> get _collectionsRef => _firestore
      .collection(kCollectionsCollectionName)
      .withConverter<AppCollection>(
        fromFirestore: (doc, _) {
          final data = doc.data();
          data!.addAll({'id': doc.id});
          return AppCollection.fromMap(data);
        },
        toFirestore: (collection, _) => collection.toMap(),
      );

  /// Get book collections stream
  Stream<QuerySnapshot<AppCollection>> get collectionsStream {
    return _collectionsRef
        .where('userId', isEqualTo: currentUserUid)
        .snapshots();
  }

  /// Get a book collection document from Firestore by its document id
  ///
  /// Returns the [AppCollection] object if it exists, otherewise returns `null`
  Future<AppCollection?> getCollectionById(String collectionId) async =>
      (await _collectionsRef.doc(collectionId).get()).data();

  /// Firestore BookCollections reference
  CollectionReference<Book> get _booksRef =>
      _firestore.collection(kBooksCollectionName).withConverter<Book>(
            fromFirestore: (doc, _) {
              final data = doc.data();
              data!.addAll({'id': doc.id});
              return Book.fromMapFirebase(data);
            },
            toFirestore: (book, _) => book.toMapFirebase(),
          );

  /// Get books stream
  Stream<QuerySnapshot<Book>> get booksStream {
    return _booksRef.where('userId', isEqualTo: currentUserUid).snapshots();
  }

  /// Get a book document from Firestore by its document id
  ///
  /// Returns the [Book] object if it exists, otherewise returns `null`
  Future<Book?> getBookDocumentById(String bookId) async =>
      (await _booksRef.doc(bookId).get()).data();

  /// Firestore BookCollections reference
  CollectionReference<Series> get _seriesRef =>
      _firestore.collection(kSeriesCollectionName).withConverter<Series>(
            fromFirestore: (doc, _) {
              final data = doc.data();
              data!.addAll({'id': doc.id});
              return Series.fromMapFirebase(data);
            },
            toFirestore: (series, _) => series.toMapFirebase(),
          );

  /// Get series stream
  Stream<QuerySnapshot<Series>> get seriesStream {
    return _seriesRef.where('userId', isEqualTo: currentUserUid).snapshots();
  }

  /// Get a series document from Firestore by its document id
  ///
  /// Returns the [Series] object if it exists, otherewise returns `null`
  Future<Series?> getSeriesById(String seriesId) async =>
      (await _seriesRef.doc(seriesId).get()).data();

  // Books *****************************************************************************************************

  /// Save a cfi to lastReadCfiLocation on a book document in Firestore
  Future<void> saveLastReadCfiLocation({
    required String lastReadCfiLocation,
    required String bookId,
  }) async {
    try {
      final userId = currentUserUid;
      if (userId == null) {
        throw AppException('user-null');
      }

      await _booksRef
          .doc(bookId)
          .update({'lastReadCfiLocation': lastReadCfiLocation});
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      rethrow;
    }
  }

  /// Get a list of books from the user's database
  Future<Either<Failure, List<Book>>> getAllBooks() async {
    try {
      final userId = currentUserUid;
      if (userId == null) {
        return Left(Failure('User not logged in'));
      }

      final bookQuery =
          await _booksRef.where('userId', isEqualTo: userId).get();
      final books = bookQuery.docs.map((doc) => doc.data()).toList();

      // Return our books to the caller in case they care
      // ignore: prefer_const_constructors
      return Right(books);
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(
          e.message ?? 'Unknown Firebase Exception, Could Not Refresh Books',
          e.code));
    } on Exception catch (_) {
      return Left(Failure('Unexpected Exception, Could Not Refresh Books'));
    }
  }

  /// Add a book to Firebase Firestore
  Future<Either<Failure, Book>> addBookToFirestore({required Book book}) async {
    try {
      // Check books for duplicates, return Failure if any are found
      final duplicatesQuerySnapshot = await _booksRef
          .where('userId', isEqualTo: book.userId)
          .where('title', isEqualTo: book.title)
          .where('filepath', isEqualTo: book.filepath)
          .where('filesize', isEqualTo: book.filesize)
          .get();

      final duplicates = duplicatesQuerySnapshot.docs;

      if (duplicates.isNotEmpty) {
        return Left(Failure('Book has already been uploaded'));
      }

      // Add book to Firestore
      await _booksRef.doc(book.id).set(book);

      // Return our books to the caller in case they care
      // ignore: prefer_const_constructors
      return Right(book);
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(
          e.message ?? 'Unknown Firebase Exception, Could Not Upload Book',
          e.code));
    } on Exception catch (_) {
      return Left(Failure('Unexpected Exception, Could Not Upload Book'));
    }
  }

  // BookCollections ********************************************************************************************

  /// Create a shelf in firestore
  Future<Either<Failure, AppCollection>> addCollection(
    String collectionName,
  ) async {
    try {
      final userId = currentUserUid;
      if (userId == null) {
        return Left(Failure('User not logged in'));
      }

      // Create a shelf with a custom id so that it can easily be referenced later
      final bookCollection = AppCollection(
        id: '$userId-$collectionName',
        name: collectionName,
        userId: userId,
      );
      // ignore: unawaited_futures
      _collectionsRef.doc(bookCollection.id).set(bookCollection);

      // Return the shelf to the caller in case they care
      return Right(bookCollection);
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(e.message ?? e.toString(), e.code));
    } on Exception catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Update a book's collections
  ///
  /// Takes a book and adds the collectionIds to it.
  ///
  /// If a book does not have any collections, it will move it to the default collection
  ///
  /// Throws [AppException] if it fails.
  Future<void> updateBookCollections({
    required String bookId,
    List<String>? collectionIds,
  }) async {
    try {
      if (currentUserUid == null) return;

      collectionIds ??= [];
      if (collectionIds.isEmpty) {
        final String defaultCollection =
            getDefaultCollectionName(currentUserUid!);
        collectionIds.add(defaultCollection);
      }

      return _booksRef.doc(bookId).update({'collectionIds': collectionIds});
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
  }

  /// Add series to collections
  ///
  /// Takes a series and adds the series id to it
  ///
  /// If a book does not have any collections, it will move it to the default collection
  ///
  /// Throws [AppException] if it fails.
  Future<void> updateSeriesCollections({
    required String seriesId,
    List<String>? collectionIds,
  }) async {
    try {
      if (currentUserUid == null) return;

      collectionIds ??= [];
      if (collectionIds.isEmpty) {
        final String defaultCollection =
            getDefaultCollectionName(currentUserUid!);
        collectionIds.add(defaultCollection);
      }
      
      return _seriesRef.doc(seriesId).update({'collectionIds': collectionIds});
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
  }

  /// Update a book's series
  ///
  /// Throws AppException if the book does not exist in Firestore
  Future<void> updateBookSeries(String bookId, String? seriesId) async {
    // ignore: unawaited_futures
    return _booksRef.doc(bookId).update({'seriesId': seriesId});
  }

  // Series *********************************************

  /// Method to add series to firebase firestore, returns a [Series] object
  ///
  /// Throws [AppException] if it fails.
  Future<Series> addSeries(
    String name, {
    required String imageUrl,
    String description = '',
    Set<String>? collectionIds,
  }) async {
    try {
      final userId = currentUserUid;
      if (userId == null) {
        throw AppException('user-null');
      }

      // Create a shelf with a custom id so that it can easily be referenced later
      final String id = uuid.v4();
      final series = Series(
          id: id,
          userId: userId,
          title: name,
          description: description,
          imageUrl: imageUrl,
          collectionIds: collectionIds ?? {'$userId-Default'});
      await _seriesRef.doc(id).set(series);

      // Return the shelf to the caller in case they care
      return series;
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
  }

  /// Add book to series
  ///
  /// Takes a book and adds the series id to it
  Future<void> addBookToSeries({
    required String bookId,
    required String seriesId,
    required Set<String> collectionIds,
  }) async {
    try {
      // ignore: unawaited_futures
      return _booksRef.doc(bookId).update(
        {
          'seriesId': seriesId,
          'collectionIds': collectionIds.toList(),
        },
      );
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
  }

  /// Delete a book firestore document
  ///
  /// path is the firestore path to the document, ie `collection/document/collection/...`
  Future<void> deleteCollectionDocument(String collectionId) async {
    try {
      // ignore: unawaited_futures
      return deleteDocument('$kCollectionsCollectionName/$collectionId');
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
  }

  /// Delete a book firestore document
  ///
  /// path is the firestore path to the document, ie `collection/document/collection/...`
  Future<void> deleteBookDocument(String bookId) async {
    try {
      // ignore: unawaited_futures
      return deleteDocument('$kBooksCollectionName/$bookId');
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
  }

  /// Delete a series firestore document
  ///
  /// path is the firestore path to the document, ie `collection/document/collection/...`
  Future<void> deleteSeriesDocument(String seriesId) async {
    try {
      // ignore: unawaited_futures
      return deleteDocument('$kSeriesCollectionName/$seriesId');
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
  }

  /// Delete a firestore document
  ///
  /// path is the firestore path to the document, ie `collection/document/collection/...`
  Future<void> deleteDocument(String path) async {
    try {
      // ignore: unawaited_futures
      return _firestore.doc(path).delete();
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
  }
}
