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
}
