import 'package:book_adapter/data/book_item.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/service/firebase_service.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final fakeFirebaseServiceProvider = Provider<MockFirebaseService>((ref) {
  return MockFirebaseService(firebaseAuth: MockFirebaseAuth());
});

class MockFirebaseService implements FirebaseService {
  MockFirebaseService({required this.firebaseAuth});
  final FirebaseAuth firebaseAuth;

  @override
  Stream<User?> get authStateChange => firebaseAuth.authStateChanges();

  // Mock get list of books
  @override
  Future<Either<Failure, List<BookItem>>> getBooks() async {
    try {
      const List<BookItem> books = [
        BookItem(name: 'Book 0', id: '0'),
        BookItem(name: 'Book 1', id: '1'),
        BookItem(name: 'Book 2', id: '2'),
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

  @override
  Future<Either<Failure, UserCredential>> signIn({required String email, required String password}) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      // Return the data incase the caller needs it
      return Right(userCredential);
    } on FirebaseAuthException catch (e) {
      return Left(FirebaseFailure(e.message ?? 'Login Unsuccessful', e.code));
    } on Exception catch (_) {
      return Left(Failure('Unexpected Exception, Could Not Login'));
    }
  }

  @override
  Future<void> signOut() async {
    firebaseAuth.signOut();
  }

  @override
  Future<Either<Failure, UserCredential>> signUp({required String email, required String password}) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
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

  /// Get the current user
  @override
  User? get currentUser => firebaseAuth.currentUser;

  /// Send reset password email
  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(e.message ?? 'Unknown Firebase Exception, Could Not Send Reset Email', e.code));
    } on Exception catch (_) {
      return Left(Failure('Unexpected Exception, Could Not Send Reset Email'));
    }
  }

  @override
  Future<bool> setDisplayName(String name) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      return false;
    }
    await user.updateDisplayName(name);
    return true;
  }

  @override
  Future<bool> setProfilePhoto(String photoURL) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      return false;
    }
    await user.updatePhotoURL(photoURL);
    return true;
  }

  @override
  // TODO: implement userChangesProvider
  StreamProvider<User?> get userChangesProvider => throw UnimplementedError();

  @override
  // TODO: implement userChanges
  Stream<User?> get userChanges => throw UnimplementedError();
}