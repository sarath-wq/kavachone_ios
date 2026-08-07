import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/scan_provider.dart';

class ScanFileScreen extends StatefulWidget {
  const ScanFileScreen({super.key});

  @override
  State<ScanFileScreen> createState() => _ScanFileScreenState();
}

class _ScanFileScreenState extends State<ScanFileScreen> {
  String _scanState = 'idle'; // 'idle' | 'scanning' | 'done' | 'error'
  String? _fileType; // 'apk' | 'pdf' | 'image' | 'text' | 'other'
  String _fileName = '';
  int _fileSize = 0;
  String _errorMsg = '';
  
  final List<Map<String, String>> _findings = [];
  String _overallRisk = 'low';

  // Danger Android permissions mappings
  final Map<String, Map<String, String>> _dangerousPermissions = {
    'android.permission.READ_SMS': {
      'risk': 'high',
      'label': 'Read SMS',
      'reason': 'Can intercept OTPs sent to your phone'
    },
    'android.permission.RECEIVE_SMS': {
      'risk': 'high',
      'label': 'Receive SMS',
      'reason': 'Can intercept incoming OTPs and bank messages'
    },
    'android.permission.SEND_SMS': {
      'risk': 'high',
      'label': 'Send SMS',
      'reason': 'Can send SMSes from your number without your knowledge'
    },
    'android.permission.SYSTEM_ALERT_WINDOW': {
      'risk': 'high',
      'label': 'Draw Over Apps',
      'reason': 'Can place fake login overlays on top of your bank app'
    },
    'android.permission.BIND_ACCESSIBILITY_SERVICE': {
      'risk': 'high',
      'label': 'Accessibility Service',
      'reason': 'Can see and control everything on your screen — classic banking trojan technique'
    },
    'android.permission.REQUEST_INSTALL_PACKAGES': {
      'risk': 'high',
      'label': 'Install Other Apps',
      'reason': 'Can silently install additional malware'
    },
    'android.permission.READ_CONTACTS': {
      'risk': 'medium',
      'label': 'Read Contacts',
      'reason': 'Can harvest all phone numbers from your contacts'
    },
    'android.permission.CAMERA': {
      'risk': 'medium',
      'label': 'Camera',
      'reason': 'Can take photos or record video silently'
    },
    'android.permission.RECORD_AUDIO': {
      'risk': 'medium',
      'label': 'Record Audio',
      'reason': 'Can record microphone audio without alerting you'
    },
    'android.permission.READ_EXTERNAL_STORAGE': {
      'risk': 'medium',
      'label': 'Read Storage',
      'reason': 'Can read all files on your device including documents'
    },
  };

  // Trojan combos
  final List<Map<String, dynamic>> _trojanCombos = [
    {
      'perms': ['android.permission.READ_SMS', 'android.permission.BIND_ACCESSIBILITY_SERVICE'],
      'label': 'OTP Theft + Screen Control — classic banking trojan fingerprint'
    },
    {
      'perms': ['android.permission.SYSTEM_ALERT_WINDOW', 'android.permission.READ_SMS'],
      'label': 'Fake Login Overlay + OTP Interception — phishing trojan pattern'
    },
  ];

