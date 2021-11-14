import 'dart:async';

import 'package:book_adapter/data/app_exception.dart';
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

  // Database ************************************************************************************************

  // Firestore BookCollections reference
  CollectionReference<BookCollection> get _collectionsRef =>
      _firestore.collection('collections').withConverter<BookCollection>(
            fromFirestore: (doc, _) {
              final data = doc.data();
              data!.addAll({'id': doc.id});
              return BookCollection.fromMap(data);
            },
            toFirestore: (collection, _) => collection.toMap(),
          );

  // Get book collections stream
  Stream<QuerySnapshot<BookCollection>> get collectionsStream {
    return _collectionsRef
        .where('userId', isEqualTo: currentUserUid)
        .snapshots();
  }

  // Firestore BookCollections reference
  CollectionReference<Book> get _booksRef =>
      _firestore.collection('books').withConverter<Book>(
            fromFirestore: (doc, _) {
              final data = doc.data();
              data!.addAll({'id': doc.id});
              return Book.fromMapFirebase(data);
            },
            toFirestore: (book, _) => book.toMapFirebase(),
          );

  // Get books stream
  Stream<QuerySnapshot<Book>> get booksStream {
    return _booksRef.where('userId', isEqualTo: currentUserUid).snapshots();
  }

  // Firestore BookCollections reference
  CollectionReference<Series> get _seriesRef =>
      _firestore.collection('series').withConverter<Series>(
            fromFirestore: (doc, _) {
              final data = doc.data();
              data!.addAll({'id': doc.id});
              return Series.fromMapFirebase(data);
            },
            toFirestore: (series, _) => series.toMapFirebase(),
          );

  // Get series stream
  Stream<QuerySnapshot<Series>> get seriesStream {
    return _seriesRef.where('userId', isEqualTo: currentUserUid).snapshots();
  }

  // Books *****************************************************************************************************

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
  Future<Either<Failure, List<Book>>> getBooks() async {
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
  Future<Either<Failure, BookCollection>> addCollection(
    String collectionName,
  ) async {
    try {
      final userId = currentUserUid;
      if (userId == null) {
        return Left(Failure('User not logged in'));
      }

      // Create a shelf with a custom id so that it can easily be referenced later
      final bookCollection = BookCollection(
          id: '$userId-$collectionName', name: collectionName, userId: userId);
      await _collectionsRef.doc('$userId-$collectionName').set(bookCollection);

      // Return the shelf to the caller in case they care
      return Right(bookCollection);
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(e.message ?? e.toString(), e.code));
    } on Exception catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Add book to collections
  ///
  /// Takes a book and adds the series id to it
  ///
  /// Throws [AppException] if it fails.
  Future<void> setBookCollections({
    required String bookId,
    required Set<String> collectionIds,
  }) async {
    try {
      await _booksRef
          .doc(bookId)
          .update({'collectionIds': collectionIds.toList()});
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
  /// Throws [AppException] if it fails.
  Future<void> setSeriesCollections({
    required String seriesId,
    required Set<String> collectionIds,
  }) async {
    try {
      await _seriesRef
          .doc(seriesId)
          .update({'collectionIds': collectionIds.toList()});
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
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
      await _booksRef.doc(bookId).update(
          {'seriesId': seriesId, 'collectionIds': collectionIds.toList()});
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
  Future<void> deleteDocument(String path) async {
    try {
      await _firestore.doc(path).delete();
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
