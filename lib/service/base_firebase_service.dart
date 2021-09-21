import 'package:book_adapter/data/book_item.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A utility class to handle all Firebase calls
abstract class BaseFirebaseService {
  BaseFirebaseService(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  // Authentication

  /// Notifies about changes to the user's sign-in state (such as sign-in or
  /// sign-out).
  Stream<User?> get authStateChange => _firebaseAuth.authStateChanges();

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
  Future<Either<Failure, UserCredential>> signIn({required String email, required String password});

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
  Future<Either<Failure, UserCredential>> signUp({required String email, required String password});

  /// Signs out the current user.
  ///
  /// If successful, it also update the stream [authStateChange]
  Future<void> signOut();

  // Database
  /// WIP
  /// 
  /// Get a list of books from the user's database
  Future<Either<Failure, List<BookItem>>> getBooks();

}