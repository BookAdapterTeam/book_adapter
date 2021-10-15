import 'dart:convert';

import 'item.dart';

class Series extends Item {
  final String description;
  const Series({
    required String id,
    required String userId,
    required String title,
    this.description = '',
    required List<String> collectionIds,
  }) : super(id: id, userId: userId, title: title, collectionIds: collectionIds);

  @override
  // TODO: implement routeTo
  String get routeTo => throw UnimplementedError();

  @override
  Series copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<String>? collectionIds,
  }) {
    return Series(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      collectionIds: collectionIds ?? this.collectionIds,
    );
  }

  @override
  Map<String, dynamic> toMapFirebase() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'collectionIds': collectionIds
    };
  }

  @override
  Map<String, dynamic> toMapSerializable() {
    return toMapFirebase();
  }

  factory Series.fromMapFirebase(Map<String, dynamic> map) {
    return Series(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      collectionIds: List.from(map['collectionIds']),
    );
  }

  @override
  String toJsonFirebase() => json.encode(toMapFirebase());

  factory Series.fromJsonFirebase(String source) => Series.fromMapFirebase(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [id, userId, title, description, collectionIds];
}
