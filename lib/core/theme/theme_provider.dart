import 'package:flutter/material.dart';
import '../utils/local_storage.dart';

class ThemeProvider extends ChangeNotifier {
  final LocalStorage _storage = LocalStorage();
  late bool _isDarkMode;

  ThemeProvider() {
    _isDarkMode = _storage.isDarkMode();
  }

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _storage.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
}
