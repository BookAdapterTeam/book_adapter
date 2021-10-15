import 'dart:typed_data';

import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/series_item.dart';
import 'package:book_adapter/service/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:epubx/epubx.dart';
import 'package:file_picker/src/platform_file.dart';
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
  Future<Either<Failure, List<Book>>> getBooks() async {
    try {
      const List<Book> books = [
        // Book(title: 'Book 0', id: '0'),
        // Book(title: 'Book 1', id: '1'),
        // Book(title: 'Book 2', id: '2'),
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
    await firebaseAuth.signOut();
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
  Future<Either<Failure, Book>> addBook(PlatformFile file, EpubBookRef openedBook, {String collection = 'Default', String? imageUrl}) {
    // TODO: implement addBook
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, BookCollection>> addCollection(String shelfName) {
    // TODO: implement addShelf
    throw UnimplementedError();
  }

  @override
  // TODO: implement bookStreamProvider
  StreamProvider<List<Book>> get bookStreamProvider => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> uploadBookToFirebaseStorage(PlatformFile file, Uint8List bytes) {
    // TODO: implement uploadBook
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, String>> uploadCoverPhoto(PlatformFile file, EpubBookRef openBook) {
    // TODO: implement uploadCoverPhoto
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, String>> uploadFile(String userId, Uint8List bytes, String filename, String contentType) {
    // TODO: implement uploadFile
    throw UnimplementedError();
  }

  @override
  // TODO: implement userChanges
  Stream<User?> get userChanges => throw UnimplementedError();

  @override
  // TODO: implement collectionsStreamProvider
  StreamProvider<List<BookCollection>> get collectionsStreamProvider => throw UnimplementedError();

  @override
  Future<Series> addSeries(String name, {String description = '', Set<String>? collectionIds}) {
    // TODO: implement addSeries
    throw UnimplementedError();
  }

  @override
  // TODO: implement seriesStreamProvider
  StreamProvider<List<Series>> get seriesStreamProvider => throw UnimplementedError();

  @override
  Future<void> addBookToSeries({required String bookId, required String seriesId, required Set<String> collectionIds}) {
    // TODO: implement addBookToSeries
    throw UnimplementedError();
  }

  @override
  Future<void> setBookCollection({required String bookId, required Set<String> collectionIds}) {
    // TODO: implement setBookCollection
    throw UnimplementedError();
  }

}