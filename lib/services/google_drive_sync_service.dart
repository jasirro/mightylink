import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import 'db_service.dart';
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
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
      sheets.SheetsApi.spreadsheetsScope,
    ],
  );

  /// Pushes local Hive data to a Google Sheet
  static Future<void> syncToGoogleSheets() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) throw Exception("Sign in aborted");

      final authHeaders = await account.authHeaders;
      final authClient = GoogleAuthClient(authHeaders);
      
      final driveApi = drive.DriveApi(authClient);
      final sheetsApi = sheets.SheetsApi(authClient);

      // Check if file exists
      final query = "name = 'Linku_Database' and mimeType = 'application/vnd.google-apps.spreadsheet' and trashed = false";
      final fileList = await driveApi.files.list(q: query, spaces: 'drive');
      
      String spreadsheetId = '';
      
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        spreadsheetId = fileList.files!.first.id!;
      } else {
        // Create new sheet
        final file = drive.File()
          ..name = 'Linku_Database'
          ..mimeType = 'application/vnd.google-apps.spreadsheet';
        final result = await driveApi.files.create(file);
        spreadsheetId = result.id!;
        
        // Add sheets for Groups and Links
        final batchUpdate = sheets.BatchUpdateSpreadsheetRequest(
          requests: [
            sheets.Request(addSheet: sheets.AddSheetRequest(properties: sheets.SheetProperties(title: 'Groups'))),
            sheets.Request(addSheet: sheets.AddSheetRequest(properties: sheets.SheetProperties(title: 'Links'))),
          ]
        );
        await sheetsApi.spreadsheets.batchUpdate(batchUpdate, spreadsheetId);
      }

      // Sync Groups
      final groups = DbService.groupsBox.values.toList();
      List<List<Object>> groupRows = [['ID', 'Name', 'CreatedAt']];
      for (var g in groups) {
        groupRows.add([g.id, g.name, g.createdAt.toIso8601String()]);
      }
      
      final groupValueRange = sheets.ValueRange(values: groupRows);
      await sheetsApi.spreadsheets.values.update(
        groupValueRange,
        spreadsheetId,
        'Groups!A1',
        valueInputOption: 'USER_ENTERED',
      );

      // Sync Links
      final links = DbService.linksBox.values.toList();
      List<List<Object>> linkRows = [['ID', 'GroupId', 'Title', 'URL', 'IsFavorite', 'CreatedAt', 'Note']];
      for (var l in links) {
        linkRows.add([l.id, l.groupId, l.title, l.url, l.isFavorite.toString(), l.createdAt.toIso8601String(), l.note]);
      }
      
      final linkValueRange = sheets.ValueRange(values: linkRows);
      await sheetsApi.spreadsheets.values.update(
        linkValueRange,
        spreadsheetId,
        'Links!A1',
        valueInputOption: 'USER_ENTERED',
      );

    } catch (e) {
      debugPrint('Upload Sync Error: $e');
      rethrow;
    }
  }

  /// Pulls data from Google Sheet and restores to local Hive database
  static Future<void> fetchFromGoogleSheets() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) throw Exception("Sign in aborted");

      final authHeaders = await account.authHeaders;
      final authClient = GoogleAuthClient(authHeaders);
      
      final driveApi = drive.DriveApi(authClient);
      final sheetsApi = sheets.SheetsApi(authClient);

      // Find the file
      final query = "name = 'Linku_Database' and mimeType = 'application/vnd.google-apps.spreadsheet' and trashed = false";
      final fileList = await driveApi.files.list(q: query, spaces: 'drive');
      
      if (fileList.files == null || fileList.files!.isEmpty) {
        throw Exception("No Google Sheet backup found. Please sync first.");
      }
      
      final spreadsheetId = fileList.files!.first.id!;

      // Fetch Groups
      final groupsData = await sheetsApi.spreadsheets.values.get(spreadsheetId, 'Groups!A:C');
      if (groupsData.values != null && groupsData.values!.length > 1) {
        await DbService.groupsBox.clear();
        for (int i = 1; i < groupsData.values!.length; i++) {
          final row = groupsData.values![i];
          if (row.length < 3) continue;
          final g = Group(
            id: row[0].toString(),
            name: row[1].toString(),
            createdAt: DateTime.tryParse(row[2].toString()) ?? DateTime.now(),
          );
          await DbService.groupsBox.put(g.id, g);
        }
      }

      // Fetch Links
      final linksData = await sheetsApi.spreadsheets.values.get(spreadsheetId, 'Links!A:G');
      if (linksData.values != null && linksData.values!.length > 1) {
        await DbService.linksBox.clear();
        for (int i = 1; i < linksData.values!.length; i++) {
          final row = linksData.values![i];
          if (row.length < 6) continue;
          final l = SavedLink(
            id: row[0].toString(),
            groupId: row[1].toString(),
            title: row[2].toString(),
            url: row[3].toString(),
            isFavorite: row[4].toString().toLowerCase() == 'true',
            createdAt: DateTime.tryParse(row[5].toString()) ?? DateTime.now(),
            note: row.length > 6 ? row[6].toString() : '',
          );
          await DbService.linksBox.put(l.id, l);
        }
      }

    } catch (e) {
      debugPrint('Download Sync Error: $e');
      rethrow;
    }
  }
}
