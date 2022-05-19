import 'package:equatable/equatable.dart';

abstract class Item extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? firebaseCoverImagePath;
  final Set<String> collectionIds;

  String get routeTo;

  const Item({
    required this.id,
    required this.userId,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.firebaseCoverImagePath,
    required this.collectionIds,
  });

  Item copyWith();

  Map<String, dynamic> toMapSerializable();

  Map<String, dynamic> toMapFirebase();

  String toJsonFirebase();

  @override
  bool get stringify;

  @override
  List<Object> get props;
}
