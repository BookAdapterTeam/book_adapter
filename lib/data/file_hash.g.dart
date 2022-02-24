// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_hash.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FileHashAdapter extends TypeAdapter<FileHash> {
  @override
  final int typeId = 1;

  @override
  FileHash read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FileHash(
      filepath: fields[0] as String,
      collectionName: fields[3] as String,
      md5: fields[1] as String,
      sha1: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FileHash obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.filepath)
      ..writeByte(3)
      ..write(obj.collectionName)
      ..writeByte(1)
      ..write(obj.md5)
      ..writeByte(2)
      ..write(obj.sha1);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileHashAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
