import 'package:book_adapter/data/app_exception.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/item.dart';
import 'package:book_adapter/features/library/data/series_item.dart';
import 'package:book_adapter/service/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:epubx/epubx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

/// Provider to easily get access to the user stream from [FirebaseService]
final authStateChangesProvider = StreamProvider.autoDispose<User?>((ref) async* {
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
final collectionsStreamProvider = StreamProvider.autoDispose<List<BookCollection>>((ref) async* {
  final firebaseController = ref.watch(firebaseControllerProvider);
  // Parse the value received and emit a Message instance
  try {
    await for (final value in firebaseController.collectionsStream) {
      yield value.docs.map((e) => e.data()).toList();
    }
  } on FirebaseException catch (_) {

  }
  
});

// Provide the stream with riverpod for easy access
final bookStreamProvider = StreamProvider.autoDispose<List<Book>>((ref) async* {
  final firebaseController = ref.watch(firebaseControllerProvider);
  // Parse the value received and emit a Message instance
  try {
    await for (final value in firebaseController.booksStream) {
      yield value.docs.map((e) => e.data()).toList();
    }
  } on FirebaseException catch (_) {

  }
});

// Provide the stream with riverpod for easy access
final seriesStreamProvider = StreamProvider.autoDispose<List<Series>>((ref) async* {
  final firebaseController = ref.watch(firebaseServiceProvider);
  // Parse the value received and emit a Message instance
  try {
    await for (final value in firebaseController.seriesStream) {
      yield value.docs.map((e) => e.data()).toList();
    }
  } on FirebaseException catch (_) {

  }
});

final firebaseControllerProvider = Provider.autoDispose<FirebaseController>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return FirebaseController(firebaseService);
});

class FirebaseController {
  FirebaseController(this._firebaseService);
  final FirebaseService _firebaseService;

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
  ///  - Returned if the user corresponding to the given email has been disabled.
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
  Future<Either<Failure, User>> signIn({required String email, required String password}) async {
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
    return res.fold(
      (failure) => Left(failure),
      (userCred) {
        final User? user = userCred.user;
        if (user == null) {
          return Left(Failure('Sign In Failed, User is NULL'));
        }
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
  ///  - Returned if there already exists an account with the given email address.
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
  Future<Either<Failure, User>> signUp({required String email, required String password, String? username}) async {
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
    return res.fold(
      (failure) => Left(failure),
      (userCred) {
        final User? user = userCred.user;
        if (user == null) {
          return Left(Failure('Sign Up Failed, User is NULL'));
        }

        // Set username
        if (username != null) {
          setDisplayName(username);
        }
        return Right(user);
      },
    );
  }

  /// Signs out the current user.
  ///
  /// If successful, it also update the stream [authStateChange]
  Future<void> signOut() async {
    return await _firebaseService.signOut();
  }

  /// Send reset password email
  Future<Either<Failure, void>> resetPassword(String email) async {
    return await _firebaseService.resetPassword(email);
  }

  /// Set display name
  /// 
  /// Returns [true] if successful
  /// Returns [false] if the user is not authenticated
  Future<bool> setDisplayName(String name) async {
    return await _firebaseService.setDisplayName(name);
  }

  /// Set profile photo
  /// 
  /// Returns [true] if successful
  /// Returns [false] if the user is not authenticated
  Future<bool> setProfilePhoto(String photoURL) async {
    return await _firebaseService.setProfilePhoto(photoURL);
  }

  // Database
  Stream<QuerySnapshot<Book>> get booksStream => _firebaseService.booksStream;
  Stream<QuerySnapshot<BookCollection>> get collectionsStream => _firebaseService.collectionsStream;
  Stream<QuerySnapshot<Series>> get seriesStream => _firebaseService.seriesStream;

  /// Get a list of books from the user's database
  Future<Either<Failure, List<Book>>> getBooks() async {
    return _firebaseService.getBooks();
  }

  /// Get a list of books from the user's database
  Future<Either<Failure, Book>> addBook(PlatformFile file) async {
    try {

      if (file.readStream == null) {
        return Left(Failure('File readStream was null'));
      }
      // Get the book stream into memory for upload
      final stream = http.ByteStream(file.readStream!);
      
      // Open book takes a future so it does not block the UI loading all the data
      final EpubBookRef openedBook = await EpubReader.openBook(stream.toBytes());

      final title = openedBook.Title ?? '';
      final authors = openedBook.AuthorList?.join(',') ?? '';

      // Upload cover image to storage
      final res = await _firebaseService.uploadCoverPhoto(file: file, openedBook: openedBook, title: title, authors: authors);
      final String? imageUrl = res.fold(
        (failure) {
          debugPrint('Could not upload cover photo');
          return;
        },
        (url) => url,
      );
      
      // Upload to Firestore
      final firestoreRes = await _firebaseService.addBookToFirestore(file, openedBook, imageUrl: imageUrl);
      if (firestoreRes.isLeft()) {
        return Left(firestoreRes.swap().getOrElse(() => Failure('Could not add book to Firestore')));
      }
      
      // Upload book to storage
      final uploadRes = await _firebaseService.uploadBookToFirebaseStorage(file, title: title, authors: authors);
      if (uploadRes.isLeft()) {
        return Left(uploadRes.swap().getOrElse(() => Failure('Could not add book to Firebase Storage')));
      }

      return firestoreRes;
    } on Exception catch (e) {
      return Left(Failure(e.toString()));
    }
  }


  /// Create a collection
  Future<Either<Failure, BookCollection>> addCollection(String name) async {
    // Upload book to storage
    return await _firebaseService.addCollection(name);
  }

  /// Add a list of books to a collection
  /// 
  /// Throws [AppException] if theres an exception
  Future<void> setItemsCollections({required List<Item> items, required Set<String> collectionIds}) async {
    try {
      for (final item in items) {
        if (item is Book) {
          await _firebaseService.setBookCollections(bookId: item.id, collectionIds: collectionIds);
        } else if (item is Series) {
          await _firebaseService.setSeriesCollections(seriesId: item.id, collectionIds: collectionIds );
        }
      }
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException (e.toString());
    }
  }
  

  /// Add a list of books to a series
  /// 
  /// Throws [AppException] if theres an exception
  Future<void> addBooksToSeries({required List<Book> books, required Series series, required Set<String> collectionIds}) async {
    try {
      //
      for (final book in books) {
        await _firebaseService.addBookToSeries(bookId: book.id, seriesId: series.id, collectionIds: collectionIds);
      }
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException (e.toString());
    }
  }

  /// Method to add series to firebase firestore, returns a [Series] object
  /// 
  /// Throws [AppException] if it fails.
  Future<Series> addSeries({required String name, required String imageUrl, String description = '', List<String>? collectionIds}) async {
    
    try {
      return await _firebaseService.addSeries(name, imageUrl: imageUrl, description: description);
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException (e.toString());
    }
  }

  /// Add book to series
  /// 
  /// Takes a book and adds the series id to it
  /// 
  /// Throws [AppException] if it fails.
  Future<void> addSingleBookToSeries({required Book book, required Series series}) async {
    final collectionIds = series.collectionIds;
    collectionIds.addAll(book.collectionIds);

    try {
      await _firebaseService.addBookToSeries(bookId: book.id, seriesId: series.id, collectionIds: collectionIds);
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException (e.toString());
    }
  }
}