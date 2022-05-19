import 'dart:convert';

import 'package:book_adapter/src/features/library/data/item.dart';
import 'package:book_adapter/src/features/library/series_view.dart';

class Series implements Item {
  @override
  final String id;
  @override
  final String userId;
  @override
  final String title;
  @override
  final String? subtitle;
  @override
  final String? imageUrl;
  @override
  final Set<String> collectionIds;
  @override
  final String? firebaseCoverImagePath;

  final String description;
  const Series({
    required this.id,
    required this.userId,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.firebaseCoverImagePath,
    this.description = '',
    required this.collectionIds,
  });

  @override
  String get routeTo => SeriesView.routeName;

  @override
  Series copyWith({
    String? id,
    String? userId,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? firebaseCoverImagePath,
    String? description,
    Set<String>? collectionIds,
  }) {
    return Series(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      firebaseCoverImagePath:
          firebaseCoverImagePath ?? this.firebaseCoverImagePath,
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
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'firebaseCoverImagePath': firebaseCoverImagePath,
      'description': description,
      'collectionIds': collectionIds.toList()
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
      subtitle: map['subtitle'],
      imageUrl: map['imageUrl'],
      firebaseCoverImagePath: map['firebaseCoverImagePath'],
      description: map['description'],
      collectionIds: List<String>.from(map['collectionIds']).toSet(),
    );
  }

  @override
  String toJsonFirebase() => json.encode(toMapFirebase());

  factory Series.fromJsonFirebase(String source) =>
      Series.fromMapFirebase(json.decode(source));

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [
        id,
        userId,
        title,
        subtitle ?? 'No subtitle',
        imageUrl ?? 'No image',
        description,
        collectionIds
      ];
}
