import 'dart:async';
import 'dart:typed_data';

import 'package:book_adapter/src/data/app_exception.dart';
import 'package:book_adapter/src/constants/constants.dart';
import 'package:book_adapter/src/data/failure.dart';
import 'package:book_adapter/src/data/file_hash.dart';
import 'package:book_adapter/src/features/library/data/book_collection.dart';
import 'package:book_adapter/src/features/library/data/book_item.dart';
import 'package:book_adapter/src/features/library/data/item.dart';
import 'package:book_adapter/src/features/library/data/series_item.dart';
import 'package:book_adapter/src/service/firebase_service.dart';
import 'package:book_adapter/src/service/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

/// Provider to easily get access to the user stream from [FirebaseService]
final authStateChangesProvider =
    StreamProvider.autoDispose<User?>((ref) async* {
  final firebaseController = ref.watch(firebaseControllerProvider);

  final authStates = firebaseController.authStateChange;

  await for (final user in authStates) {
    yield user;
  }
});

/// Provider to get access to stream of user changes
final userChangesProvider = StreamProvider.autoDispose<User?>((ref) async* {
  final firebaseController = ref.watch(firebaseControllerProvider);
  final userChanges = firebaseController.userChanges;

  await for (final user in userChanges) {
    yield user;
  }
});

// Provide the stream with riverpod for easy access
final collectionsStreamProvider =
    StreamProvider.autoDispose<List<AppCollection>>((ref) async* {
  final firebaseController = ref.watch(firebaseControllerProvider);
  // Parse the value received and emit a Message instance
  try {
    await for (final value in firebaseController.collectionsStream) {
      yield value.docs.map((e) => e.data()).toList();
    }
  } on FirebaseException catch (_) {}
});

// Provide the stream with riverpod for easy access
final bookStreamProvider = StreamProvider.autoDispose<List<Book>>((ref) async* {
  final firebaseController = ref.watch(firebaseControllerProvider);
  // Parse the value received and emit a Message instance
  try {
    await for (final value in firebaseController.booksStream) {
      yield value.docs.map((e) => e.data()).toList();
    }
  } on FirebaseException catch (_) {}
});

// Provide the stream with riverpod for easy access
final seriesStreamProvider =
    StreamProvider.autoDispose<List<Series>>((ref) async* {
  final firebaseController = ref.watch(firebaseServiceProvider);
  // Parse the value received and emit a Message instance
  try {
    await for (final value in firebaseController.seriesStream) {
      yield value.docs.map((e) => e.data()).toList();
    }
  } on FirebaseException catch (_) {}
});

final firebaseControllerProvider =
    Provider.autoDispose<FirebaseController>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return FirebaseController(
    firebaseService: firebaseService,
    storageService: storageService,
  );
});

class FirebaseController {
  FirebaseController({
    required FirebaseService firebaseService,
    required StorageService storageService,
  })  : _firebaseService = firebaseService,
        _storageService = storageService;

  final FirebaseService _firebaseService;
  final StorageService _storageService;
  final log = Logger();
  static const uuid = Uuid();

  // Authentication

  /// Notifies about changes to the user's sign-in state (such as sign-in or
  /// sign-out).
  Stream<User?> get authStateChange => _firebaseService.authStateChange;

  /// Returns the current [User] if they are currently signed-in, or `null` if
  /// not.
  ///
  /// You should not use this getter to determine the users current state,
  /// instead use [authStateChanges], [idTokenChanges] or [userChanges] to
  /// subscribe to updates.
  User? get currentUser {
    return _firebaseService.currentUser;
  }

  /// Notifies about changes to any user updates.
  ///
  /// This is a superset of both [authStateChanges] and [idTokenChanges]. It
  /// provides events on all user changes, such as when credentials are linked,
  /// unlinked and when updates to the user profile are made. The purpose of
  /// this Stream is for listening to realtime updates to the user state
  /// (signed-in, signed-out, different user & token refresh) without
  /// manually having to call [reload] and then rehydrating changes to your
  /// application.
  Stream<User?> get userChanges => _firebaseService.userChanges;

