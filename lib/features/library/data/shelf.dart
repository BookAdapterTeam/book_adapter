import 'dart:convert';

import 'item.dart';

class Shelf extends Item {
  final String name;

  const Shelf({
    required id,
    required userId,
    required this.name,
  }) : super(id: id, userId: userId);

  @override
  Shelf copyWith({
    String? id,
    String? userId,
    String? name,
  }) {
    return Shelf(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
    };
  }

  factory Shelf.fromMap(Map<String, dynamic> map) {
    return Shelf(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
    );
  }

  @override
  String toJson() => json.encode(toMap());

  factory Shelf.fromJson(String source) => Shelf.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [id, userId, name];
}
