import 'dart:convert';

import 'package:equatable/equatable.dart';

class Item extends Equatable {
  final String id;
  final String userId;
  const Item({
    required this.id,
    required this.userId,
  });

  Item copyWith({
    String? id,
    String? userId,
  }) {
    return Item(
      id: id ?? this.id,
      userId: userId ?? this.userId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      userId: map['userId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Item.fromJson(String source) => Item.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [id, userId];
}
