import 'dart:convert';

import 'package:book_adapter/features/reader/book_reader_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'item.dart';

/// A placeholder class that represents a book.
class Book extends Item {
  final DateTime addedDate;
  final String description;
  final String filename;
  final String genre;
  final String language;
  final DateTime? lastRead;
  final String publisher;
  final int? readingProgress;
  final int? wordCount;

  const Book({
    required String id,
    required String userId,
    required String title,
    required this.addedDate,
    String? subtitle = '',
    this.description = '',
    required this.filename,
    String? imageUrl,
    this.genre = '',
    this.language = '',
    this.lastRead,
    this.publisher = '',
    this.readingProgress,
    this.wordCount,
  }) : super(id: id, userId: userId, title: title, imageUrl: imageUrl);

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
    String? filename,
    String? imageUrl,
    String? genre,
    String? language,
    DateTime? lastRead,
    String? publisher,
    int? readingProgress,
    int? wordCount,
  }) {
    return Book(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      addedDate: addedDate ?? this.addedDate,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      filename: filename ?? this.filename,
      imageUrl: imageUrl ?? this.imageUrl,
      genre: genre ?? this.genre,
      language: language ?? this.language,
      lastRead: lastRead ?? this.lastRead,
      publisher: publisher ?? this.publisher,
      readingProgress: readingProgress ?? this.readingProgress,
      wordCount: wordCount ?? this.wordCount,
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
      'filename': filename,
      'imageUrl': imageUrl,
      'genre': genre,
      'language': language,
      'lastRead': lastRead?.millisecondsSinceEpoch,
      'publisher': publisher,
      'readingProgress': readingProgress,
      'wordCount': wordCount,
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
      filename: map['filename'],
      imageUrl: map['imageUrl'],
      genre: map['genre'],
      language: map['language'],
      lastRead: lastRead != null ? DateTime.fromMillisecondsSinceEpoch(lastRead) : null,
      publisher: map['publisher'],
      readingProgress: map['readingProgress'],
      wordCount: map['wordCount'],
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
      'filename': filename,
      'imageUrl': imageUrl,
      'genre': genre,
      'language': language,
      'lastRead': lastRead != null ? Timestamp.fromDate(lastRead!) : null,
      'publisher': publisher,
      'readingProgress': readingProgress,
      'wordCount': wordCount,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      addedDate: map['addedDate'].toDate(),
      subtitle: map['authors'],
      description: map['description'],
      filename: map['filename'],
      imageUrl: map['imageUrl'],
      genre: map['genre'],
      language: map['language'],
      lastRead: map['lastRead']?.toDate(),
      publisher: map['publisher'],
      readingProgress: map['readingProgress'],
      wordCount: map['wordCount'],
    );
  }

  @override
  String toJsonFirebase() => json.encode(toMapFirebase());

  factory Book.fromJson(String source) => Book.fromMap(json.decode(source));

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
      filename,
      imageUrl ?? 'No image',
      genre,
      language,
      lastRead ?? 'Not read yet',
      publisher,
      readingProgress ?? 'Not started reading',
      wordCount ?? 'Unknown word count',
    ];
  }
}
