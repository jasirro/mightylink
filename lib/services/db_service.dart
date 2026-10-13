import 'package:hive_flutter/hive_flutter.dart';
import '../models/group.dart';
import '../models/saved_link.dart';

class DbService {
  static String? _activeUser;

  static String get activeUser {
    if (_activeUser != null) return _activeUser!;
    final authBox = Hive.box('auth');
    final user = authBox.get('currentUser', defaultValue: '') as String;
    _activeUser = user;
    return user;
  }

  static set activeUser(String user) {
    _activeUser = user;
  }

  static String get groupsBoxName {
    final user = activeUser;
    return user.isEmpty ? 'groups' : 'groups_$user';
  }

  static String get linksBoxName {
    final user = activeUser;
    return user.isEmpty ? 'links' : 'links_$user';
  }

  static Box<Group> get groupsBox => Hive.box<Group>(groupsBoxName);
  static Box<SavedLink> get linksBox => Hive.box<SavedLink>(linksBoxName);

  static Future<void> openUserBoxes(String username) async {
    await Hive.openBox<Group>('groups_$username');
    await Hive.openBox<SavedLink>('links_$username');
  }

  static Future<void> closeUserBoxes(String username) async {
    if (Hive.isBoxOpen('groups_$username')) {
      await Hive.box<Group>('groups_$username').close();
    }
    if (Hive.isBoxOpen('links_$username')) {
      await Hive.box<SavedLink>('links_$username').close();
    }
  }
}
