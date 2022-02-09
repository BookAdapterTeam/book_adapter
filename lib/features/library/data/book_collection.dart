import 'dart:convert';

import 'package:equatable/equatable.dart';

class AppCollection extends Equatable {
  final String id;
  final String userId;
  final String name;

  const AppCollection({
    required this.id,
    required this.userId,
    required this.name,
  });

  AppCollection copyWith({
    String? id,
    String? userId,
    String? name,
  }) {
    return AppCollection(
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

  factory AppCollection.fromMap(Map<String, dynamic> map) {
    return AppCollection(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
    );
  }

  factory AppCollection.fromJson(String source) =>
      AppCollection.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [id, userId, name];
}
