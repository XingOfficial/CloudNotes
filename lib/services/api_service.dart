import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'https://xingclouddisk.share.zrok.io/notes-api';
  static const String releaseApi = 'https://api.github.com/repos/XingOfficial/CloudNotes/releases/latest';

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$path'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> _get(String path, {Map<String, dynamic>? query}) async {
    var uri = Uri.parse('$baseUrl/$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query.map((k, v) => MapEntry(k, v.toString())));
    }
    final response = await http.get(
      uri,
      headers: _headers,
    ).timeout(const Duration(seconds: 20));
    return _parseResponse(response);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? '请求失败');
    }
    return data['data'] ?? {};
  }

  Future<void> sendCode(String email, {String purpose = 'login'}) async {
    await _post('send_code.php', {'email': email, 'purpose': purpose});
  }

  Future<Map<String, dynamic>> verifyCode(String email, String code, {String purpose = 'login', String nickname = ''}) async {
    final body = {'email': email, 'code': code, 'purpose': purpose};
    if (purpose == 'register') body['nickname'] = nickname;
    final data = await _post('verify_code.php', body);
    return data;
  }

  Future<List<Note>> getNotes({bool onlyFavorite = false, String? tag}) async {
    final query = <String, dynamic>{};
    if (onlyFavorite) query['only_favorite'] = 1;
    if (tag != null && tag.isNotEmpty) query['tag'] = tag;
    final data = await _get('notes_list.php', query: query.isEmpty ? null : query);
    final List<dynamic> notesJson = data['notes'] ?? [];
    return notesJson.map((e) => Note.fromJson(e)).toList();
  }

  Future<Note> createNote(String title, String content, {
    bool isFavorite = false,
    bool isPinned = false,
    List<String> tags = const [],
    String? reminderTime,
  }) async {
    final body = {
      'title': title,
      'content': content,
      'is_favorite': isFavorite ? 1 : 0,
      'is_pinned': isPinned ? 1 : 0,
      'tags': jsonEncode(tags),
      'reminder_time': reminderTime ?? '',
    };
    final data = await _post('notes_create.php', body);
    return Note.fromJson(data['note']);
  }

  Future<Note> updateNote(String id, {
    String? title,
    String? content,
    bool? isFavorite,
    bool? isPinned,
    List<String>? tags,
    String? reminderTime,
  }) async {
    final body = <String, dynamic>{'id': id};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (isFavorite != null) body['is_favorite'] = isFavorite ? 1 : 0;
    if (isPinned != null) body['is_pinned'] = isPinned ? 1 : 0;
    if (tags != null) body['tags'] = jsonEncode(tags);
    if (reminderTime != null) body['reminder_time'] = reminderTime;
    final data = await _post('notes_update.php', body);
    return Note.fromJson(data['note']);
  }

  Future<Note> toggleFavorite(String id) async {
    final data = await _post('notes_toggle_favorite.php', {'id': id});
    return Note.fromJson(data['note']);
  }

  Future<Note> togglePinned(String id) async {
    final data = await _post('notes_toggle_pinned.php', {'id': id});
    return Note.fromJson(data['note']);
  }

  Future<Note> duplicateNote(String id) async {
    final data = await _post('notes_duplicate.php', {'id': id});
    return Note.fromJson(data['note']);
  }

  Future<List<String>> getTags() async {
    final data = await _get('notes_tags.php');
    final List<dynamic> tagsJson = data['tags'] ?? [];
    return tagsJson.map((e) => e.toString()).toList();
  }

  Future<void> deleteNote(String id) async {
    await _post('notes_delete.php', {'id': id});
  }

  Future<Map<String, dynamic>?> checkUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(releaseApi),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
