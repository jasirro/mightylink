import 'package:hive/hive.dart';

part 'group.g.dart';

@HiveType(typeId: 0)
class Group extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.createdAt,
  });
}
