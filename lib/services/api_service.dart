import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/scan_result.dart';
import '../core/utils/local_storage.dart';

class ApiService {
  final LocalStorage _storage = LocalStorage();
  final http.Client client;

  ApiService({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Automatic token refresh on 401 ────────────────────────────────────────

  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.apiBase}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['access_token'] != null) {
          await _storage.setAccessToken(data['access_token']);
          if (data['refresh_token'] != null) {
            await _storage.setRefreshToken(data['refresh_token']);
          }
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // Generic request helper — auto-refreshes token on 401 and retries once
  Future<http.Response> _request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? extraHeaders,
  }) async {
    Future<http.Response> _fire(Map<String, String> headers) {
      final uri = Uri.parse('${ApiConstants.apiBase}$path');
      switch (method.toUpperCase()) {
        case 'POST':
          return client.post(uri, headers: headers, body: body != null ? json.encode(body) : null);
        case 'PATCH':
          return client.patch(uri, headers: headers, body: body != null ? json.encode(body) : null);
        case 'PUT':
          return client.put(uri, headers: headers, body: body != null ? json.encode(body) : null);
        case 'DELETE':
          return client.delete(uri, headers: headers);
        default: // GET
          return client.get(uri, headers: headers);
      }
    }

    var headers = await _headers();
    if (extraHeaders != null) headers = {...headers, ...extraHeaders};
    var response = await _fire(headers);

    // Auto-refresh and retry on 401 Unauthorized
    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        headers = await _headers();
        if (extraHeaders != null) headers = {...headers, ...extraHeaders};
        response = await _fire(headers);
      } else {
        // Refresh failed — clear session so app redirects to login
        await _storage.deleteAccessToken();
        await _storage.deleteRefreshToken();
        await _storage.deleteUser();
        throw Exception('{"error_code":"SESSION_EXPIRED","message":"Your session has expired. Please log in again."}');
      }
    }
    return response;
  }

  // ── Auth API ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCaptcha() async {
    final response = await client.get(Uri.parse('${ApiConstants.apiBase}/auth/captcha'));
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return json.decode(response.body);
    }
    throw Exception(response.body);
  }

  Future<Map<String, dynamic>> login(
    String identifier,
    String password,
    String captchaToken,
    String captchaAnswer,
  ) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': identifier,
        'password': password,
        'captcha_token': captchaToken,
        'captcha_answer': captchaAnswer,
      }),
    );
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      final data = json.decode(response.body);
      await _storage.setAccessToken(data['access_token']);
      await _storage.setRefreshToken(data['refresh_token']);
      return data;
    }
    throw Exception(response.body);
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String fullName,
    required String email,
    required String password,
    required String captchaToken,
    required String captchaAnswer,
    String? mobileNumber,
  }) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'full_name': fullName,
        'email': email,
        'password': password,
        'mobile_number': mobileNumber,
        'role': 'api_client',
        'captcha_token': captchaToken,
        'captcha_answer': captchaAnswer,
      }),
    );
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      final data = json.decode(response.body);
      await _storage.setAccessToken(data['access_token']);
      await _storage.setRefreshToken(data['refresh_token']);
      return data;
    }
    throw Exception(response.body);
  }

  Future<Map<String, dynamic>> forgotPassword(String email, String phoneNumber) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'phone_number': phoneNumber}),
    );
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return json.decode(response.body);
    }
    throw Exception(response.body);
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String phoneNumber, String otp) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'phone_number': phoneNumber, 'otp': otp}),
    );
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return json.decode(response.body);
    }
    throw Exception(response.body);
  }

  Future<Map<String, dynamic>> resetPasswordPublic(
    String email,
    String resetToken,
    String newPassword,
  ) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/auth/reset-password-public'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'reset_token': resetToken,
        'new_password': newPassword,
      }),
    );
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return json.decode(response.body);
    }
    throw Exception(response.body);
  }

  Future<Map<String, dynamic>> upgradeToPremium() async {
    final headers = await _headers();
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/auth/upgrade'),
      headers: headers,
      body: json.encode({}),
    );
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return json.decode(response.body);
    }
    throw Exception(response.body);
  }

  Future<Map<String, dynamic>> loadCurrentUser() async {
    final response = await _request('GET', '/auth/me');
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      final userMap = json.decode(response.body);
      await _storage.setUser(userMap);
      return userMap;
    }
    throw Exception(response.body);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _request('PATCH', '/auth/me', body: data);
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      final updatedUser = json.decode(response.body);
      await _storage.setUser(updatedUser);
      return updatedUser;
    }
    throw Exception(response.body);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final headers = await _headers();
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/auth/change-password'),
      headers: headers,
      body: json.encode({
        'old_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  Future<void> deleteAccount() async {
    final headers = await _headers();
    final response = await client.delete(
      Uri.parse('${ApiConstants.apiBase}/auth/me'),
      headers: headers,
    );
    if ((response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204)) {
      await _storage.clearAll();
      return;
    }
    throw Exception(response.body);
  }

  Future<void> saveConsent() async {
    final response = await _request('POST', '/auth/consent');
    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  // ── Scans API ──────────────────────────────────────────────────────────────

  Future<ScanResult> scanMessage({
    required String channel,
    required String sourceIdentifier,
    required String rawContent,
  }) async {
    final response = await _request('POST', '/scans', body: {
      'channel': channel,
      'source_identifier': sourceIdentifier,
      'raw_content': rawContent,
    });
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return ScanResult.fromJson(json.decode(response.body));
    }
    throw Exception(response.body);
  }

  Future<List<ScanResult>> getMyScans({int pageSize = 50}) async {
    final response = await _request('GET', '/scans?page_size=$pageSize');
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> items = data['items'] ?? [];
      return items.map((s) => ScanResult.fromJson(s)).toList();
    }
    throw Exception(response.body);
  }

  Future<Uint8List> downloadScanReport(String scanId) async {
    final token = await _storage.getAccessToken();
    final response = await client.get(
      Uri.parse('${ApiConstants.apiBase}/scans/$scanId/report.pdf'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return response.bodyBytes;
    }
    throw Exception('Failed to download report PDF');
  }

  Future<Map<String, dynamic>> getDocuSignUrl(String scanId) async {
    final headers = await _headers();
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/scans/$scanId/docusign'),
      headers: headers,
    );
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return json.decode(response.body);
    }
    throw Exception(response.body);
  }

  // ── Scam Reports ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fileScamReport({
    required String inputText,
    String? scamCategory,
    String? threatLevel,
    String? sourceChannel,
  }) async {
    final headers = await _headers();
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/scam-reports'),
      headers: headers,
      body: json.encode({
        'input_text': inputText,
        if (scamCategory != null) 'scam_category': scamCategory,
        if (threatLevel != null) 'threat_level': threatLevel,
        if (sourceChannel != null) 'source_channel': sourceChannel,
      }),
    );
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return json.decode(response.body);
    }
    throw Exception(response.body);
  }

  Future<List<dynamic>> getMyReports() async {
    final headers = await _headers();
    final response = await client.get(
      Uri.parse('${ApiConstants.apiBase}/scam-reports?page_size=20'),
      headers: headers,
    );
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return json.decode(response.body);
    }
    throw Exception(response.body);
  }

  // ── QR & Files API ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> logApkScan({
    required String fileName,
    required int fileSize,
    required List<String> permissions,
    required List<dynamic> findings,
    required String overallRisk,
  }) async {
    final headers = await _headers();
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/scans/apk-report'),
      headers: headers,
      body: json.encode({
        'file_name': fileName,
        'file_size_bytes': fileSize,
        'permissions': permissions,
        'findings': findings,
        'overall_risk': overallRisk,
      }),
    );
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return json.decode(response.body);
    }
    throw Exception(response.body);
  }

  Future<Map<String, dynamic>> checkFileHash({
    required String fileName,
    required int fileSize,
    required String sha256,
  }) async {
    final headers = await _headers();
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/scans/file-hash-check'),
      headers: headers,
      body: json.encode({
        'file_name': fileName,
        'file_size_bytes': fileSize,
        'sha256': sha256,
      }),
    );
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return json.decode(response.body);
    }
    throw Exception(response.body);
  }

  Future<Map<String, dynamic>> scanImageFile(Uint8List fileBytes, String filename) async {
    final token = await _storage.getAccessToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.apiBase}/scans/image'),
    );
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
      ),
    );

    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return json.decode(response.body);
    }
    throw Exception(response.body);
  }

  // ── Blacklist & SOS API ───────────────────────────────────────────────────

  Future<void> blacklistNumber(String phoneNumber) async {
    final headers = await _headers();
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/blacklist/numbers'),
      headers: headers,
      body: json.encode({
        'number': phoneNumber,
        'source': 'user_block',
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  Future<void> triggerSOSAlert() async {
    final headers = await _headers();
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/system/sos-alert'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  // ── Billing API ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createBillingOrder(String plan) async {
    final headers = await _headers();
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/billing/create-order'),
      headers: headers,
      body: json.encode({'plan': plan}),
    );
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return json.decode(response.body);
    }
    throw Exception(response.body);
  }

  Future<Map<String, dynamic>> verifyBillingPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final headers = await _headers();
    final response = await client.post(
      Uri.parse('${ApiConstants.apiBase}/billing/verify-payment'),
      headers: headers,
      body: json.encode({
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      }),
    );
    if ((response.statusCode == 200 || response.statusCode == 201)) {
      return json.decode(response.body);
    }
    throw Exception(response.body);
  }
}
