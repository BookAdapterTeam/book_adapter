// ignore_for_file: sort_constructors_first
import 'dart:convert';

import 'package:book_adapter/features/library/book_item.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

@immutable
class UserData extends Equatable {
  const UserData({
    required this.books,
  });

  // In the future, this would contain other data about Users, such as Collections, Series, etc
  final List<BookItem> books;

  // The following was generated with VSCode extention "Dart Data Class Generator"
  UserData copyWith({
    List<BookItem>? books,
  }) {
    return UserData(
      books: books ?? this.books,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'books': books.map((x) => x.toMap()).toList(),
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      books: List<BookItem>.from((map['books'] as List<Map<String, dynamic>>).map((bookMap) => BookItem.fromMap(bookMap))),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserData.fromJson(String source) => UserData.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [books];
}
