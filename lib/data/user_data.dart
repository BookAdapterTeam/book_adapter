// ignore_for_file: sort_constructors_first
import 'package:book_adapter/data/book_item.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

@immutable
class UserData extends Equatable {
  const UserData({
    required this.currentUser,
    this.books = const [],
  });

  // In the future, this would contain other data about Users, such as Collections, Series, etc
  final User? currentUser;
  final List<Book> books;

  // The following was generated with VSCode extention "Dart Data Class Generator"
  UserData copyWith({
    User? currentUser,
    List<Book>? books,
  }) {
    return UserData(
      currentUser: currentUser ?? this.currentUser,
      books: books ?? this.books,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [currentUser.toString(), books];
}
