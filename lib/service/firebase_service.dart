import 'dart:io' as io;
import 'dart:typed_data';

import 'package:book_adapter/data/book_item.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/features/library/data/shelf.dart';
import 'package:book_adapter/service/base_firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:epubx/epubx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Provider to easily get access to the [FirebaseService] functions
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

/// A utility class to handle all Firebase calls
class FirebaseService extends BaseFirebaseService {
  FirebaseService() : super(_auth);

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const uuid = Uuid();

  // Authentication

  /// Notifies about changes to the user's sign-in state (such as sign-in or
  /// sign-out).
  @override
  Stream<User?> get authStateChange => _auth.authStateChanges();

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
  /// Left [Failure] returned for any other exception
  @override
  Future<Either<Failure, UserCredential>> signIn({required String email, required String password}) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Return the data incase the caller needs it
      return Right(userCredential);
    } on FirebaseAuthException catch (e) {
      return Left(FirebaseFailure(e.message ?? 'Login Unsuccessful', e.code));
    } on Exception catch (_) {
      return Left(Failure('Unexpected Exception, Could Not Login'));
    }
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
  /// Left [Failure] returned for any other exception
  @override
  Future<Either<Failure, UserCredential>> signUp({required String email, required String password}) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Return the data incase the caller needs it
      return Right(userCredential);
    } on FirebaseAuthException catch (e) {
      return Left(FirebaseFailure(e.message ?? 'Signup Not Successful', e.code));
    } on Exception catch (_) {
      return Left(Failure('Unexpected Exception, Could Not SignUp'));
    }
  }

  /// Signs out the current user.
  ///
  /// If successful, it also update the stream [authStateChange]
  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Returns the current [User] if they are currently signed-in, or `null` if
  /// not.
  ///
  /// You should not use this getter to determine the users current state,
  /// instead use [authStateChanges], [idTokenChanges] or [userChanges] to
  /// subscribe to updates.
  User? get currentUser {
    return _auth.currentUser;
  }

  /// Send reset password email
  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(e.message ?? 'Unknown Firebase Exception, Could Not Send Reset Email', e.code));
    } on Exception catch (_) {
      return Left(Failure('Unexpected Exception, Could Not Send Reset Email'));
    }
  }

  /// Set display name
  /// 
  /// Returns [true] if successful
  /// Returns [false] if the user is not authenticated
  @override
  Future<bool> setDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    await user.updateDisplayName(name);
    return true;
  }

  /// Set profile photo
  /// 
  /// Returns [true] if successful
  /// Returns [false] if the user is not authenticated
  @override
  Future<bool> setProfilePhoto(String photoURL) async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    await user.updatePhotoURL(photoURL);
    return true;
  }

  // Database

  /// WIP
  /// 
  /// Get a list of books from the user's database
  @override
  Future<Either<Failure, List<Book>>> getBooks() async {
    try {
      // TODO: Implement Firebase call to database to get the list of user books
      await Future.delayed(const Duration(seconds: 1));
      const List<Book> books = [
        // BookItem(name: 'Book 0', id: '0'),
        // BookItem(name: 'Book 1', id: '1'),
        // BookItem(name: 'Book 2', id: '2'),
      ];
      
      // Return our books to the caller in case they care
      // ignore: prefer_const_constructors
      return Right(books);
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(e.message ?? 'Unknown Firebase Exception, Could Not Refresh Books', e.code));
    } on Exception catch (_) {
      return Left(Failure('Unexpected Exception, Could Not Refresh Books'));
    }
  }

  /// Add a book to Firebase Firestore
  @override
  Future<Either<Failure, Book>> addBook(PlatformFile file, Uint8List bytes, {String collection = 'Default'}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return Left(Failure('User not logged in'));
      }

      final CollectionReference<Book> defaultShelf = _firestore.collection('shelves/$userId-$collection/books').withConverter<Book>(
        fromFirestore: (snapshot, _) => Book.fromMap(snapshot.data()!),
        toFirestore: (book, _) => book.toMap(),
      );

      final openedBook = await EpubReader.openBook(bytes);
      final book = Book(
        title: openedBook.Title ?? '',
        authors: openedBook.AuthorList?.join(',') ?? '',
        id: file.name,
        addedDate: DateTime.now().toUtc(),
        filename: file.name,
      );
      await defaultShelf.doc(uuid.v4()).set(book);
      
      // Return our books to the caller in case they care
      // ignore: prefer_const_constructors
      return Right(book);
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(e.message ?? 'Unknown Firebase Exception, Could Not Upload Book', e.code));
    } on Exception catch (_) {
      return Left(Failure('Unexpected Exception, Could Not Upload Book'));
    }
  }

  /// Upload a book to Firebase Storage
  @override
  Future<Either<Failure, void>> uploadBook(PlatformFile file, Uint8List bytes) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return Left(Failure('User not logged in'));
      }

      final filePath = file.path;
      if (filePath == null) {
        return Left(Failure('File path was null'));
      }

      // Upload book file
      await _storage.ref('$userId/${file.name}').putFile(io.File(filePath));
      
      // Return our books to the caller in case they care
      // ignore: prefer_const_constructors
      return Right(null);
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(e.message ?? 'Unknown Firebase Exception, Could Not Upload Book', e.code));
    } on Exception catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Create a shelf in firestore
  @override
  Future<Either<Failure, Shelf>> addShelf(String name) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return Left(Failure('User not logged in'));
      }

      final CollectionReference<Shelf> shelvesRef = _firestore.collection('shelves').withConverter<Shelf>(
        fromFirestore: (snapshot, _) => Shelf.fromMap(snapshot.data()!),
        toFirestore: (shelf, _) => shelf.toMap(),
      );

      final shelf = Shelf(name: '$userId-$name', userId: userId);
      shelvesRef.add(shelf);
      
      // Return the shelf to the caller in case they care
      return Right(shelf);
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(e.message ?? e.toString(), e.code));
    } on Exception catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}