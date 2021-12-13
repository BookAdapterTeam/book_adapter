import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../features/library/data/book_item.dart';

@immutable
class UserData extends Equatable {
  const UserData({
    this.books,
  });

  // In the future, this would contain other data about Users, such as Collections, Series, etc
  final List<Book>? books;

  // The following was generated with VSCode extention "Dart Data Class Generator"
  UserData copyWith({
    List<Book>? books,
    List<String>? downloadedFiles,
  }) {
    return UserData(
      books: books ?? this.books,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [
        books ?? 'No books set',
      ];
}
