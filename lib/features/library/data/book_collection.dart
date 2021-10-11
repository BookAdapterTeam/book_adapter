import 'dart:convert';

import 'package:equatable/equatable.dart';

class BookCollection extends Equatable {

  final String id;
  final String userId;
  final String name;

  const BookCollection({
    required this.id,
    required this.userId,
    required this.name,
  });

  BookCollection copyWith({
    String? id,
    String? userId,
    String? name,
  }) {
    return BookCollection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
    };
  }

  String toJson() => json.encode(toMap());

  factory BookCollection.fromMap(Map<String, dynamic> map) {
    return BookCollection(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
    );
  }

  factory BookCollection.fromJson(String source) => BookCollection.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [id, userId, name];
}
