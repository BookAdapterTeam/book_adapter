import 'dart:typed_data';

import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/series_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:epubx/epubx.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// A utility class to handle all Firebase calls
abstract class BaseFirebaseService {
  BaseFirebaseService();

  // Authentication

  /// Notifies about changes to the user's sign-in state (such as sign-in or
  /// sign-out).
  Stream<User?> get authStateChange;

  /// Returns the current [User] if they are currently signed-in, or `null` if
  /// not.
  ///
  /// You should not use this getter to determine the users current state,
  /// instead use [authStateChanges], [idTokenChanges] or [userChanges] to
  /// subscribe to updates.
  User? get currentUser;

  /// Notifies about changes to any user updates.
  ///
  /// This is a superset of both [authStateChanges] and [idTokenChanges]. It
  /// provides events on all user changes, such as when credentials are linked,
  /// unlinked and when updates to the user profile are made. The purpose of
  /// this Stream is for listening to realtime updates to the user state
  /// (signed-in, signed-out, different user & token refresh) without
  /// manually having to call [reload] and then rehydrating changes to your
  /// application.
  Stream<User?> get userChanges;

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
  /// Left [Failure] maybe returned with the following error code:
  /// - **invalid-email**:
  ///  - Returned if the email address is not valid.
  /// - **user-disabled**:
  ///  - Returned if the user corresponding to the given email has been disabled.
  /// - **user-not-found**:
  ///  - Returned if there is no user corresponding to the given email.
  /// - **wrong-password**:
  ///  - Returned if the password is invalid for the given email, or the account
  ///    corresponding to the email does not have a password set.
  Future<Either<Failure, UserCredential>> signIn({
    required String email,
    required String password,
  });

  /// Tries to create a new user account with the given email address and
  /// password.
  ///
  /// Returns an [Either]
  ///
  /// Right [UserCredential] is returned if successful
  ///
  /// Left [Failure] maybe returned with the following error code:
  /// - **email-already-in-use**:
  ///  - Returned if there already exists an account with the given email address.
  /// - **invalid-email**:
  ///  - Returned if the email address is not valid.
  /// - **operation-not-allowed**:
  ///  - Returned if email/password accounts are not enabled. Enable
  ///    email/password accounts in the Firebase Console, under the Auth tab.
  /// - **weak-password**:
  ///  - Returned if the password is not strong enough.
  Future<Either<Failure, UserCredential>> signUp({
    required String email,
    required String password,
  });

  /// Signs out the current user.
  ///
  /// If successful, it also update the stream [authStateChange]
  Future<void> signOut();

  /// Send reset password email
  Future<Either<Failure, void>> resetPassword(String email);

  /// Set display name
  ///
  /// Returns [true] if successful
  /// Returns [false] if the user is not authenticated
  Future<bool> setDisplayName(String name);

  /// Set profile photo
  ///
  /// Returns [true] if successful
  /// Returns [false] if the user is not authenticated
  Future<bool> setProfilePhoto(String photoURL);

  // Database

  Stream<QuerySnapshot<BookCollection>> get collectionsStream;
  Stream<QuerySnapshot<Book>> get booksStream;
  Stream<QuerySnapshot<Series>> get seriesStream;

  /// Get a list of books from the user's database
  Future<Either<Failure, List<Book>>> getBooks();

  /// Add a book to Firebase Database
  Future<Either<Failure, Book>> addBookToFirestore({required Book book});

  /// Create a shelf
  Future<Either<Failure, BookCollection>> addCollection(String name);

  /// Add book to collections
  ///
  /// Takes a book and adds the series id to it
  Future<void> setBookCollections({
    required String bookId,
    required Set<String> collectionIds,
  });

  /// Add series to collections
  ///
  /// Takes a series and adds the series id to it
  ///
  /// Throws [AppException] if it fails.
  Future<void> setSeriesCollections({
    required String seriesId,
    required Set<String> collectionIds,
  });

  /// Create a series
  Future<Series> addSeries(
    String name, {
    required String imageUrl,
    String description = '',
    Set<String>? collectionIds,
  });

  /// Add book to series
  Future<void> addBookToSeries({
    required String bookId,
    required String seriesId,
    required Set<String> collectionIds,
  });

  /// Remove series
  ///
  /// This invokes a firebase function to remove all references to the series.
  /// This does not delete the books.
  Future<void> removeSeries(String seriesId);

  /// Upload a book to Firebase Storage
  Future<Either<Failure, String>> uploadBookToFirebaseStorage({
    required String firebaseFilePath,
    required String localFilePath,
  });

  /// Upload a book cover photo to Firebase Storage
  Future<Either<Failure, String>> uploadCoverPhoto({
    required EpubBookRef openedBook,
    required String uploadToPath,
  });

  /// Upload bytes to Firebase Storage
  Future<Either<Failure, String>> uploadBytes({
    required String contentType,
    required String firebaseFilePath,
    required Uint8List bytes,
  });

  /// Upload a file to Firebase Storage
  Future<Either<Failure, String>> uploadFile(
      {required String contentType,
      required String firebaseFilePath,
      required String localFilePath});

  /// Download a file into memory
  DownloadTask downloadFile({
    required String firebaseFilePath,
    required String downloadToLocation,
  });

  Future<bool> fileExists(String filename);
}
