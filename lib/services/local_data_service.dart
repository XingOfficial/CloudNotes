import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDataService {
  static late SharedPreferences _prefs;
  static const _favoritesKey = 'note_favorites';
  static const _pinnedKey = 'note_pinned';
  static const _tagsKey = 'note_tags';
  static const _remindersKey = 'note_reminders';
  static const _themeKey = 'app_theme';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ========== 收藏 ==========
  static Set<String> getFavorites() {
    final list = _prefs.getStringList(_favoritesKey) ?? [];
    return list.toSet();
  }

  static Future<void> toggleFavorite(String noteId) async {
    final favorites = getFavorites();
    if (favorites.contains(noteId)) {
      favorites.remove(noteId);
    } else {
      favorites.add(noteId);
    }
    await _prefs.setStringList(_favoritesKey, favorites.toList());
  }

  static bool isFavorite(String noteId) {
    return getFavorites().contains(noteId);
  }

  // ========== 置顶 ==========
  static Set<String> getPinned() {
    final list = _prefs.getStringList(_pinnedKey) ?? [];
    return list.toSet();
  }

  static Future<void> togglePinned(String noteId) async {
    final pinned = getPinned();
    if (pinned.contains(noteId)) {
      pinned.remove(noteId);
    } else {
      pinned.add(noteId);
    }
    await _prefs.setStringList(_pinnedKey, pinned.toList());
  }

  static bool isPinned(String noteId) {
    return getPinned().contains(noteId);
  }

  // ========== 标签 ==========
  static Map<String, List<String>> getAllTags() {
    final jsonStr = _prefs.getString(_tagsKey);
    if (jsonStr == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((k, v) => MapEntry(k, List<String>.from(v)));
  }

  static List<String> getTags(String noteId) {
    return getAllTags()[noteId] ?? [];
  }

  static Future<void> setTags(String noteId, List<String> tags) async {
    final all = getAllTags();
    if (tags.isEmpty) {
      all.remove(noteId);
    } else {
      all[noteId] = tags;
    }
    await _prefs.setString(_tagsKey, jsonEncode(all));
  }

  static List<String> getAllTagNames() {
    final all = getAllTags();
    final Set<String> tagSet = {};
    for (final tags in all.values) {
      tagSet.addAll(tags);
    }
    return tagSet.toList()..sort();
  }

  // ========== 提醒 ==========
  static Map<String, String> getAllReminders() {
    final jsonStr = _prefs.getString(_remindersKey);
    if (jsonStr == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  }

  static String? getReminder(String noteId) {
    return getAllReminders()[noteId];
  }

  static Future<void> setReminder(String noteId, String? dateTime) async {
    final all = getAllReminders();
    if (dateTime == null) {
      all.remove(noteId);
    } else {
      all[noteId] = dateTime;
    }
    await _prefs.setString(_remindersKey, jsonEncode(all));
  }

  // ========== 主题 ==========
  static bool isDarkMode() {
    return _prefs.getBool(_themeKey) ?? false;
  }

  static Future<void> setDarkMode(bool dark) async {
    await _prefs.setBool(_themeKey, dark);
  }

  // ========== 笔记缓存（离线查看） ==========
  static const _notesCacheKey = 'notes_cache';
  static const _notesCacheTimeKey = 'notes_cache_time';

  static List<Map<String, dynamic>> getNotesCache() {
    final jsonStr = _prefs.getString(_notesCacheKey);
    if (jsonStr == null) return [];
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  static DateTime? getNotesCacheTime() {
    final ts = _prefs.getInt(_notesCacheTimeKey);
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  static Future<void> saveNotesCache(List<Map<String, dynamic>> notes) async {
    await _prefs.setString(_notesCacheKey, jsonEncode(notes));
    await _prefs.setInt(_notesCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clearNotesCache() async {
    await _prefs.remove(_notesCacheKey);
    await _prefs.remove(_notesCacheTimeKey);
  }

  // ========== 编辑页字体大小 ==========
  static const _fontSizeKey = 'editor_font_size';

  static double getEditorFontSize() {
    return _prefs.getDouble(_fontSizeKey) ?? 16.0;
  }

  static Future<void> setEditorFontSize(double size) async {
    await _prefs.setDouble(_fontSizeKey, size);
  }

  // ========== 应用锁 PIN ==========
  static const _pinKey = 'app_pin';

  static String? getPin() {
    return _prefs.getString(_pinKey);
  }

  static bool hasPin() {
    final pin = getPin();
    return pin != null && pin.isNotEmpty;
  }

  static Future<void> setPin(String pin) async {
    await _prefs.setString(_pinKey, pin);
  }

  static Future<void> clearPin() async {
    await _prefs.remove(_pinKey);
  }

  static bool verifyPin(String pin) {
    return getPin() == pin;
  }

  // ========== 字数限制 ==========
  static const _maxCharsKey = 'max_note_chars';

  static int getMaxChars() {
    return _prefs.getInt(_maxCharsKey) ?? 10000;
  }

  static Future<void> setMaxChars(int chars) async {
    await _prefs.setInt(_maxCharsKey, chars);
  }
}