  /// Attempts to sign in a user with the given email address and password.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// the stream [authStateChange]
  ///
  /// **Important**: You must enable Email & Password accounts in the Auth
  /// section of the Firebase console before being able to use them.
  ///
  /// Returns an [Either]
  ///
  /// Right [UserCredential] is returned if successful
  ///
  /// Left [FirebaseFailure] maybe returned with the following error code:
  /// - **invalid-email**:
  ///  - Returned if the email address is not valid.
  /// - **user-disabled**:
  ///  - Returned if the user corresponding to the given email has been disabled
  /// - **user-not-found**:
  ///  - Returned if there is no user corresponding to the given email.
  /// - **wrong-password**:
  ///  - Returned if the password is invalid for the given email, or the account
  ///    corresponding to the email does not have a password set.
  ///
  /// Left [Failure] may also be returned with only the failure message
  /// - **Email cannot be empty**
  ///  - Returned if the email address is empty
  /// - **Password cannot be empty**
  ///  - Returned if the password field is empty
  /// - **Password cannot be less than six characters**
  ///  - Returned if the password is less than six characters
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    // Guards, return Failure object with reason for failure
    // The message should be displayed to the user
    if (email.isEmpty) {
      return Left(Failure('Email cannot be empty'));
    } else if (password.isEmpty) {
      return Left(Failure('Password cannot be empty'));
    } else if (password.length < 6) {
      return Left(Failure('Password cannot be less than six characters'));
    }

    final res = await _firebaseService.signIn(email: email, password: password);

