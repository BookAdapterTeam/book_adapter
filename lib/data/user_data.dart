import 'package:book_adapter/features/library/data/book_item.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
class UserData extends Equatable {
  const UserData({
    this.books = const [],
    this.downloadedFiles,
  });

  // In the future, this would contain other data about Users, such as Collections, Series, etc
  final List<Book>? books;
  final List<String>? downloadedFiles;

  // The following was generated with VSCode extention "Dart Data Class Generator"
  UserData copyWith({
    List<Book>? books,
    List<String>? downloadedFiles,
  }) {
    return UserData(
      books: books ?? this.books,
      downloadedFiles: downloadedFiles ?? this.downloadedFiles,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [books ?? 'No books set', downloadedFiles ?? 'No files set'];
}
