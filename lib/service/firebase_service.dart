import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:book_adapter/data/app_exception.dart';
import 'package:book_adapter/data/failure.dart';
import 'package:book_adapter/features/library/data/book_collection.dart';
import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:book_adapter/features/library/data/series_item.dart';
import 'package:book_adapter/service/base_firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:epubx/epubx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

/// Provider to easily get access to the [FirebaseService] functions
final firebaseServiceProvider = Provider.autoDispose<FirebaseService>((ref) {
  return FirebaseService();
});

/// A utility class to handle all Firebase calls
class FirebaseService extends BaseFirebaseService {
  FirebaseService() : super();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  static const uuid = Uuid();

  // Authentication

  /// Notifies about changes to the user's sign-in state (such as sign-in or
  /// sign-out).
  @override
  Stream<User?> get authStateChange => _auth.authStateChanges();

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
  Stream<User?> get userChanges => _auth.userChanges();

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
  Future<Either<Failure, UserCredential>> signIn({
    required String email,
    required String password,
  }) async {
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
  Future<Either<Failure, UserCredential>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Return the data incase the caller needs it
      return Right(userCredential);
    } on FirebaseAuthException catch (e) {
      return Left(
          FirebaseFailure(e.message ?? 'Signup Not Successful', e.code));
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
  @override
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
      return Left(FirebaseFailure(
          e.message ?? 'Unknown Firebase Exception, Could Not Send Reset Email',
          e.code));
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
        .where('userId', isEqualTo: _auth.currentUser?.uid)
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
    return _booksRef
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .snapshots();
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
    return _seriesRef
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .snapshots();
  }

  // Books *****************************************************************************************************

