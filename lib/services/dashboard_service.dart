import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'google_drive_sync_service.dart';

class ReminderItem {
  final String id;
  String title;
  String url;
  DateTime dueDate;
  String priority; // 'urgent', 'high', 'normal'
  bool isCompleted;

  ReminderItem({
    required this.id,
    required this.title,
    required this.url,
    required this.dueDate,
    this.priority = 'normal',
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'url': url,
    'dueDate': dueDate.toIso8601String(),
    'priority': priority,
    'isCompleted': isCompleted,
  };

  factory ReminderItem.fromMap(Map<String, dynamic> map) => ReminderItem(
    id: map['id'] as String,
    title: map['title'] as String,
    url: (map['url'] as String?) ?? '',
    dueDate: DateTime.tryParse(map['dueDate'] as String? ?? '') ?? DateTime.now(),
    priority: (map['priority'] as String?) ?? 'normal',
    isCompleted: (map['isCompleted'] as bool?) ?? false,
  );
}

class VaultItem {
  final String id;
  String title;
  String url;
  String secretNote;
  DateTime createdAt;

  VaultItem({
    required this.id,
    required this.title,
    required this.url,
    required this.secretNote,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'url': url,
    'secretNote': secretNote,
    'createdAt': createdAt.toIso8601String(),
  };

  factory VaultItem.fromMap(Map<String, dynamic> map) => VaultItem(
    id: map['id'] as String,
    title: map['title'] as String,
    url: (map['url'] as String?) ?? '',
    secretNote: (map['secretNote'] as String?) ?? '',
    createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class SharedBundle {
  final String id;
  String title;
  String shareUrl;
  int linkCount;
  String expiresIn;
  int views;
  bool isPasswordProtected;

  SharedBundle({
    required this.id,
    required this.title,
    required this.shareUrl,
    required this.linkCount,
    this.expiresIn = 'Never',
    this.views = 0,
    this.isPasswordProtected = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'shareUrl': shareUrl,
    'linkCount': linkCount,
    'expiresIn': expiresIn,
    'views': views,
    'isPasswordProtected': isPasswordProtected,
  };

  factory SharedBundle.fromMap(Map<String, dynamic> map) => SharedBundle(
    id: map['id'] as String,
    title: map['title'] as String,
    shareUrl: map['shareUrl'] as String,
    linkCount: (map['linkCount'] as int?) ?? 1,
    expiresIn: (map['expiresIn'] as String?) ?? 'Never',
    views: (map['views'] as int?) ?? 0,
    isPasswordProtected: (map['isPasswordProtected'] as bool?) ?? false,
  );
}

class TeamMember {
  final String id;
  String name;
  String email;
  String role; // 'Owner', 'Admin', 'Editor', 'Viewer'

  TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
  };

  factory TeamMember.fromMap(Map<String, dynamic> map) => TeamMember(
    id: map['id'] as String,
    name: map['name'] as String,
    email: map['email'] as String,
    role: map['role'] as String,
  );
}

class DashboardService {
  static const String _boxName = 'dashboard_store';
  static bool isVaultUnlocked = false;
  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  static Box get _box => Hive.box(_boxName);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    _seedInitialDataIfNeeded();
  }

  static void _notify() {
    changeNotifier.value++;
  }

  static void _seedInitialDataIfNeeded() {
    // Seed extension token if none
    if (!_box.containsKey('extension_token')) {
      _box.put('extension_token', 'ML-8942-SYNC');
      _box.put('extension_connected', true);
      _box.put('extension_browsers', jsonEncode(['Chrome (Desktop)', 'Brave Browser']));
    }

    // Seed Reminders
    if (!_box.containsKey('reminders')) {
      final initialReminders = [
        ReminderItem(
          id: const Uuid().v4(),
          title: 'Review Figma Design Tokens',
          url: 'https://figma.com/design/mighty-link',
          dueDate: DateTime.now().add(const Duration(hours: 4)),
          priority: 'urgent',
          isCompleted: false,
        ),
        ReminderItem(
          id: const Uuid().v4(),
          title: 'Check Flutter 3.44 Migration Notes',
          url: 'https://docs.flutter.dev/release/breaking-changes',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          priority: 'high',
          isCompleted: false,
        ),
        ReminderItem(
          id: const Uuid().v4(),
          title: 'Read Google Cloud OAuth Guidelines',
          url: 'https://cloud.google.com/docs/authentication',
          dueDate: DateTime.now().add(const Duration(days: 3)),
          priority: 'normal',
          isCompleted: true,
        ),
      ];
      _saveReminders(initialReminders);
    }

    // Seed Vault
    if (!_box.containsKey('vault_pin')) {
      _box.put('vault_pin', '1234');
    }
    if (!_box.containsKey('vault_items')) {
      final initialVaultItems = [
        VaultItem(
          id: const Uuid().v4(),
          title: 'Stripe Merchant Production Dashboard',
          url: 'https://dashboard.stripe.com/live/apikeys',
          secretNote: 'Live API restricted keys & webhook signing secret',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        VaultItem(
          id: const Uuid().v4(),
          title: 'AWS Cloud Console (Root MFA)',
          url: 'https://us-east-1.signin.aws.amazon.com/console',
          secretNote: 'Hardware YubiKey required for login',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];
      _saveVaultItems(initialVaultItems);
    }

    // Seed Shared Bundles
    if (!_box.containsKey('shared_bundles')) {
      final initialBundles = [
        SharedBundle(
          id: const Uuid().v4(),
          title: 'Product Design & System Specs',
          shareUrl: 'https://mightylink.app/s/design-tokens-921',
          linkCount: 14,
          expiresIn: 'Never',
          views: 48,
          isPasswordProtected: false,
        ),
        SharedBundle(
          id: const Uuid().v4(),
          title: 'Q4 Investor Research Deck',
          shareUrl: 'https://mightylink.app/s/investor-q4-secure',
          linkCount: 6,
          expiresIn: '7 Days',
          views: 19,
          isPasswordProtected: true,
        ),
      ];
      _saveSharedBundles(initialBundles);
    }

    // Seed Team Members
    if (!_box.containsKey('team_members')) {
      final initialMembers = [
        TeamMember(
          id: const Uuid().v4(),
          name: 'Alex Rivera (You)',
          email: 'alex@mightylink.io',
          role: 'Owner',
        ),
        TeamMember(
          id: const Uuid().v4(),
          name: 'Sarah Chen',
          email: 'sarah.c@mightylink.io',
          role: 'Admin',
        ),
        TeamMember(
          id: const Uuid().v4(),
          name: 'David Kim',
          email: 'david.k@mightylink.io',
          role: 'Editor',
        ),
      ];
      _saveTeamMembers(initialMembers);
    }
  }

  // --- Browser Extension ---
  static String get extensionToken => _box.get('extension_token', defaultValue: 'ML-8942-SYNC');
  static bool get isExtensionConnected => _box.get('extension_connected', defaultValue: true);
  
  static List<String> get connectedBrowsers {
    final raw = _box.get('extension_browsers');
    if (raw == null) return ['Chrome (Desktop)', 'Brave Browser'];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return ['Chrome (Desktop)'];
    }
  }

  static void regenerateExtensionToken() {
    final rand = (1000 + DateTime.now().millisecond % 9000);
    _box.put('extension_token', 'ML-$rand-SYNC');
    _notify();
  }

  // --- Smart Reminders & Todo ---
  static List<ReminderItem> getReminders() {
    final raw = _box.get('reminders');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ReminderItem.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  static void _saveReminders(List<ReminderItem> items) {
    _box.put('reminders', jsonEncode(items.map((e) => e.toMap()).toList()));
    _notify();
    GoogleDriveSyncService.scheduleDebouncedSync();
  }

  static void addReminder(ReminderItem item) {
    final items = getReminders();
    items.insert(0, item);
    _saveReminders(items);
  }

  static void toggleReminder(String id) {
    final items = getReminders();
    for (var item in items) {
      if (item.id == id) {
        item.isCompleted = !item.isCompleted;
        break;
      }
    }
    _saveReminders(items);
  }

  static void deleteReminder(String id) {
    final items = getReminders();
    items.removeWhere((e) => e.id == id);
    _saveReminders(items);
  }

  // --- Secure Vault ---
  static String get vaultPin => _box.get('vault_pin', defaultValue: '1234');

  static bool checkPin(String pin) {
    return pin.trim() == vaultPin;
  }

  static void setPin(String newPin) {
    _box.put('vault_pin', newPin.trim());
    _notify();
  }

  static List<VaultItem> getVaultItems() {
    final raw = _box.get('vault_items');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => VaultItem.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  static void _saveVaultItems(List<VaultItem> items) {
    _box.put('vault_items', jsonEncode(items.map((e) => e.toMap()).toList()));
    _notify();
    GoogleDriveSyncService.scheduleDebouncedSync();
  }

  static void addVaultItem(VaultItem item) {
    final items = getVaultItems();
    items.insert(0, item);
    _saveVaultItems(items);
  }

  static void deleteVaultItem(String id) {
    final items = getVaultItems();
    items.removeWhere((e) => e.id == id);
    _saveVaultItems(items);
  }

  // --- Link Sharing ---
  static List<SharedBundle> getSharedBundles() {
    final raw = _box.get('shared_bundles');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => SharedBundle.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  static void _saveSharedBundles(List<SharedBundle> items) {
    _box.put('shared_bundles', jsonEncode(items.map((e) => e.toMap()).toList()));
    _notify();
  }

  static void addSharedBundle(SharedBundle bundle) {
    final items = getSharedBundles();
    items.insert(0, bundle);
    _saveSharedBundles(items);
  }

  static void deleteSharedBundle(String id) {
    final items = getSharedBundles();
    items.removeWhere((e) => e.id == id);
    _saveSharedBundles(items);
  }

  // --- Team Workspace ---
  static String get teamWorkspaceName => _box.get('team_name', defaultValue: 'MightyLink Product Squad');

  static List<TeamMember> getTeamMembers() {
    final raw = _box.get('team_members');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => TeamMember.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  static void _saveTeamMembers(List<TeamMember> items) {
    _box.put('team_members', jsonEncode(items.map((e) => e.toMap()).toList()));
    _notify();
  }

  static void inviteTeamMember(String name, String email, String role) {
    final members = getTeamMembers();
    members.add(TeamMember(
      id: const Uuid().v4(),
      name: name,
      email: email,
      role: role,
    ));
    _saveTeamMembers(members);
  }

  static void removeTeamMember(String id) {
    final members = getTeamMembers();
    members.removeWhere((e) => e.id == id);
    _saveTeamMembers(members);
  }
}