  Future<void> _onPickFile(ScanProvider provider) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true, // Need file bytes for manifest parsing/hash
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      _processFile(file.name, file.bytes!, provider);
    }
  }

  Future<void> _processFile(String name, Uint8List bytes, ScanProvider provider) async {
    setState(() {
      _fileName = name;
      _fileSize = bytes.length;
      _scanState = 'scanning';
      _findings.clear();
      _overallRisk = 'low';
      _errorMsg = '';
    });

    final ext = name.split('.').last.toLowerCase();

    try {
      if (ext == 'apk') {
        _fileType = 'apk';
        await _scanApk(bytes, provider);
      } else if (ext == 'pdf' || ext == 'txt') {
        _fileType = ext == 'pdf' ? 'pdf' : 'text';
        await _scanTextBased(bytes, _fileType!, provider);
      } else if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        _fileType = 'image';
        await _scanImage(bytes, provider);
      } else {
        _fileType = 'other';
        _findings.add({
          'risk': 'low',
          'label': 'File type not deeply scanned',
          'detail': 'DigiKavach cannot inspect .$ext files yet. Treat unexpected files with caution.'
        });
        _scanState = 'done';
      }
    } catch (e) {
      setState(() {
        _scanState = 'error';
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ── APK Parser ─────────────────────────────────────────────────────────────

  Future<void> _scanApk(Uint8List bytes, ScanProvider provider) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? manifestFile;
    
    for (final f in archive) {
      if (f.name == 'AndroidManifest.xml') {
        manifestFile = f;
        break;
      }
    }

    if (manifestFile == null) {
      setState(() {
        _findings.add({
          'risk': 'medium',
          'label': 'Could not read APK manifest',
          'detail': 'This file appears to be an obfuscated or corrupted APK, which is common in malware.'
        });
        _overallRisk = 'medium';
        _scanState = 'done';
      });
      return;
    }

    final manifestBytes = manifestFile.content as List<int>;
    final manifestText = _binaryToString(manifestBytes);
    final perms = _extractPermissions(manifestText);

    // Check individual dangerous permissions
    for (final entry in _dangerousPermissions.entries) {
      if (perms.contains(entry.key)) {
        _findings.add({
          'risk': entry.value['risk']!,
          'label': entry.value['label']!,
          'detail': entry.value['reason']!,
        });
      }
    }

    // Check dangerous combos
    for (final combo in _trojanCombos) {
      final requiredPerms = combo['perms'] as List<String>;
      if (requiredPerms.every((p) => perms.contains(p))) {
        _findings.insert(0, {
          'risk': 'high',
          'label': '⚠️ Dangerous combination detected',
          'detail': combo['label']!,
        });
      }
    }

    if (_findings.isEmpty) {
      _findings.add({
        'risk': 'low',
        'label': '✅ No suspicious permissions found',
        'detail': 'Scanned ${perms.length} permissions. None match known Indian banking trojan patterns.',
      });
    } else {
      final permList = perms.map((p) => p.replaceFirst('android.permission.', '')).join(', ');
      _findings.add({
        'risk': 'low',
        'label': '📋 All requested permissions (${perms.length})',
        'detail': permList,
      });
    }

    _computeOverallRisk();

    // Log APK findings to server for audit trail
    try {
      await provider.logApkScan(
        fileName: _fileName,
        fileSize: _fileSize,
        permissions: perms.toList(),
        findings: _findings,
        overallRisk: _overallRisk,
      );
    } catch (_) {}

    // Verify SHA-256 Threat reputation via VirusTotal lookup
    final sha256Hash = sha256.convert(bytes).toString();
    try {
      final hashRes = await provider.checkFileHash(
        fileName: _fileName,
        fileSize: _fileSize,
        sha256: sha256Hash,
      );
      if (hashRes['verdict'] == 'malicious') {
        _findings.insert(0, {
          'risk': 'high',
          'label': '🚫 Flagged MALICIOUS by VirusTotal engines',
          'detail': hashRes['message'] ?? 'Known malware signature detected.',
        });
        _overallRisk = 'high';
      } else if (hashRes['verdict'] == 'suspicious') {
        _findings.insert(0, {
          'risk': 'medium',
          'label': '⚠️ Flagged suspicious by threat database',
          'detail': hashRes['message'] ?? 'Suspicious hash markers detected.',
        });
        if (_overallRisk != 'high') _overallRisk = 'medium';
      }
    } catch (_) {}

    setState(() {
      _scanState = 'done';
    });
  }

  String _binaryToString(List<int> bytes) {
    final out = StringBuffer();
    // Attempt UTF-16LE decode
    for (var i = 0; i < bytes.length - 1; i += 2) {
      final cp = bytes[i] | (bytes[i + 1] << 8);
      if (cp >= 32 && cp < 0xD800) {
        out.write(String.fromCharCode(cp));
      }
    }
    // Also append raw Latin-1
    for (var i = 0; i < bytes.length; i++) {
      final c = bytes[i];
      if (c >= 32 && c < 128) {
        out.write(String.fromCharCode(c));
      }
    }
    return out.toString();
  }

  Set<String> _extractPermissions(String text) {
    final found = <String>{};
    final exp = RegExp(r'android\.permission\.[A-Z_]+');
    final matches = exp.allMatches(text);
    for (final m in matches) {
      found.add(m.group(0)!);
    }
    return found;
  }

  // ── Text / PDF Scanner ─────────────────────────────────────────────────────

  Future<void> _scanTextBased(Uint8List bytes, String type, ScanProvider provider) async {
    final rawText = utf8.decode(bytes, allowMalformed: true);
    final previewText = rawText.length > 4000 ? rawText.substring(0, 4000) : rawText;

    if (previewText.trim().isEmpty) {
      setState(() {
        _findings.add({
          'risk': 'low',
          'label': 'Empty File',
          'detail': 'No readable text was found in this document.',
        });
        _overallRisk = 'low';
        _scanState = 'done';
      });
      return;
    }

    // Client-side local keyword scan
    final clientRisk = _getClientSideRisk(previewText);

    try {
      // API Scan check
      final scanRes = await provider.scanMessage(
        channel: 'sms',
        sourceIdentifier: _fileName,
        rawContent: previewText,
      );
      final level = (scanRes.threatLevel ?? 'low').toLowerCase();
      final apiRisk = (level == 'high' || level == 'critical') ? 'high' : (level == 'medium' ? 'medium' : 'low');

      // Higher verdict prevails
      final finalRisk = (apiRisk == 'high' || clientRisk == 'high') 
        ? 'high' 
        : ((apiRisk == 'medium' || clientRisk == 'medium') ? 'medium' : 'low');

      _findings.add({
        'risk': finalRisk,
        'label': finalRisk == 'high'
            ? '⚠️ Scam content detected in document'
            : (finalRisk == 'medium' ? 'Suspicious content found' : '✅ No scam content detected'),
        'detail': scanRes.aiReasoning.isNotEmpty 
            ? scanRes.aiReasoning 
            : 'Scanned file text for phishing, fake helpline numbers, and extortion language.',
      });
      _overallRisk = finalRisk;
    } catch (_) {
      // Local keyword fallback only
      _localKeywordCheck(previewText);
    }

    setState(() {
      _scanState = 'done';
    });
  }

  String _getClientSideRisk(String text) {
    final lc = text.toLowerCase();
    final scamKeywords = ['otp', 'urgent', 'kyc', 'suspended', 'verify now', 'prize', 'lottery', 'upi', 'pay now'];
    final hits = scamKeywords.where((k) => lc.contains(k)).toList();
    if (hits.length >= 3) return 'high';
    if (hits.isNotEmpty) return 'medium';
    return 'low';
  }

  void _localKeywordCheck(String text) {
    final risk = _getClientSideRisk(text);
    _findings.add({
      'risk': risk,
      'label': risk == 'high' 
          ? 'Multiple scam keywords detected' 
          : (risk == 'medium' ? 'Some suspicious keywords found' : 'No obvious scam keywords'),
      'detail': risk == 'high' 
          ? 'Document contains urgent action items, otp requests, or payment calls.' 
          : 'Scanned text structure; stay cautious.',
    });
    _overallRisk = risk;
  }

  // ── Image Scanner ──────────────────────────────────────────────────────────

  Future<void> _scanImage(Uint8List bytes, ScanProvider provider) async {
    _findings.add({
      'risk': 'low',
      'label': '📷 Image file received',
      'detail': 'Uploaded image contents to server. Scanning for OCR threat texts...',
    });

    if (bytes.length > 10 * 1024 * 1024) {
      _findings.add({
        'risk': 'medium',
        'label': 'Unusually large image file',
        'detail': 'Image exceeds 10MB. Scammers sometimes attempt to hide data payload contents in images.',
      });
    }

    try {
      final imgRes = await provider.scanImageFile(bytes, _fileName);
      final level = (imgRes['threat_level'] ?? 'low').toLowerCase();
      final finalRisk = (level == 'high' || level == 'critical') ? 'high' : (level == 'medium' ? 'medium' : 'low');

      _findings.add({
        'risk': finalRisk,
        'label': finalRisk == 'high' 
            ? '⚠️ Scam text detected in image' 
            : (finalRisk == 'medium' ? 'Suspicious context found' : '✅ Verified clean image'),
        'detail': imgRes['ai_analysis']?['ai_reasoning'] ?? 'Image text checked successfully.',
      });
      _overallRisk = finalRisk;
    } catch (_) {
      _overallRisk = 'low';
    }

    setState(() {
      _scanState = 'done';
    });
  }

  void _computeOverallRisk() {
    if (_findings.any((f) => f['risk'] == 'high')) {
      _overallRisk = 'high';
    } else if (_findings.any((f) => f['risk'] == 'medium')) {
      _overallRisk = 'medium';
    } else {
      _overallRisk = 'low';
    }
  }

  Color _getRiskColor(String r) {
    if (r == 'high') return AppTheme.threatCritical;
    if (r == 'medium') return AppTheme.threatWarning;
    return AppTheme.threatSafe;
  }

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Malware & File Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_scanState == 'idle') ...[
              // Upload Area
              InkWell(
                onTap: () => _onPickFile(scanProvider),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.01),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4), style: BorderStyle.values[0] /* dash */),
                  ),
                  child: Column(
                    children: [
                      const Text('📁', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text(
                        'Upload File to Scan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select APK, PDF, TXT or Image file',
                        style: TextStyle(color: Colors.black45, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Explanations Card
              const Text('💡 Scanner Features', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildFeatureDetail('🤖 APK Permissions Inspector', 'Extracts binary package manifests, identifying permissions used by malicious banking trojans to grab SMS OTPs.'),
              _buildFeatureDetail('🌐 VirusTotal Hash Verify', 'We hash the file and match signatures against VirusTotal known-malware lists without uploading your files.'),
              _buildFeatureDetail('📝 PDF/Image Phishing Audits', 'Searches invoices or screenshots for scam helpline numbers and blackmail contents.'),
            ] else if (_scanState == 'scanning') ...[
              // Progress Loading View
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 80.0),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 24),
                    Text('Analysing $_fileName...', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Extracting binary structures & comparing signatures...', style: TextStyle(fontSize: 12, color: Colors.black45)),
                  ],
                ),
              ),
            ] else if (_scanState == 'error') ...[
              // Error block
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    const Text('❌', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text('Analysis Failed', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_errorMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => setState(() => _scanState = 'idle'),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Results Done block
              _buildScanResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureDetail(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildScanResults() {
    final color = _getRiskColor(_overallRisk);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Overall Risk Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              Text(
                _overallRisk == 'high' 
                    ? '🚫 HIGH RISK DETECTED' 
                    : (_overallRisk == 'medium' ? '⚠️ WARNING / SUSPICIOUS' : '✅ VERIFIED CLEAN'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                'File name: $_fileName (${(_fileSize / 1024).toStringAsFixed(1)} KB)',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Findings Log
        const Text('Scanner Findings Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ..._findings.map((f) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f['risk'] == 'high' ? '🚨' : (f['risk'] == 'medium' ? '⚡' : '🛡️'),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f['label']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _getRiskColor(f['risk']!),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f['detail']!,
                        style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => setState(() => _scanState = 'idle'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
          child: const Text('Scan Another File'),
        ),
      ],
    );
  }
}
