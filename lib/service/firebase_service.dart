import 'package:book_adapter/data/book_item.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/service/base_firebase_service.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider to easily get access to the [FirebaseService] functions
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

/// A utility class to handle all Firebase calls
class FirebaseService extends BaseFirebaseService {
  FirebaseService() : super(_firebaseAuth);

  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Authentication

  /// Notifies about changes to the user's sign-in state (such as sign-in or
  /// sign-out).
  @override
  Stream<User?> get authStateChange => _firebaseAuth.authStateChanges();

  /// Notifies about changes to any user updates.
  ///
  /// This is a superset of both [authStateChanges] and [idTokenChanges]. It
  /// provides events on all user changes, such as when credentials are linked,
  /// unlinked and when updates to the user profile are made. The purpose of
  /// this Stream is for listening to realtime updates to the user state
  /// (signed-in, signed-out, different user & token refresh) without
  /// manually having to call [reload] and then rehydrating changes to your
  /// application.
  @override
  Stream<User?> get userChanges => _firebaseAuth.userChanges();

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
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
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
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
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
    await _firebaseAuth.signOut();
  }

  /// Returns the current [User] if they are currently signed-in, or `null` if
  /// not.
  ///
  /// You should not use this getter to determine the users current state,
  /// instead use [authStateChanges], [idTokenChanges] or [userChanges] to
  /// subscribe to updates.
  @override
  User? get currentUser {
    return _firebaseAuth.currentUser;
  }

  // Database
  /// WIP
  /// 
  /// Get a list of books from the user's database
  @override
  Future<Either<Failure, List<BookItem>>> getBooks() async {
    try {
      // TODO: Implement Firebase call to database to get the list of user books
      await Future.delayed(const Duration(seconds: 1));
      const List<BookItem> books = [
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

  /// Send reset password email
  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
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
    final user = _firebaseAuth.currentUser;
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
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return false;
    }
    await user.updatePhotoURL(photoURL);
    return true;
  }
}