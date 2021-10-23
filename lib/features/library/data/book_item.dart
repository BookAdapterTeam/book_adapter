import 'dart:convert';

import 'package:book_adapter/features/reader/book_reader_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'item.dart';

/// A placeholder class that represents a book.
class Book implements Item {
  @override
  final String id;
  @override
  final String userId;
  @override
  final String title;
  @override
  final String? subtitle;
  @override
  final String? imageUrl;
  @override
  final Set<String> collectionIds;
  final DateTime addedDate;
  final String description;
  final String filepath;
  final String genre;
  final String language;
  final DateTime? lastRead;
  final String publisher;
  final int? readingProgress;
  final int? wordCount;
  final String? seriesId;

  bool get hasSeries => seriesId != null;

  String get filename => filepath.split('/').last;

  String get filetype => filepath.split('.').last;

  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.addedDate,
    this.subtitle = '',
    this.description = '',
    required this.filepath,
    this.imageUrl,
    this.genre = '',
    this.language = '',
    this.lastRead,
    this.publisher = '',
    this.readingProgress,
    this.wordCount,
    required this.collectionIds,
    this.seriesId,
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
    String? imageUrl,
    String? genre,
    String? language,
    DateTime? lastRead,
    String? publisher,
    int? readingProgress,
    int? wordCount,
    Set<String>? collectionIds,
    String? seriesId,
  }) {
    return Book(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      addedDate: addedDate ?? this.addedDate,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      filepath: filepath ?? this.filepath,
      imageUrl: imageUrl ?? this.imageUrl,
      genre: genre ?? this.genre,
      language: language ?? this.language,
      lastRead: lastRead ?? this.lastRead,
      publisher: publisher ?? this.publisher,
      readingProgress: readingProgress ?? this.readingProgress,
      wordCount: wordCount ?? this.wordCount,
      collectionIds: collectionIds ?? this.collectionIds,
      seriesId: seriesId ?? this.seriesId,
    );
  }

  @override
  Map<String, dynamic> toMapSerializable() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'addedDate': addedDate.millisecondsSinceEpoch,
      'authors': subtitle,
      'description': description,
      'filepath': filepath,
      'imageUrl': imageUrl,
      'genre': genre,
      'language': language,
      'lastRead': lastRead?.millisecondsSinceEpoch,
      'publisher': publisher,
      'readingProgress': readingProgress,
      'wordCount': wordCount,
      'collectionIds': collectionIds.toList(),
      'seriesId': seriesId,
    };
  }

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
      imageUrl: map['imageUrl'],
      genre: map['genre'],
      language: map['language'],
      lastRead: lastRead != null
          ? DateTime.fromMillisecondsSinceEpoch(lastRead)
          : null,
      publisher: map['publisher'],
      readingProgress: map['readingProgress'],
      wordCount: map['wordCount'],
      collectionIds: Set<String>.from(map['collectionIds']),
      seriesId: map['seriesId'],
    );
  }

  @override
  Map<String, dynamic> toMapFirebase() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'addedDate': Timestamp.fromDate(addedDate),
      'authors': subtitle,
      'description': description,
      'filepath': filepath,
      'imageUrl': imageUrl,
      'genre': genre,
      'language': language,
      'lastRead': lastRead != null ? Timestamp.fromDate(lastRead!) : null,
      'publisher': publisher,
      'readingProgress': readingProgress,
      'wordCount': wordCount,
      'collectionIds': collectionIds.toList(),
      'seriesId': seriesId,
    };
  }

  factory Book.fromMapFirebase(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      addedDate: map['addedDate'].toDate(),
      subtitle: map['authors'],
      description: map['description'],
      filepath: map['filepath'],
      imageUrl: map['imageUrl'],
      genre: map['genre'],
      language: map['language'],
      lastRead: map['lastRead']?.toDate(),
      publisher: map['publisher'],
      readingProgress: map['readingProgress'],
      wordCount: map['wordCount'],
      collectionIds: List<String>.from(map['collectionIds']).toSet(),
      seriesId: map['seriesId'],
    );
  }

  @override
  String toJsonFirebase() => json.encode(toMapFirebase());

  factory Book.fromJsonFirebase(String source) =>
      Book.fromMapFirebase(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [
      id,
      userId,
      title,
      addedDate,
      subtitle ?? 'No subtitle',
      description,
      filepath,
      imageUrl ?? 'No image',
      genre,
      language,
      lastRead ?? 'Not read yet',
      publisher,
      readingProgress ?? 'Not started reading',
      wordCount ?? 'Unknown word count',
      collectionIds,
    ];
  }
}
