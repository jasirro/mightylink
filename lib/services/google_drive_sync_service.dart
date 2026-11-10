import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'db_service.dart';
import 'dashboard_service.dart';
import 'vault_cipher.dart';
import '../models/group.dart';
import '../models/saved_link.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveSyncService {
  static const String _syncBoxName = 'google_sync_settings';
  static const String _sheetFileName = 'MightyLink_Database';

  // Safe Google OAuth scopes (NO risky full Gmail inbox scopes)
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope, // Only files created by MightyLink
      sheets.SheetsApi.spreadsheetsScope, // Read/write personal spreadsheet
    ],
  );

  static final ValueNotifier<int> syncNotifier = ValueNotifier<int>(0);
  static bool isSyncing = false;
  static String? lastError;

  static Box get _syncBox => Hive.box(_syncBoxName);

  static Timer? _autoSyncTimer;
  static Timer? _debounceSyncTimer;

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_syncBoxName)) {
      await Hive.openBox(_syncBoxName);
    }
    if (isConnected && isAutoSyncEnabled) {
      startAutoSyncWorker();
    }
  }

  // --- Auto-Sync Worker Configuration ---
  static bool get isAutoSyncEnabled => _syncBox.get('is_auto_sync_enabled', defaultValue: true);
  static int get autoSyncIntervalMinutes => _syncBox.get('auto_sync_interval_minutes', defaultValue: 15);

  static Future<void> setAutoSyncEnabled(bool enabled) async {
    await _syncBox.put('is_auto_sync_enabled', enabled);
    if (enabled) {
      startAutoSyncWorker();
    } else {
      stopAutoSyncWorker();
    }
    syncNotifier.value++;
  }

  static Future<void> setAutoSyncInterval(int minutes) async {
    await _syncBox.put('auto_sync_interval_minutes', minutes);
    if (isAutoSyncEnabled) {
      startAutoSyncWorker();
    }
    syncNotifier.value++;
  }

  static void startAutoSyncWorker() {
    stopAutoSyncWorker();
    if (!isAutoSyncEnabled || !isConnected) return;
    _autoSyncTimer = Timer.periodic(Duration(minutes: autoSyncIntervalMinutes), (_) {
      triggerAutoSync(reason: 'periodic_timer');
    });
  }

  static void stopAutoSyncWorker() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Debounces rapid local edits and auto-syncs after 4 seconds of idle
  static void scheduleDebouncedSync() {
    if (!isAutoSyncEnabled || !isConnected) return;
    _debounceSyncTimer?.cancel();
    _debounceSyncTimer = Timer(const Duration(seconds: 4), () {
      triggerAutoSync(reason: 'data_changed');
    });
  }

  static Future<void> triggerAutoSync({String reason = 'background'}) async {
    if (!isConnected || isSyncing) return;
    try {
      debugPrint('[AutoSyncWorker] Running automatic sync (reason: $reason)...');
      await syncToGoogleSheets();
    } catch (e) {
      debugPrint('[AutoSyncWorker] Auto-sync skipped: $e');
    }
  }

  // --- Getters for UI State ---
  static bool get isConnected => _syncBox.get('is_connected', defaultValue: false);
  static String get connectedEmail => _syncBox.get('google_email', defaultValue: '');
  static String get connectedName => _syncBox.get('google_name', defaultValue: '');
  static String get connectedPhoto => _syncBox.get('google_photo', defaultValue: '');
  static String get spreadsheetId => _syncBox.get('spreadsheet_id', defaultValue: '');
  static String get spreadsheetUrl => _syncBox.get(
    'spreadsheet_url',
    defaultValue: spreadsheetId.isNotEmpty ? 'https://docs.google.com/spreadsheets/d/$spreadsheetId' : '',
  );

  static DateTime? get lastSyncTime {
    final str = _syncBox.get('last_sync_time');
    return str != null ? DateTime.tryParse(str) : null;
  }

  // --- Tombstones for Offline Deletions ---
  static void recordDeletedLink(String linkId) {
    final list = _syncBox.get('tombstone_links', defaultValue: <String>[]);
    final mutable = List<String>.from(list);
    if (!mutable.contains(linkId)) {
      mutable.add(linkId);
      _syncBox.put('tombstone_links', mutable);
    }
  }

  static void recordDeletedGroup(String groupId) {
    final list = _syncBox.get('tombstone_groups', defaultValue: <String>[]);
    final mutable = List<String>.from(list);
    if (!mutable.contains(groupId)) {
      mutable.add(groupId);
      _syncBox.put('tombstone_groups', mutable);
    }
  }

  static List<String> get deletedLinkIds => List<String>.from(_syncBox.get('tombstone_links', defaultValue: <String>[]));
  static List<String> get deletedGroupIds => List<String>.from(_syncBox.get('tombstone_groups', defaultValue: <String>[]));

  static void _clearTombstones() {
    _syncBox.put('tombstone_links', <String>[]);
    _syncBox.put('tombstone_groups', <String>[]);
  }

  // --- Connect Google Account ---
  static Future<GoogleSignInAccount?> connectGoogleAccount() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await _syncBox.put('is_connected', true);
        await _syncBox.put('google_email', account.email);
        await _syncBox.put('google_name', account.displayName ?? account.email.split('@').first);
        await _syncBox.put('google_photo', account.photoUrl ?? '');
        startAutoSyncWorker();
        syncNotifier.value++;
      }
      return account;
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      rethrow;
    }
  }

  // --- Disconnect Google Account ---
  static Future<void> disconnectGoogleAccount() async {
    stopAutoSyncWorker();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _syncBox.put('is_connected', false);
    await _syncBox.put('google_email', '');
    await _syncBox.put('google_name', '');
    await _syncBox.put('google_photo', '');
    await _syncBox.put('spreadsheet_id', '');
    await _syncBox.put('spreadsheet_url', '');
    syncNotifier.value++;
  }

  // --- Two-Way Bidirectional Sync Engine ---
  static Future<void> syncToGoogleSheets() async {
    if (isSyncing) return;
    isSyncing = true;
    lastError = null;
    syncNotifier.value++;

    try {
      var account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) throw Exception("Google Sign-in was cancelled or aborted.");

      // Save user profile
      await _syncBox.put('is_connected', true);
      await _syncBox.put('google_email', account.email);
      await _syncBox.put('google_name', account.displayName ?? account.email.split('@').first);
      await _syncBox.put('google_photo', account.photoUrl ?? '');

      final authHeaders = await account.authHeaders;
      final authClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authClient);
      final sheetsApi = sheets.SheetsApi(authClient);

      // 1. Locate or Auto-Create Personal Spreadsheet
      String sheetId = spreadsheetId;
      if (sheetId.isEmpty) {
        final query = "name = '$_sheetFileName' and mimeType = 'application/vnd.google-apps.spreadsheet' and trashed = false";
        final fileList = await driveApi.files.list(q: query, spaces: 'drive');

        if (fileList.files != null && fileList.files!.isNotEmpty) {
          sheetId = fileList.files!.first.id!;
        } else {
          // Create new personal spreadsheet
          final newFile = drive.File()
            ..name = _sheetFileName
            ..mimeType = 'application/vnd.google-apps.spreadsheet';
          final result = await driveApi.files.create(newFile);
          sheetId = result.id!;

          // Add required tabs
          final batchUpdate = sheets.BatchUpdateSpreadsheetRequest(
            requests: [
              sheets.Request(addSheet: sheets.AddSheetRequest(properties: sheets.SheetProperties(title: 'Workspaces'))),
              sheets.Request(addSheet: sheets.AddSheetRequest(properties: sheets.SheetProperties(title: 'Links'))),
              sheets.Request(addSheet: sheets.AddSheetRequest(properties: sheets.SheetProperties(title: 'Reminders'))),
              sheets.Request(addSheet: sheets.AddSheetRequest(properties: sheets.SheetProperties(title: 'VaultEncrypted'))),
              sheets.Request(addSheet: sheets.AddSheetRequest(properties: sheets.SheetProperties(title: 'SyncMeta'))),
            ],
          );
          await sheetsApi.spreadsheets.batchUpdate(batchUpdate, sheetId);
        }

        await _syncBox.put('spreadsheet_id', sheetId);
        await _syncBox.put('spreadsheet_url', 'https://docs.google.com/spreadsheets/d/$sheetId');
      }

      // 2. Fetch Remote Data for Two-Way Merge
      final remoteGroupsMap = <String, Map<String, dynamic>>{};
      final remoteLinksMap = <String, Map<String, dynamic>>{};

      try {
        final groupsRes = await sheetsApi.spreadsheets.values.get(sheetId, 'Workspaces!A:E');
        if (groupsRes.values != null && groupsRes.values!.length > 1) {
          for (int i = 1; i < groupsRes.values!.length; i++) {
            final row = groupsRes.values![i];
            if (row.isEmpty) continue;
            final id = row[0].toString();
            remoteGroupsMap[id] = {
              'id': id,
              'name': row.length > 1 ? row[1].toString() : 'Workspace',
              'createdAt': row.length > 2 ? row[2].toString() : '',
              'isDeleted': row.length > 4 ? row[4].toString().toLowerCase() == 'true' : false,
            };
          }
        }
      } catch (_) {}

      try {
        final linksRes = await sheetsApi.spreadsheets.values.get(sheetId, 'Links!A:H');
        if (linksRes.values != null && linksRes.values!.length > 1) {
          for (int i = 1; i < linksRes.values!.length; i++) {
            final row = linksRes.values![i];
            if (row.isEmpty) continue;
            final id = row[0].toString();
            remoteLinksMap[id] = {
              'id': id,
              'groupId': row.length > 1 ? row[1].toString() : '',
              'title': row.length > 2 ? row[2].toString() : '',
              'url': row.length > 3 ? row[3].toString() : '',
              'isFavorite': row.length > 4 ? row[4].toString().toLowerCase() == 'true' : false,
              'createdAt': row.length > 5 ? row[5].toString() : '',
              'note': row.length > 6 ? row[6].toString() : '',
              'isDeleted': row.length > 7 ? row[7].toString().toLowerCase() == 'true' : false,
            };
          }
        }
      } catch (_) {}

      // 3. Merge Remote Workspaces into Local Hive
      final localGroupsBox = DbService.groupsBox;
      for (var entry in remoteGroupsMap.entries) {
        final r = entry.value;
        if (r['isDeleted'] == true) {
          await localGroupsBox.delete(entry.key);
        } else if (!localGroupsBox.containsKey(entry.key)) {
          final newG = Group(
            id: r['id'],
            name: r['name'],
            createdAt: DateTime.tryParse(r['createdAt']) ?? DateTime.now(),
          );
          await localGroupsBox.put(newG.id, newG);
        }
      }

      // 4. Merge Remote Links into Local Hive
      final localLinksBox = DbService.linksBox;
      for (var entry in remoteLinksMap.entries) {
        final r = entry.value;
        if (r['isDeleted'] == true) {
          await localLinksBox.delete(entry.key);
        } else if (!localLinksBox.containsKey(entry.key)) {
          final newL = SavedLink(
            id: r['id'],
            groupId: r['groupId'],
            title: r['title'],
            url: r['url'],
            isFavorite: r['isFavorite'],
            createdAt: DateTime.tryParse(r['createdAt']) ?? DateTime.now(),
            note: r['note'],
          );
          await localLinksBox.put(newL.id, newL);
        }
      }

      // 4b. Fetch & Merge Remote Reminders
      try {
        final remindersRes = await sheetsApi.spreadsheets.values.get(sheetId, 'Reminders!A:H');
        if (remindersRes.values != null && remindersRes.values!.length > 1) {
          final localReminders = DashboardService.getReminders();
          final localIds = localReminders.map((rem) => rem.id).toSet();
          for (int i = 1; i < remindersRes.values!.length; i++) {
            final row = remindersRes.values![i];
            if (row.isEmpty) continue;
            final id = row[0].toString();
            final isDeleted = row.length > 7 ? row[7].toString().toLowerCase() == 'true' : false;
            if (isDeleted) {
              DashboardService.deleteReminder(id);
            } else if (!localIds.contains(id)) {
              DashboardService.addReminder(ReminderItem(
                id: id,
                title: row.length > 1 ? row[1].toString() : '',
                url: row.length > 2 ? row[2].toString() : '',
                dueDate: row.length > 3 ? (DateTime.tryParse(row[3].toString()) ?? DateTime.now()) : DateTime.now(),
                priority: row.length > 4 ? row[4].toString() : 'normal',
                isCompleted: row.length > 5 ? row[5].toString().toLowerCase() == 'true' : false,
              ));
            }
          }
        }
      } catch (_) {}

      // 4c. Fetch & Merge Remote Encrypted Vault
      try {
        final vaultRes = await sheetsApi.spreadsheets.values.get(sheetId, 'VaultEncrypted!A:G');
        if (vaultRes.values != null && vaultRes.values!.length > 1) {
          final localVault = DashboardService.getVaultItems();
          final localIds = localVault.map((v) => v.id).toSet();
          final pin = DashboardService.vaultPin;
          for (int i = 1; i < vaultRes.values!.length; i++) {
            final row = vaultRes.values![i];
            if (row.isEmpty) continue;
            final id = row[0].toString();
            final isDeleted = row.length > 6 ? row[6].toString().toLowerCase() == 'true' : false;
            if (isDeleted) {
              DashboardService.deleteVaultItem(id);
            } else if (!localIds.contains(id)) {
              DashboardService.addVaultItem(VaultItem(
                id: id,
                title: row.length > 1 ? VaultCipher.decrypt(row[1].toString(), pin) : '',
                url: row.length > 2 ? VaultCipher.decrypt(row[2].toString(), pin) : '',
                secretNote: row.length > 3 ? VaultCipher.decrypt(row[3].toString(), pin) : '',
                createdAt: row.length > 4 ? (DateTime.tryParse(row[4].toString()) ?? DateTime.now()) : DateTime.now(),
              ));
            }
          }
        }
      } catch (_) {}

      // 5. Build Two-Way PUSH Rows to Google Sheets (Workspaces)
      final allLocalGroups = localGroupsBox.values.toList();
      final deletedGIds = deletedGroupIds;
      final groupRows = <List<Object>>[
        ['ID', 'Name', 'CreatedAt', 'UpdatedAt', 'IsDeleted']
      ];

      for (var g in allLocalGroups) {
        groupRows.add([g.id, g.name, g.createdAt.toIso8601String(), DateTime.now().toIso8601String(), 'false']);
      }
      for (var gid in deletedGIds) {
        groupRows.add([gid, 'Deleted', '', DateTime.now().toIso8601String(), 'true']);
      }

      // 6. Build Two-Way PUSH Rows to Google Sheets (Links)
      final allLocalLinks = localLinksBox.values.toList();
      final deletedLIds = deletedLinkIds;
      final linkRows = <List<Object>>[
        ['ID', 'GroupId', 'Title', 'URL', 'IsFavorite', 'CreatedAt', 'Note', 'IsDeleted']
      ];

      for (var l in allLocalLinks) {
        linkRows.add([
          l.id,
          l.groupId,
          l.title,
          l.url,
          l.isFavorite.toString(),
          l.createdAt.toIso8601String(),
          l.note,
          'false'
        ]);
      }
      for (var lid in deletedLIds) {
        linkRows.add([lid, '', 'Deleted', '', 'false', '', '', 'true']);
      }

      // 7. Build Reminders Rows (Smart Reminder & Todo)
      final reminders = DashboardService.getReminders();
      final reminderRows = <List<Object>>[
        ['ID', 'Title', 'URL', 'DueDate', 'Priority', 'IsCompleted', 'UpdatedAt', 'IsDeleted']
      ];
      for (var rem in reminders) {
        reminderRows.add([
          rem.id,
          rem.title,
          rem.url,
          rem.dueDate.toIso8601String(),
          rem.priority,
          rem.isCompleted.toString(),
          DateTime.now().toIso8601String(),
          'false'
        ]);
      }

      // 8. Build Vault Rows (Encrypted Client-Side with VaultCipher)
      final pin = DashboardService.vaultPin;
      final vaultItems = DashboardService.getVaultItems();
      final vaultRows = <List<Object>>[
        ['ID', 'TitleCipher', 'URLCipher', 'SecretNoteCipher', 'CreatedAt', 'UpdatedAt', 'IsDeleted']
      ];
      for (var v in vaultItems) {
        vaultRows.add([
          v.id,
          VaultCipher.encrypt(v.title, pin),
          VaultCipher.encrypt(v.url, pin),
          VaultCipher.encrypt(v.secretNote, pin),
          v.createdAt.toIso8601String(),
          DateTime.now().toIso8601String(),
          'false'
        ]);
      }

      // 9. Sync Metadata Row
      final metaRows = <List<Object>>[
        ['Key', 'Value', 'UpdatedAt'],
        ['App', 'MightyLink', DateTime.now().toIso8601String()],
        ['Version', '1.0.0', DateTime.now().toIso8601String()],
        ['LastSync', DateTime.now().toIso8601String(), DateTime.now().toIso8601String()],
        ['Account', account.email, DateTime.now().toIso8601String()],
      ];

      // 10. Execute Google Sheets Batch Updates
      final updateData = [
        sheets.ValueRange(range: 'Workspaces!A1', values: groupRows),
        sheets.ValueRange(range: 'Links!A1', values: linkRows),
        sheets.ValueRange(range: 'Reminders!A1', values: reminderRows),
        sheets.ValueRange(range: 'VaultEncrypted!A1', values: vaultRows),
        sheets.ValueRange(range: 'SyncMeta!A1', values: metaRows),
      ];

      final batchUpdateReq = sheets.BatchUpdateValuesRequest(
        data: updateData,
        valueInputOption: 'USER_ENTERED',
      );

      await sheetsApi.spreadsheets.values.batchUpdate(batchUpdateReq, sheetId);

      // Clean up tombstones and record sync timestamp
      _clearTombstones();
      await _syncBox.put('last_sync_time', DateTime.now().toIso8601String());

    } catch (e) {
      debugPrint('Sync Engine Error: $e');
      lastError = e.toString();
      rethrow;
    } finally {
      isSyncing = false;
      syncNotifier.value++;
    }
  }
}
