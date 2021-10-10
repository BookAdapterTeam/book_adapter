import 'dart:convert';

import 'package:equatable/equatable.dart';

class Shelf extends Equatable {
  final String name;
  final String userId;

  const Shelf({
    required this.name,
    required this.userId,
  });

  Shelf copyWith({
    String? name,
    String? userId,
  }) {
    return Shelf(
      name: name ?? this.name,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'userId': userId,
    };
  }

  factory Shelf.fromMap(Map<String, dynamic> map) {
    return Shelf(
      name: map['name'],
      userId: map['userId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Shelf.fromJson(String source) => Shelf.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [name, userId];
}
