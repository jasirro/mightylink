// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_link.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedLinkAdapter extends TypeAdapter<SavedLink> {
  @override
  final int typeId = 1;

  @override
  SavedLink read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedLink(
      id: fields[0] as String,
      title: fields[1] as String,
      url: fields[2] as String,
      note: fields[3] as String,
      groupId: fields[4] as String,
      isFavorite: fields[5] as bool,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SavedLink obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.groupId)
      ..writeByte(5)
      ..write(obj.isFavorite)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedLinkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
