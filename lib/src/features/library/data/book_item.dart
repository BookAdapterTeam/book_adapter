import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/data/file_hash.dart';
import '../../reader/book_reader_view.dart';
import 'item.dart';

/// A placeholder class that represents a book.
class Book extends Item {
  final DateTime addedDate;
  final String description;
  final String filepath;
  final int filesize;
  final String genre;
  final String language;
  final DateTime? lastRead;
  final String publisher;
  final int? readingProgress;
  final int? wordCount;
  final String? seriesId;
  final String? lastReadCfiLocation;
  final bool finished;
  final FileHash? fileHash;

  bool get hasSeries => seriesId != null;

  String get filename => filepath.split('/').last;

  String get filetype => filepath.split('.').last;

  const Book({
    required super.id,
    required super.userId,
    required super.title,
    required this.addedDate,
    super.subtitle = '',
    this.description = '',
    required this.filepath,
    required this.filesize,
    super.imageUrl,
    super.firebaseCoverImagePath,
    this.genre = '',
    this.language = '',
    this.lastRead,
    this.publisher = '',
    this.readingProgress,
    this.wordCount,
    required super.collectionIds,
    this.seriesId,
    this.lastReadCfiLocation,
    this.finished = false,
    this.fileHash,
  });

  @override
  String get routeTo => BookReaderView.routeName;

  @override
  Book copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? addedDate,
    String? subtitle,
    String? description,
    String? filepath,
    int? filesize,
    String? imageUrl,
    String? firebaseCoverImagePath,
    String? genre,
    String? language,
    DateTime? lastRead,
    String? publisher,
    int? readingProgress,
    int? wordCount,
    Set<String>? collectionIds,
    String? seriesId,
    String? lastReadCfiLocation,
    bool? finished,
    FileHash? fileHash,
  }) =>
      Book(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        addedDate: addedDate ?? this.addedDate,
        subtitle: subtitle ?? this.subtitle,
        description: description ?? this.description,
        filepath: filepath ?? this.filepath,
        filesize: filesize ?? this.filesize,
        imageUrl: imageUrl ?? this.imageUrl,
        firebaseCoverImagePath: firebaseCoverImagePath ?? this.firebaseCoverImagePath,
        genre: genre ?? this.genre,
        language: language ?? this.language,
        lastRead: lastRead ?? this.lastRead,
        publisher: publisher ?? this.publisher,
        readingProgress: readingProgress ?? this.readingProgress,
        wordCount: wordCount ?? this.wordCount,
        collectionIds: collectionIds ?? this.collectionIds,
        seriesId: seriesId ?? this.seriesId,
        lastReadCfiLocation: lastReadCfiLocation ?? this.lastReadCfiLocation,
        finished: finished ?? this.finished,
        fileHash: fileHash ?? this.fileHash,
      );

  @override
  Map<String, dynamic> toMapSerializable() => {
        'id': id,
        'userId': userId,
        'title': title,
        'addedDate': addedDate.millisecondsSinceEpoch,
        'authors': subtitle,
        'description': description,
        'filepath': filepath,
        'filesize': filesize,
        'imageUrl': imageUrl,
        'firebaseCoverImagePath': firebaseCoverImagePath,
        'genre': genre,
        'language': language,
        'lastRead': lastRead?.millisecondsSinceEpoch,
        'publisher': publisher,
        'readingProgress': readingProgress,
        'wordCount': wordCount,
        'collectionIds': collectionIds.toList(),
        'seriesId': seriesId,
        'lastReadCfiLocation': lastReadCfiLocation,
        'finished': finished,
        'fileHash': fileHash,
      };

  factory Book.fromMapSerializable(Map<String, dynamic> map) {
    final lastRead = map['lastRead'];
    return Book(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      addedDate: DateTime.fromMillisecondsSinceEpoch(map['addedDate']),
      subtitle: map['authors'],
      description: map['description'],
      filepath: map['filepath'],
      filesize: map['filesize'],
      imageUrl: map['imageUrl'],
      firebaseCoverImagePath: map['firebaseCoverImagePath'],
      genre: map['genre'],
      language: map['language'],
      lastRead: lastRead != null ? DateTime.fromMillisecondsSinceEpoch(lastRead) : null,
      publisher: map['publisher'],
      readingProgress: map['readingProgress'],
      wordCount: map['wordCount'],
      collectionIds: Set<String>.from(map['collectionIds']),
      seriesId: map['seriesId'],
      lastReadCfiLocation: map['lastReadCfiLocation'],
      finished: map['finished'] ?? false,
      fileHash: FileHash.fromMap(map['fileHash']),
    );
  }

  @override
  Map<String, dynamic> toMapFirebase() => {
        'id': id,
        'userId': userId,
        'title': title,
        'addedDate': Timestamp.fromDate(addedDate),
        'authors': subtitle,
        'description': description,
        'filepath': filepath,
        'filesize': filesize,
        'imageUrl': imageUrl,
        'firebaseCoverImagePath': firebaseCoverImagePath,
        'genre': genre,
        'language': language,
        'lastRead': lastRead != null ? Timestamp.fromDate(lastRead!) : null,
        'publisher': publisher,
        'readingProgress': readingProgress,
        'wordCount': wordCount,
        'collectionIds': collectionIds.toList(),
        'seriesId': seriesId,
        'lastReadCfiLocation': lastReadCfiLocation,
        'finished': finished,
        'fileHash': fileHash?.toMap(),
      };

  factory Book.fromMapFirebase(Map<String, dynamic> map) => Book(
        id: map['id'],
        userId: map['userId'],
        title: map['title'],
        addedDate: map['addedDate']?.toDate(),
        subtitle: map['authors'],
        description: map['description'],
        filepath: map['filepath'],
        filesize: map['filesize'],
        imageUrl: map['imageUrl'],
        firebaseCoverImagePath: map['firebaseCoverImagePath'],
        genre: map['genre'],
        language: map['language'],
        lastRead: map['lastRead']?.toDate(),
        publisher: map['publisher'],
        readingProgress: map['readingProgress'],
        wordCount: map['wordCount'],
        collectionIds: List<String>.from(map['collectionIds']).toSet(),
        seriesId: map['seriesId'],
        lastReadCfiLocation: map['lastReadCfiLocation'],
        finished: map['finished'] ?? false,
        fileHash: map['fileHash'] == null ? null : FileHash.fromMap(map['fileHash']),
      );

  @override
  String toJsonFirebase() => json.encode(toMapFirebase());

  factory Book.fromJsonFirebase(String source) => Book.fromMapFirebase(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [
        id,
        userId,
        title,
        addedDate,
        subtitle ?? 'No subtitle',
        description,
        filepath,
        filesize,
        imageUrl ?? 'No image',
        genre,
        language,
        lastRead ?? 'Not read yet',
        publisher,
        readingProgress ?? 'Not started reading',
        wordCount ?? 'Unknown word count',
        collectionIds,
        lastReadCfiLocation ?? 'No last read CFI location',
        finished,
        fileHash ?? 'No FileHash',
      ];
}
