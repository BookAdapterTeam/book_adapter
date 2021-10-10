import 'dart:convert';

import 'package:equatable/equatable.dart';

/// A placeholder class that represents a book.
class Book extends Equatable {
  final String id;
  final String title;
  final DateTime addedDate;
  final String authors;
  final String description;
  final String filename;
  final String genre;
  final String language;
  final DateTime? lastRead;
  final String publisher;
  final int? readingProgress;
  final int? wordCount;

  const Book({
    required this.id,
    required this.title,
    required this.addedDate,
    this.authors = '',
    this.description = '',
    required this.filename,
    this.genre = '',
    this.language = '',
    this.lastRead,
    this.publisher = '',
    this.readingProgress,
    this.wordCount,
  });

  Book copyWith({
    String? title,
    String? id,
    DateTime? addedDate,
    String? authors,
    String? description,
    String? filename,
    String? genre,
    String? language,
    DateTime? lastRead,
    String? publisher,
    int? readingProgress,
    int? wordCount,
  }) {
    return Book(
      title: title ?? this.title,
      id: id ?? this.id,
      addedDate: addedDate ?? this.addedDate,
      authors: authors ?? this.authors,
      description: description ?? this.description,
      filename: filename ?? this.filename,
      genre: genre ?? this.genre,
      language: language ?? this.language,
      lastRead: lastRead ?? this.lastRead,
      publisher: publisher ?? this.publisher,
      readingProgress: readingProgress ?? this.readingProgress,
      wordCount: wordCount ?? this.wordCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'id': id,
      'addedDate': addedDate.millisecondsSinceEpoch,
      'authors': authors,
      'description': description,
      'filename': filename,
      'genre': genre,
      'language': language,
      'lastRead': lastRead?.millisecondsSinceEpoch,
      'publisher': publisher,
      'readingProgress': readingProgress,
      'wordCount': wordCount,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      title: map['title'],
      id: map['id'],
      addedDate: DateTime.fromMillisecondsSinceEpoch(map['addedDate']),
      authors: map['authors'],
      description: map['description'],
      filename: map['filename'],
      genre: map['genre'],
      language: map['language'],
      lastRead: DateTime.fromMillisecondsSinceEpoch(map['lastRead']),
      publisher: map['publisher'],
      readingProgress: map['readingProgress'],
      wordCount: map['wordCount'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Book.fromJson(String source) => Book.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [
      id,
      title,
      addedDate,
      authors,
      description,
      filename,
      genre,
      language,
      lastRead ?? 'Not read yet',
      publisher,
      readingProgress ?? 'Not started reading',
      wordCount ?? 'Unknown word count',
    ];
  }
}
