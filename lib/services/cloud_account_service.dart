import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'db_service.dart';
import '../models/saved_link.dart';

class CloudAccountService {
  static const String _authBoxName = 'cloud_account_settings';

  static String get defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:5000';
    return 'http://localhost:5000';
  }

  static Box get _box => Hive.box(_authBoxName);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_authBoxName)) {
      await Hive.openBox(_authBoxName);
    }
  }

  // --- Configuration ---
  static String get apiUrl => _box.get('api_url', defaultValue: defaultBaseUrl);
  static set apiUrl(String val) => _box.put('api_url', val.trim());

  static String? get token => _box.get('jwt_token');
  static String? get userEmail => _box.get('user_email');
  static String? get userName => _box.get('user_name');

  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  // --- Auth API ---
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final url = Uri.parse('$apiUrl/api/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'name': name ?? email.split('@')[0],
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        await _saveAuthData(data['token'], data['user']);
        return {'success': true, 'message': 'Account created successfully!'};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Cannot connect to server at $apiUrl ($e)'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$apiUrl/api/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _saveAuthData(data['token'], data['user']);
        return {'success': true, 'message': 'Logged in successfully!'};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Cannot connect to server at $apiUrl ($e)'};
    }
  }

  static Future<void> _saveAuthData(String jwt, Map<String, dynamic> user) async {
    await _box.put('jwt_token', jwt);
    await _box.put('user_email', user['email']);
    await _box.put('user_name', user['name'] ?? user['email'].split('@')[0]);
    DbService.activeUser = user['email'];
  }

  static Future<void> logout() async {
    await _box.delete('jwt_token');
    await _box.delete('user_email');
    await _box.delete('user_name');
  }

  // --- Bi-Directional Cloud Sync ---
  // Pulls links from Cloud (Extension/Web) and merges with App, and pushes local App links to Cloud!
  static Future<Map<String, dynamic>> syncNow() async {
    if (!isLoggedIn) {
      return {'success': false, 'error': 'Please log in to your MightyLink account first'};
    }

    try {
      final linksBox = DbService.linksBox;
      final localLinks = linksBox.values.toList();

      // Convert local links to JSON payload
      final localPayload = localLinks.map((link) => {
        'id': link.id,
        'title': link.title,
        'url': link.url,
        'workspace': link.groupId.isNotEmpty ? link.groupId : 'General',
        'notes': link.note,
        'isFavorite': link.isFavorite,
        'savedAt': link.createdAt.toIso8601String(),
      }).toList();

      // Batch Sync with Cloud API
      final url = Uri.parse('$apiUrl/api/sync');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'links': localPayload}),
      );

      if (response.statusCode != 200) {
        return {'success': false, 'error': 'Sync failed: ${response.body}'};
      }

      final data = jsonDecode(response.body);
      final List cloudLinks = data['links'] ?? [];

      // Update local Hive box with merged links from cloud
      for (final item in cloudLinks) {
        final id = item['id']?.toString() ?? 'bm_${DateTime.now().millisecondsSinceEpoch}';
        final title = item['title']?.toString() ?? 'Bookmark';
        final linkUrl = item['url']?.toString() ?? '';
        final note = item['notes']?.toString() ?? '';
        final workspace = item['workspace']?.toString() ?? 'General';
        final isFavorite = item['isFavorite'] == true;
        final createdAt = item['savedAt'] != null
            ? DateTime.tryParse(item['savedAt']) ?? DateTime.now()
            : DateTime.now();

        // Check if exists in local
        final existingIdx = localLinks.indexWhere((l) => l.id == id || l.url == linkUrl);
        if (existingIdx != -1) {
          final existing = localLinks[existingIdx];
          existing.title = title;
          existing.url = linkUrl;
          existing.note = note;
          existing.groupId = workspace;
          existing.isFavorite = isFavorite;
          await existing.save();
        } else {
          final newLink = SavedLink(
            id: id,
            title: title,
            url: linkUrl,
            note: note,
            groupId: workspace,
            isFavorite: isFavorite,
            createdAt: createdAt,
          );
          await linksBox.add(newLink);
        }
      }

      return {
        'success': true,
        'count': cloudLinks.length,
        'message': 'Synced ${cloudLinks.length} links with Cloud Account!',
      };
    } catch (e) {
      return {'success': false, 'error': 'Sync error: $e'};
    }
  }
}
