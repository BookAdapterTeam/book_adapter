import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'file_hash.g.dart';

@immutable
@HiveType(typeId: 1) // If change Hive stuff, run `flutter packages pub run build_runner build` with flutter generate disabled in pubspec.yaml
class FileHash extends Equatable {
  @HiveField(0)
  final String filepath;

  @HiveField(1)
  final String md5;

  @HiveField(2)
  final String sha1;

  const FileHash({
    required this.filepath,
    required this.md5,
    required this.sha1,
  });

  FileHash copyWith({
    String? filepath,
    String? md5,
    String? sha1,
  }) {
    return FileHash(
      filepath: filepath ?? this.filepath,
      md5: md5 ?? this.md5,
      sha1: sha1 ?? this.sha1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'md5': md5,
      'sha1': sha1,
    };
  }

  factory FileHash.fromMap(Map<String, dynamic> map) {
    return FileHash(
      filepath: map['filepath'] ?? '',
      md5: map['md5'] ?? '',
      sha1: map['sha1'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory FileHash.fromJson(String source) =>
      FileHash.fromMap(json.decode(source));

  @override
  String toString() => 'FileHash(filepath: $filepath, md5: $md5, sha1: $sha1)';

  @override
  List<Object> get props => [filepath, md5, sha1];
}
