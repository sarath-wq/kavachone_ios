import 'dart:convert';
import 'package:flutter/services.dart';

class CallScreeningService {
  static const _channel = MethodChannel('kavach/call_screening');

  /// Check if Call Screening role is held
  static Future<bool> isCallScreeningEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isCallScreeningEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if Draw Over Apps permission is granted
  static Future<bool> isOverlayEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isOverlayEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Request Call Screening Role via RoleManager dialog
  static Future<bool> requestCallScreeningRole() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestCallScreeningRole');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open Draw Over Apps settings for this app
  static Future<bool> requestOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestOverlayPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve intercepted call log from native SharedPreferences
  static Future<List<Map<String, dynamic>>> getCallLog() async {
    try {
      final raw = await _channel.invokeMethod<String>('getCallLog');
      if (raw == null || raw.isEmpty) return [];
      final arr = jsonDecode(raw) as List;
      return arr.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Clear call log
  static Future<void> clearCallLog() async {
    try {
      await _channel.invokeMethod('clearCallLog');
    } catch (_) {}
  }
}
