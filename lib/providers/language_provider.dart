import 'package:flutter/material.dart';
import '../core/utils/local_storage.dart';
import '../core/utils/translations.dart';

class LanguageProvider extends ChangeNotifier {
  final LocalStorage _storage = LocalStorage();
  late String _currentLanguage;

  LanguageProvider() {
    _currentLanguage = _storage.getLanguage();
  }

  String get currentLanguage => _currentLanguage;

  void changeLanguage(String code) {
    if (_currentLanguage == code) return;
    _currentLanguage = code;
    _storage.setLanguage(code);
    notifyListeners();
  }

  String translate(String key) {
    final Map<String, String> langData = Translations.data[_currentLanguage] ?? Translations.data['en']!;
    return langData[key] ?? Translations.data['en']![key] ?? key;
  }
}
