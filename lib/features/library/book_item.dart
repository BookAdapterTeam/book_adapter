import 'dart:convert';

import 'package:equatable/equatable.dart';

/// A placeholder class that represents a book.
class BookItem extends Equatable {
  final String name;
  final String id;

  const BookItem({
    required this.name,
    required this.id,
  });

  // The following was generated with VSCode extention "Dart Data Class Generator"
  BookItem copyWith({
    String? name,
    String? id,
  }) {
    return BookItem(
      name: name ?? this.name,
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'id': id,
    };
  }

  factory BookItem.fromMap(Map<String, dynamic> map) {
    return BookItem(
      name: map['name'],
      id: map['id'],
    );
  }

  String toJson() => json.encode(toMap());

  factory BookItem.fromJson(String source) => BookItem.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [name, id];
}