    // If sign in failed, return the failure object
    // If sign in is successful, return the user object in case the caller cares
    return await res.fold(
      Left.new,
      (userCred) async {
        final User? user = userCred.user;
        if (user == null) {
          return Left(Failure('Sign In Failed, User is NULL'));
        }
        await _storageService.createUserDirectory(user.uid);
        return Right(user);
      },
    );
  }

  /// Tries to create a new user account with the given email address and
  /// password.
  ///
  /// Returns an [Either]
  ///
  /// Right [UserCredential] is returned if successful
  ///
  /// Left [FirebaseFailure] maybe returned with the following error code:
  /// - **email-already-in-use**:
  ///  - Returned if there already exists an account with the given
  ///    email address.
  /// - **invalid-email**:
  ///  - Returned if the email address is not valid.
  /// - **operation-not-allowed**:
  ///  - Returned if email/password accounts are not enabled. Enable
  ///    email/password accounts in the Firebase Console, under the Auth tab.
  /// - **weak-password**:
  ///  - Returned if the password is not strong enough.
  ///
  /// Left [Failure] may also be returned with only the failure message
  /// - **Email cannot be empty**
  ///  - Returned if the email address is empty
  /// - **Password cannot be empty**
  ///  - Returned if the password field is empty
  /// - **Password cannot be less than six characters**
  ///  - Returned if the password is less than six characters
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    String? username,
  }) async {
    // Guards, return Failure object with reason for failure
    // The message should be displayed to the user
    if (email.isEmpty) {
      return Left(Failure('Email cannot be empty'));
    } else if (password.isEmpty) {
      return Left(Failure('Password cannot be empty'));
    } else if (password.length < 6) {
      return Left(Failure('Password cannot be less than six characters'));
    }

    final res = await _firebaseService.signUp(email: email, password: password);

    // If sign up failed, return the failure object
    // If sign up is successful, return the user object, update the username
    return await res.fold(
      Left.new,
      (userCred) async {
        final User? user = userCred.user;
        if (user == null) {
          return Left(Failure('Sign Up Failed, User is NULL'));
        }

        // Set username
        if (username != null) {
          await setDisplayName(username);
        }
        await _storageService.createUserDirectory(user.uid);
        return Right(user);
      },
    );
  }

  /// Signs out the current user.
  ///
  /// If successful, it also update the stream [authStateChange]
  Future<void> signOut() async {
    return _firebaseService.signOut();
  }

  /// Send reset password email
  Future<Either<Failure, void>> resetPassword(String email) async {
    return _firebaseService.resetPassword(email);
  }

  /// Set display name
  ///
  /// Returns [true] if successful
  /// Returns [false] if the user is not authenticated
  Future<bool> setDisplayName(String name) async {
    return _firebaseService.setDisplayName(name);
  }

  /// Set profile photo
  ///
  /// Returns [true] if successful
  /// Returns [false] if the user is not authenticated
  Future<bool> setProfilePhoto(String photoURL) async {
    return _firebaseService.setProfilePhoto(photoURL);
  }

  // Database
  Stream<QuerySnapshot<Book>> get booksStream => _firebaseService.booksStream;
  Stream<QuerySnapshot<AppCollection>> get collectionsStream =>
      _firebaseService.collectionsStream;
  Stream<QuerySnapshot<Series>> get seriesStream =>
      _firebaseService.seriesStream;

  /// Save the last read cfi location in firebase
  Future<void> saveLastCfiLocation({
    required String cfi,
    required String bookId,
  }) async {
    return _firebaseService.saveLastReadCfiLocation(
      lastReadCfiLocation: cfi,
      bookId: bookId,
    );
  }

  /// Get a list of books from the user's database
  Future<Either<Failure, List<Book>>> getBooks() async {
    return _firebaseService.getAllBooks();
  }

  Future<UploadTask?> uploadCoverImage({
    required String firebaseFilepath,
    required Uint8List bytes,
  }) async {
    return _firebaseService.uploadCoverPhoto(
      uploadToPath: firebaseFilepath,
      bytes: bytes,
    );
  }

  Future<void> uploadBookDocument(Book book) async {
    return _firebaseService.addBookToFirestore(book: book);
  }

  Future<UploadTask?> uploadBookData({
    required String userId,
    required Uint8List bytes,
    required String firebaseFilepath,
    required FileHash fileHash,
  }) async {
    return _firebaseService.uploadBookDataToFirebaseStorage(
      firebaseFilePath: firebaseFilepath,
      bytes: bytes,
      customMetadata: {
        StorageService.kFileHashKey: fileHash.toJson(),
      },
    );
  }

  Future<UploadTask?> uploadBookFile({
    required String userId,
    required String cacheFilepath,
    required String firebaseFilepath,
    required FileHash fileHash,
  }) async {
    return _firebaseService.uploadBookFileToFirebaseStorage(
      firebaseFilePath: firebaseFilepath,
      localFilePath: cacheFilepath,
      customMetadata: {
        StorageService.kFileHashKey: fileHash.toJson(),
      },
    );
  }

  Future<bool> fileHashExists(String md5, String sha1) async {
    return _firebaseService.fileHashExists(md5: md5, sha1: sha1);
  }

  /// Create a collection
  Future<Either<Failure, AppCollection>> addCollection(String name) async {
    // Create collection document
    return _firebaseService.addCollection(name);
  }

  /// Add a list of books to a collection
  ///
  /// Throws [AppException] if theres an exception
  Future<void> setItemsCollections({
    required List<Item> items,
    required List<String> collectionIds,
  }) async {
    try {
      for (final item in items) {
        if (item is Book) {
          unawaited(_firebaseService.updateBookCollections(
            bookId: item.id,
            collectionIds: collectionIds,
          ));
        } else if (item is Series) {
          unawaited(_firebaseService.updateSeriesCollections(
            seriesId: item.id,
            collectionIds: collectionIds,
          ));
        }
      }
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
  }

  Future<Series> mergeToSeries({
    String? name,
    // List of selected books including books in selected series
    required List<Book> selectedBooks,
    required List<Series> selectedSeries,
  }) async {
    try {
      // Get list of collections to put the new series in
      final Set<String> collectionIds = {};
      for (final book in selectedBooks) {
        collectionIds.addAll(book.collectionIds);
      }

      // Create a new series with the title with the first item in the list
      final newSeriesFuture = addSeries(
        name: name ?? selectedBooks.first.title,
        imageUrl: selectedBooks.first.imageUrl ?? kDefaultImage,
        collectionIds: collectionIds,
      );

      unawaited(newSeriesFuture.then((newSeries) {
        addBooksToSeries(
          books: selectedBooks,
          series: newSeries,
          collectionIds: collectionIds,
        );

        for (final series in selectedSeries) {
          unawaited(_firebaseService.deleteSeriesDocument(series.id));
        }
      }));

      return newSeriesFuture;
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
  }

  /// Add a list of books to a series
  ///
  /// Throws [AppException] if theres an exception
  Future<void> addBooksToSeries({
    required List<Book> books,
    required Series series,
    required Set<String> collectionIds,
  }) async {
    try {
      for (final book in books) {
        unawaited(_firebaseService.addBookToSeries(
          bookId: book.id,
          seriesId: series.id,
          collectionIds: collectionIds,
        ));
      }
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
  }

  /// Method to add series to firebase firestore, returns a [Series] object
  ///
  /// Throws [AppException] if it fails.
  Future<Series> addSeries({
    required String name,
    required String imageUrl,
    String description = '',
    Set<String>? collectionIds,
  }) async {
    try {
      return _firebaseService.addSeries(
        name,
        imageUrl: imageUrl,
        description: description,
        collectionIds: collectionIds,
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

  /// Add book to series
  ///
  /// Takes a book and adds the series id to it
  ///
  /// Throws [AppException] if it fails.
  Future<void> addSingleBookToSeries({
    required Book book,
    required Series series,
  }) async {
    final Set<String> collectionIds = series.collectionIds;
    collectionIds.addAll(book.collectionIds);

    try {
      unawaited(_firebaseService.addBookToSeries(
        bookId: book.id,
        seriesId: series.id,
        collectionIds: collectionIds,
      ));
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
  }

  Future<String> getFileDownloadUrl(String storagePath) async {
    return _firebaseService.getFileDownloadUrl(storagePath);
  }

  /// Download a file and copy it to documents
  ///
  /// Thorws `AppException` if it fails
  DownloadTask downloadFile(
      String firebaseStorageFilePath, String downloadToLocation) {
    try {
      return _firebaseService.downloadFile(
        firebaseFilePath: firebaseStorageFilePath,
        downloadToLocation: downloadToLocation,
      );
    } on AppException catch (_) {
      rethrow;
    } on Exception catch (e, st) {
      log.e(e.toString(), e, st);
      throw AppException(e.toString());
    }
  }

  /// Check if a file exists on the server
  ///
  /// Throws `AppException` if user is not logged in
  Future<bool> fileExists(String firebaseFilePath) async {
    return _firebaseService.fileExists(firebaseFilePath);
  }

  /// List the files the user has uploaded to their folder
  Future<List<String>> listFilenames() async {
    final String? userId = _firebaseService.currentUser?.uid;
    if (userId == null) {
      throw AppException('User not authenticated.');
    }
    return _firebaseService.listFilenames(userId);
  }

  /// Delete a library item permamently
  ///
  /// Arguments
  /// `items` - Items to be deleted
  List<Book> deleteItemsPermanently({
    required List<Item> itemsToDelete,
    required List<Book> allBooks,
  }) {
    final deletedBooks = <Book>[];
    for (final item in itemsToDelete) {
      if (item is Book) {
        // Delete the book document in firebase
        unawaited(_firebaseService.deleteBookDocument(item.id));
        // Delete the book files on firebase storage
        unawaited(_deleteFirebaseStorageBookFiles(item.filepath));
        deletedBooks.add(item);
      } else if (item is Series) {
        // Delete all books in the series
        final seriesItems = _getSeriesItems(item, allBooks);
        for (final itemInSeries in seriesItems) {
          unawaited(_firebaseService.deleteBookDocument(itemInSeries.id));
          deletedBooks.add(itemInSeries);
        }

        // Delete the series document in firebase
        unawaited(_firebaseService.deleteSeriesDocument(item.id));

        for (final itemInSeries in seriesItems) {
          unawaited(_deleteFirebaseStorageBookFiles(itemInSeries.filepath));
        }
      }
    }
    return deletedBooks;
  }

  List<Book> _getSeriesItems(Series series, List<Book> allBooks) {
    return allBooks.where((book) => book.seriesId == series.id).toList();
  }

  Future<void> _deleteFirebaseStorageBookFiles(String filepath) async {
    try {
      await _firebaseService.deleteFile(filepath);
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
    try {
      await _firebaseService
          .deleteFile(filepath + kFirebaseStorageImageExtension);
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }

  /// Unmerge a series
  ///
  /// This removes the series document and removes all references to it
  /// in the books that belong to it. Each book in the series should be
  /// assigned to the same collection as the series was
  ///
  /// `series` - The series to be unmerged
  /// `books` - The books that belong to the above series
  Future<void> unmergeSeries({
    required Series series,
    required List<Book> books,
  }) async {
    try {
      unawaited(_firebaseService.deleteSeriesDocument(series.id));
      for (final book in books) {
        unawaited(_firebaseService.updateBookSeries(book.id, null));
        unawaited(_firebaseService.updateBookCollections(
          bookId: book.id,
          collectionIds: series.collectionIds.toList(),
        ));
      }
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
  }

  /// Remove a collection
  Future<void> removeCollection({
    required AppCollection collection,
    required List<Item> collectionItems,
  }) async {
    try {
      for (final item in collectionItems) {
        //remove collection id. Dart implements remove function inplace
        final List<String> collectionIds = [
          ...item.collectionIds.toList()..remove(collection.id)
        ];
        if (item is Book) {
          await _firebaseService.updateBookCollections(
            bookId: item.id,
            collectionIds: collectionIds,
          );
        } else if (item is Series) {
          await _firebaseService.updateSeriesCollections(
            seriesId: item.id,
            collectionIds: collectionIds,
          );
        }
      }
      await _firebaseService.deleteCollectionDocument(collection.id);
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
