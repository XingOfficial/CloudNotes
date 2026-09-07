import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class StorageService {
  static const String _keyToken = 'token';
  static const String _keyUser = 'user';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? getToken() {
    return _prefs?.getString(_keyToken);
  }

  static Future<void> setToken(String? token) async {
    if (token == null) {
      await _prefs?.remove(_keyToken);
    } else {
      await _prefs?.setString(_keyToken, token);
    }
  }

  static AppUser? getUser() {
    final userStr = _prefs?.getString(_keyUser);
    if (userStr == null) return null;
    return AppUser.fromJson(jsonDecode(userStr));
  }

  static Future<void> setUser(AppUser? user) async {
    if (user == null) {
      await _prefs?.remove(_keyUser);
    } else {
      await _prefs?.setString(_keyUser, jsonEncode(user.toJson()));
    }
  }

  static Future<void> clear() async {
    await _prefs?.remove(_keyToken);
    await _prefs?.remove(_keyUser);
  }
}
