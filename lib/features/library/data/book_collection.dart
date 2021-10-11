import 'dart:convert';

import 'item.dart';

class BookCollection extends Item {

  const BookCollection({
    required id,
    required userId,
    required title,
  }) : super(id: id, userId: userId, title: title);

  @override
  BookCollection copyWith({
    String? id,
    String? userId,
    String? title,
  }) {
    return BookCollection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
    );
  }

  @override
  Map<String, dynamic> toMapSerializable() => toMapFirebase();

  factory BookCollection.fromMapSerializable(Map<String, dynamic> map) => BookCollection.fromMap(map);

  @override
  Map<String, dynamic> toMapFirebase() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
    };
  }

  factory BookCollection.fromMap(Map<String, dynamic> map) {
    return BookCollection(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
    );
  }

  @override
  String toJsonFirebase() => json.encode(toMapFirebase());

  factory BookCollection.fromJson(String source) => BookCollection.fromMap(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [id, userId, title];
}
