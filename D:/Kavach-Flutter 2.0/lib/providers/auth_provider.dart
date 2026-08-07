import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../core/utils/local_storage.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final LocalStorage _storage = LocalStorage();

  AuthProvider({ApiService? api}) : _api = api ?? ApiService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  Future<void> init() async {
    final cachedUser = _storage.getUser();
    if (cachedUser != null) {
      _user = UserModel.fromJson(cachedUser);
      notifyListeners();
    }
  }

  // Helper to run operations with loader
  Future<T> _runWithLoader<T>(Future<T> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await operation();
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login(String username, String password, String captchaToken, String captchaAnswer) async {
    await _runWithLoader(() async {
      await _api.login(username, password, captchaToken, captchaAnswer);
      await loadCurrentUser();
    });
  }

  Future<void> register({
    required String username,
    required String fullName,
    required String email,
    required String password,
    required String captchaToken,
    required String captchaAnswer,
    String? mobileNumber,
  }) async {
    await _runWithLoader(() async {
      await _api.register(
        username: username,
        fullName: fullName,
        email: email,
        password: password,
        mobileNumber: mobileNumber,
        captchaToken: captchaToken,
        captchaAnswer: captchaAnswer,
      );
      await loadCurrentUser();
    });
  }

  Future<void> loadCurrentUser() async {
    try {
      final userMap = await _api.loadCurrentUser();
      _user = UserModel.fromJson(userMap);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? mobileNumber,
    String? email,
    String? profilePic,
  }) async {
    await _runWithLoader(() async {
      final updated = await _api.updateProfile({
        'full_name': fullName,
        if (mobileNumber != null) 'mobile_number': mobileNumber,
        if (email != null && email != _user?.email) 'email': email,
        if (profilePic != null) 'profile_pic': profilePic,
      });
      _user = UserModel.fromJson(updated);
    });
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _runWithLoader(() async {
      await _api.changePassword(currentPassword, newPassword);
    });
  }

  Future<void> deleteAccount() async {
    await _runWithLoader(() async {
      await _api.deleteAccount();
      _user = null;
    });
  }

  Future<void> logout() async {
    await _storage.clearAll();
    _user = null;
    notifyListeners();
  }

  Future<void> upgradeToPremium() async {
    await _runWithLoader(() async {
      await _api.upgradeToPremium();
      await loadCurrentUser();
    });
  }
}
