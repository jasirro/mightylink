import 'package:hive/hive.dart';

part 'saved_link.g.dart';

@HiveType(typeId: 1)
class SavedLink extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String url;

  @HiveField(3)
  String note;

  @HiveField(4)
  String groupId;

  @HiveField(5)
  bool isFavorite;

  @HiveField(6)
  DateTime createdAt;

  SavedLink({
    required this.id,
    required this.title,
    required this.url,
    required this.note,
    required this.groupId,
    this.isFavorite = false,
    required this.createdAt,
  });
}