  /// Get a list of books from the user's database
  @override
  Future<Either<Failure, List<Book>>> getBooks() async {
    try {
      final userId = _auth.currentUser?.uid;
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
  @override
  Future<Either<Failure, Book>> addBookToFirestore(
    PlatformFile file,
    EpubBookRef openedBook, {
    String collection = 'Default',
    String? imageUrl,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return Left(Failure('User not logged in'));
      }

      // Create a book object to add to the collection
      final title = openedBook.Title ?? '';
      final subtitle =
          openedBook.AuthorList?.join(', ') ?? openedBook.Author ?? '';
      final filename = file.name;
      final String id = uuid.v4();
      final book = Book(
        id: id,
        userId: userId,
        title: title,
        subtitle: subtitle,
        addedDate: DateTime.now().toUtc(),
        filename: filename,
        imageUrl: imageUrl,
        collectionIds: {'$userId-$collection'},
      );

      // Check books for duplicates, return Failure if any are found
      final duplicatesQuerySnapshot = await _booksRef
          .where('userId', isEqualTo: userId)
          .where('title', isEqualTo: title)
          .where('filename', isEqualTo: filename)
          .get();

      final duplicates = duplicatesQuerySnapshot.docs;

      if (duplicates.isNotEmpty) {
        return Left(Failure('Book has already been uploaded'));
      }

      // Add book to Firestore
      await _booksRef.doc(id).set(book);

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
  @override
  Future<Either<Failure, BookCollection>> addCollection(
    String collectionName,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
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
  @override
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
  @override
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
  @override
  Future<Series> addSeries(
    String name, {
    required String imageUrl,
    String description = '',
    Set<String>? collectionIds,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
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
  @override
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

  /// Remove series
  ///
  /// This invokes a firebase function to remove all references to the series.
  /// This does not delete the books.
  Future<void> removeSeries(String seriesId) {
    try {
      // TODO: Implement removeSeries cloud function
      throw UnimplementedError();
    } on FirebaseException catch (e) {
      throw AppException(e.message ?? e.toString(), e.code);
    } on Exception catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw AppException(e.toString());
    }
  }

  // Storage *****************************************************************************************

  /// Upload a book to Firebase Storage
  @override
  Future<Either<Failure, void>> uploadBookToFirebaseStorage(
    PlatformFile file, {
    required String title,
    required String authors,
  }) async {
    const String epubContentType = 'application/epub+zip';

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return Left(Failure('User not logged in'));
      }

      final filePath = file.path;
      if (filePath == null) {
        return Left(Failure('File path was null'));
      }

      final res = await uploadFile(
          userId: userId,
          file: file,
          contentType: epubContentType,
          title: title,
          authors: authors);

      return res;
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(
          e.message ?? 'Unknown Firebase Exception, Could Not Upload Book',
          e.code));
    } on Exception catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  /// Upload a book cover photo to Firebase Storage
  @override
  Future<Either<Failure, String>> uploadCoverPhoto({
    required PlatformFile file,
    required EpubBookRef openedBook,
    required String title,
    required String authors,
  }) async {
    const imageContentType = 'image/jpeg';
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return Left(Failure('User not logged in'));
      }

      final filePath = file.path;
      if (filePath == null) {
        return Left(Failure('File path was null'));
      }

      Image? image = await openedBook.readCover();

      if (image == null) {
        // No cover image, use the first image instead
        final imagesRef = openedBook.Content?.Images;

        if (imagesRef == null) {
          // images from epub is null
          return Left(Failure('Book has no images'));
        }

        // Use the first image that has a height greater than width to avoid using banners and copyright notices
        for (final imageRef in imagesRef.values) {
          final imageContent = await imageRef.readContent();
          final img.Image? cover = img.decodeImage(imageContent);
          if (cover != null && cover.height > cover.width) {
            image = cover;
            break;
          }
        }

        // If no applicable image found above, use the first image
        if (image == null) {
          final imageContent = await imagesRef.values.first.readContent();
          image = img.decodeImage(imageContent);
        }
      }

      if (image == null) {
        return Left(Failure('Could not get cover image for upload'));
      }

      final bytes = img.encodeJpg(image);
      final String filename = '${file.name}.jpg';

      final res = await uploadBytes(
          userId: userId,
          bytes: Uint8List.fromList(bytes),
          filename: filename,
          contentType: imageContentType,
          title: title,
          authors: authors);

      return res;
    } on FirebaseException catch (e) {
      return Left(FirebaseFailure(
          e.message ?? 'Unknown Firebase Exception, Could Not Upload Book',
          e.code));
    } on Exception catch (e) {
      return Left(Failure(e.toString()));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadBytes({
    required String userId,
    required Uint8List bytes,
    required String filename,
    required String contentType,
    required String title,
    required String authors,
  }) async {
    final path = '$userId/$title-$authors-$filename'.replaceAll('/', '');
    try {
      // Check if file exists, exit if it does
      await _firebaseStorage.ref(path).getDownloadURL();
      return Left(Failure('File already exists'));
    } on FirebaseException catch (_) {
      // File does not exist, continue uploading
      await _firebaseStorage.ref(path).putData(
            bytes,
            SettableMetadata(contentType: contentType),
          );
      final url = await _firebaseStorage.ref(path).getDownloadURL();
      return Right(url);
    }
  }

  /// Upload a file to FirebaseStorage
  ///
  /// Thorws `AppException` if it fails
  @override
  Future<Either<Failure, String>> uploadFile({
    required String userId,
    required PlatformFile file,
    required String contentType,
    required String title,
    required String authors,
  }) async {
    final path = '$userId/$title-$authors-${file.name}'.replaceAll('/', '');
    try {
      // Check if file exists, exit if it does
      await _firebaseStorage.ref(path).getDownloadURL();
      return Left(Failure('File already exists'));
    } on FirebaseException catch (_) {
      // File does not exist, continue uploading
      final filepath = file.path;
      if (filepath == null) return Left(Failure('file.path was null'));

      final UploadTask task = _firebaseStorage.ref(path).putFile(
            io.File(filepath),
            SettableMetadata(contentType: contentType),
          );

      // TODO: Somehow expose this to UI for upload progress
      /*final TaskSnapshot snapshot = */await task;

      final url = await _firebaseStorage.ref(path).getDownloadURL();
      return Right(url);
    }
  }

  /// Download a file to memory
  ///
  /// Thorws `AppException` if it fails
  @override
  DownloadTask downloadFile(String filename, String filePath) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw AppException('User not logged in');
    }

    final io.File downloadToFile = io.File(filePath);

    try {
      final fileRef = _firebaseStorage.ref('$userId/$filename');
      return fileRef.writeToFile(downloadToFile);
    } on FirebaseException catch (e, _) {
      throw AppException(e.message, e.code);
    }
  }
}
