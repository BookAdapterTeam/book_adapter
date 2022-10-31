import 'dart:convert';

import '../presentation/series_view.dart';
import 'item.dart';

class Series extends Item {
  final String description;

  const Series({
    required super.id,
    required super.userId,
    required super.title,
    super.subtitle,
    super.imageUrl,
    super.firebaseCoverImagePath,
    this.description = '',
    required super.collectionIds,
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
  }) =>
      Series(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        imageUrl: imageUrl ?? this.imageUrl,
        firebaseCoverImagePath: firebaseCoverImagePath ?? this.firebaseCoverImagePath,
        description: description ?? this.description,
        collectionIds: collectionIds ?? this.collectionIds,
      );

  @override
  Map<String, dynamic> toMapFirebase() => {
        'id': id,
        'userId': userId,
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'firebaseCoverImagePath': firebaseCoverImagePath,
        'description': description,
        'collectionIds': collectionIds.toList()
      };

  @override
  Map<String, dynamic> toMapSerializable() => toMapFirebase();

  factory Series.fromMapFirebase(Map<String, dynamic> map) => Series(
        id: map['id'],
        userId: map['userId'],
        title: map['title'],
        subtitle: map['subtitle'],
        imageUrl: map['imageUrl'],
        firebaseCoverImagePath: map['firebaseCoverImagePath'],
        description: map['description'],
        collectionIds: List<String>.from(map['collectionIds']).toSet(),
      );

  @override
  String toJsonFirebase() => json.encode(toMapFirebase());

  factory Series.fromJsonFirebase(String source) => Series.fromMapFirebase(json.decode(source));

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
