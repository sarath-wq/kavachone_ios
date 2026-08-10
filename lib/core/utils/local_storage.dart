import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  late final SharedPreferences _prefs;
  final _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Secure Storage (Tokens) with SharedPreferences Fallback ───────────────

  Future<String?> _readSecure(String key) async {
    if (kIsWeb) {
      return _prefs.getString(key);
    }
    try {
      return await _secureStorage.read(key: key);
    } catch (_) {
      return _prefs.getString(key);
    }
  }

  Future<void> _writeSecure(String key, String value) async {
    if (kIsWeb) {
      await _prefs.setString(key, value);
      return;
    }
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {
      await _prefs.setString(key, value);
    }
  }

  Future<void> _deleteSecure(String key) async {
    if (kIsWeb) {
      await _prefs.remove(key);
      return;
    }
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {
      await _prefs.remove(key);
    }
  }

  Future<String?> getAccessToken() async {
    return await _readSecure(ApiConstants.tokenKey);
  }

  Future<void> setAccessToken(String? token) async {
    if (token != null) {
      await _writeSecure(ApiConstants.tokenKey, token);
    }
  }

  Future<void> deleteAccessToken() async {
    await _deleteSecure(ApiConstants.tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _readSecure(ApiConstants.refreshKey);
  }

  Future<void> setRefreshToken(String? token) async {
    if (token != null) {
      await _writeSecure(ApiConstants.refreshKey, token);
    }
  }

  Future<void> deleteRefreshToken() async {
    await _deleteSecure(ApiConstants.refreshKey);
  }

  // ── SharedPreferences (Metadata / Preferences) ─────────────────────────────

  String getLanguage() {
    return _prefs.getString(ApiConstants.languageKey) ?? 'en';
  }

  Future<void> setLanguage(String langCode) async {
    await _prefs.setString(ApiConstants.languageKey, langCode);
  }

  bool isOnboarded() {
    return _prefs.getBool(ApiConstants.onboardedKey) ?? false;
  }

  Future<void> setOnboarded(bool value) async {
    await _prefs.setBool(ApiConstants.onboardedKey, value);
  }

  bool isTermsAccepted() {
    return _prefs.getBool(ApiConstants.termsAcceptedKey) ?? false;
  }

  Future<void> setTermsAccepted(bool value) async {
    await _prefs.setBool(ApiConstants.termsAcceptedKey, value);
  }

  bool isPermissionsDone() {
    return _prefs.getBool(ApiConstants.permissionsDoneKey) ?? false;
  }

  Future<void> setPermissionsDone(bool value) async {
    await _prefs.setBool(ApiConstants.permissionsDoneKey, value);
  }

  bool isDarkMode() {
    return _prefs.getBool(ApiConstants.darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(ApiConstants.darkModeKey, value);
  }

  String? getRole() {
    return _prefs.getString(ApiConstants.roleKey);
  }

  Future<void> setRole(String role) async {
    await _prefs.setString(ApiConstants.roleKey, role);
  }

  Future<void> deleteRole() async {
    await _prefs.remove(ApiConstants.roleKey);
  }

  Map<String, dynamic>? getUser() {
    final userStr = _prefs.getString(ApiConstants.userKey);
    if (userStr != null) {
      try {
        return json.decode(userStr) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> setUser(Map<String, dynamic> userMap) async {
    await _prefs.setString(ApiConstants.userKey, json.encode(userMap));
    if (userMap['role'] != null) {
      await setRole(userMap['role']);
    }
  }

  Future<void> deleteUser() async {
    await _prefs.remove(ApiConstants.userKey);
    await deleteRole();
  }

  // ── Family Numbers ────────────────────────────────────────────────────────

  List<String> getFamilyNumbers() {
    final listStr = _prefs.getString(ApiConstants.familyNumbersKey);
    if (listStr != null) {
      try {
        final List<dynamic> decoded = json.decode(listStr);
        return decoded.map((e) => e.toString()).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  Future<void> setFamilyNumbers(List<String> numbers) async {
    await _prefs.setString(ApiConstants.familyNumbersKey, json.encode(numbers));
  }

  Future<void> addFamilyNumber(String number) async {
    final list = getFamilyNumbers();
    if (!list.contains(number)) {
      list.add(number);
      await setFamilyNumbers(list);
    }
  }

  Future<void> removeFamilyNumber(String number) async {
    final list = getFamilyNumbers();
    if (list.contains(number)) {
      list.remove(number);
      await setFamilyNumbers(list);
    }
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await deleteUser();
    await _prefs.remove(ApiConstants.termsAcceptedKey);
    await _prefs.remove(ApiConstants.permissionsDoneKey);
  }
}
