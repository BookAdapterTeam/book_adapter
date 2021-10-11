import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'item.dart';

/// A placeholder class that represents a book.
class Book extends Item {
  final String title;
  final DateTime addedDate;
  final String authors;
  final String description;
  final String filename;
  final String? imageUrl;
  final String genre;
  final String language;
  final DateTime? lastRead;
  final String publisher;
  final int? readingProgress;
  final int? wordCount;

  const Book({
    required id,
    required userId,
    required this.title,
    required this.addedDate,
    this.authors = '',
    this.description = '',
    required this.filename,
    this.imageUrl,
    this.genre = '',
    this.language = '',
    this.lastRead,
    this.publisher = '',
    this.readingProgress,
    this.wordCount,
  }) : super(id: id, userId: userId);

  @override
  Book copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? addedDate,
    String? authors,
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
      authors: authors ?? this.authors,
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

  Map<String, dynamic> toMapSerializable() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'addedDate': addedDate.millisecondsSinceEpoch,
      'authors': authors,
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
      authors: map['authors'],
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
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'addedDate': Timestamp.fromDate(addedDate),
      'authors': authors,
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
      authors: map['authors'],
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
  String toJson() => json.encode(toMap());

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
      authors,
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