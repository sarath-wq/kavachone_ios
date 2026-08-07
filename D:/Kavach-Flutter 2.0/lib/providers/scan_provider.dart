import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/scan_result.dart';
import '../services/api_service.dart';
import '../core/utils/local_storage.dart';

class ScanProvider extends ChangeNotifier {
  final ApiService _api;
  final LocalStorage _storage = LocalStorage();

  ScanProvider({ApiService? api}) : _api = api ?? ApiService();

  List<ScanResult> _allScans = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  // Scan statistics metrics
  int totalScans = 0;
  int dangerCount = 0;
  int safeCount = 0;
  int phishingCount = 0;
  int upiCount = 0;
  int callCount = 0;
  int qrCount = 0;
  int fileCount = 0;

  List<ScanResult> get allScans => _allScans;
  List<ScanResult> get recentScans => _allScans.take(5).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  // ── Scans and History ──────────────────────────────────────────────────────

  Future<void> loadMyScans() async {
    try {
      final isAdmin = _storage.getRole() == 'admin';
      final list = await _api.getMyScans(pageSize: isAdmin ? 1000 : 50);
      _updateScanData(list);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  void _updateScanData(List<ScanResult> list) {
    _allScans = list;
    totalScans = list.length;
    
    dangerCount = list.where((s) => s.threatLevel == 'critical' || s.threatLevel == 'high').length;
    safeCount = list.where((s) => s.threatLevel == 'safe' || s.threatLevel == 'low').length;
    
    phishingCount = list.where((s) {
      final cat = (s.scamCategory ?? '').toLowerCase();
      return cat == 'phishing' || cat == 'smishing' || cat == 'job_fraud' || cat == 'lottery';
    }).length;

    upiCount = list.where((s) {
      final cat = (s.scamCategory ?? '').toLowerCase();
      final content = (s.rawContent ?? '').toLowerCase();
      return cat == 'financial_fraud' || content.contains('upi') || content.contains('paytm') || content.contains('gpay');
    }).length;

    callCount = list.where((s) {
      final chan = s.channel.toLowerCase();
      final cat = (s.scamCategory ?? '').toLowerCase();
      return chan == 'voip' || cat == 'vishing';
    }).length;

    qrCount = list.where((s) => s.channel.toLowerCase() == 'qr_code').length;

    fileCount = list.where((s) {
      final chan = s.channel.toLowerCase();
      return chan == 'file_upload' || chan == 'file_scan';
    }).length;

    notifyListeners();
  }

  // Polling management for auto-refresh statistics (every 5 seconds)
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final isAdmin = _storage.getRole() == 'admin';
        final list = await _api.getMyScans(pageSize: isAdmin ? 1000 : 50);
        _updateScanData(list);
      } catch (_) {}
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<ScanResult> scanMessage({
    required String channel,
    required String sourceIdentifier,
    required String rawContent,
  }) async {
    return await _runWithLoader(() async {
      final result = await _api.scanMessage(
        channel: channel,
        sourceIdentifier: sourceIdentifier,
        rawContent: rawContent,
      );
      await loadMyScans();
      return result;
    });
  }

  Future<Uint8List> downloadScanReport(String scanId) async {
    return await _runWithLoader(() async {
      return await _api.downloadScanReport(scanId);
    });
  }

  Future<Map<String, dynamic>> getDocuSignUrl(String scanId) async {
    return await _runWithLoader(() async {
      return await _api.getDocuSignUrl(scanId);
    });
  }

  // ── Scam reporting & SOS ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> fileScamReport({
    required String inputText,
    String? scamCategory,
    String? threatLevel,
    String? sourceChannel,
  }) async {
    return await _runWithLoader(() async {
      final res = await _api.fileScamReport(
        inputText: inputText,
        scamCategory: scamCategory,
        threatLevel: threatLevel,
        sourceChannel: sourceChannel,
      );
      return res;
    });
  }

  Future<void> blacklistNumber(String phoneNumber) async {
    try {
      await _api.blacklistNumber(phoneNumber);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> triggerSOSAlert() async {
    try {
      await _api.triggerSOSAlert();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // ── Files & QR scanning reputation ────────────────────────────────────────

  Future<Map<String, dynamic>> logApkScan({
    required String fileName,
    required int fileSize,
    required List<String> permissions,
    required List<dynamic> findings,
    required String overallRisk,
  }) async {
    return await _api.logApkScan(
      fileName: fileName,
      fileSize: fileSize,
      permissions: permissions,
      findings: findings,
      overallRisk: overallRisk,
    );
  }

  Future<Map<String, dynamic>> checkFileHash({
    required String fileName,
    required int fileSize,
    required String sha256,
  }) async {
    return await _api.checkFileHash(
      fileName: fileName,
      fileSize: fileSize,
      sha256: sha256,
    );
  }

  Future<Map<String, dynamic>> scanImageFile(Uint8List fileBytes, String filename) async {
    return await _runWithLoader(() async {
      final res = await _api.scanImageFile(fileBytes, filename);
      await loadMyScans();
      return res;
    });
  }

  // Family numbers local storage bindings
  List<String> getFamilyNumbers() => _storage.getFamilyNumbers();

  Future<void> addFamilyNumber(String number) async {
    await _storage.addFamilyNumber(number);
    notifyListeners();
  }

  Future<void> removeFamilyNumber(String number) async {
    await _storage.removeFamilyNumber(number);
    notifyListeners();
  }

  Future<Map<String, dynamic>> createBillingOrder(String plan) async {
    return await _api.createBillingOrder(plan);
  }

  Future<Map<String, dynamic>> verifyBillingPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    return await _api.verifyBillingPayment(
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
    );
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
