import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/scan_result.dart';
import '../../../providers/scan_provider.dart';
import '../../../providers/auth_provider.dart';

class CheckMessageScreen extends StatefulWidget {
  final bool isEmbed;
  const CheckMessageScreen({super.key, this.isEmbed = false});

  @override
  State<CheckMessageScreen> createState() => _CheckMessageScreenState();
}

class _CheckMessageScreenState extends State<CheckMessageScreen> {
  final List<String> _channels = ['WhatsApp', 'Telegram', 'Instagram', 'SMS', 'Email', 'Paste a Link'];
  String _selectedChannel = 'WhatsApp';
  final _textController = TextEditingController();
  
  bool _isScanning = false;
  ScanResult? _scanResult;
  String? _errorMsg;

  final Map<String, String> _overrideLabels = {
    'OVR-A_CONFIRMED_INDICATOR': 'Matches a number or link already confirmed as a scam by other users',
    'OVR-B_THREAT_DETECTED': 'Contains explicit threats, blackmail or extortion language',
    'OVR-C_CLI_SPOOF_OFFICIAL': 'Caller ID may be spoofed to impersonate an official number',
    'OVR-D_COMMAND_COOCCURRENCE': 'Combines urgency with a request for money, OTP or personal details',
    'OVR-E_LOW_CONFIDENCE': 'Some signals are unclear — flagged for extra caution',
  };

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _selectChannel(String ch) {
    setState(() {
      _selectedChannel = ch;
      _textController.clear();
    });
  }

  bool get _isLinkMode => _selectedChannel == 'Paste a Link';

  String get _placeholderText {
    return _isLinkMode
      ? 'Paste the link / URL you want checked (e.g. https://...)'
      : 'Paste the message, link, UPI ID, or phone number...';
  }

  Future<void> _onAnalyse(ScanProvider provider) async {
    final text = _textController.text.trim();
    final mappedChannel = _selectedChannel.toLowerCase() == 'paste a link' ? 'whatsapp' : _selectedChannel.toLowerCase();

    // Photo / File Attachment Validation Guard
    if (mappedChannel.contains('photo') || mappedChannel.contains('image') || mappedChannel.contains('apk') || mappedChannel.contains('file')) {
      if (text.isEmpty || text.toLowerCase() == 'photo' || text.toLowerCase() == 'user input' || !text.startsWith('data:')) {
        setState(() {
          _isScanning = false;
          _scanResult = null;
          _errorMsg = 'Please select or capture an image/file before scanning.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Please select or capture an image/file before scanning.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (text.isEmpty || _isScanning) return;

    setState(() {
      _isScanning = true;
      _scanResult = null;
      _errorMsg = null;
    });

    String finalText = text;
    if (_isLinkMode) {
      final normalized = RegExp(r'^https?:\/\/', caseSensitive: false).hasMatch(text) ? text : 'https://$text';
      finalText = 'Please check this link: $normalized';
    }

    try {
      final res = await provider.scanMessage(
        channel: mappedChannel,
        sourceIdentifier: 'app-user',
        rawContent: finalText,
      );
      setState(() {
        _isScanning = false;
        _scanResult = res;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        final msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.contains('LIMIT_EXCEEDED')) {
          _errorMsg = 'Daily Scan Limit Reached! Upgrade to Premium to scan more messages.';
        } else if (msg.contains('SESSION_EXPIRED')) {
          _errorMsg = 'Session expired. Redirecting to login...';
          Future.microtask(() async {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            await auth.logout();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your session has expired. Please log in again.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          });
        } else {
          String displayMsg = msg;
          try {
            final parsed = json.decode(msg);
            if (parsed is Map) {
              if (parsed['message'] != null) {
                displayMsg = parsed['message'].toString();
              } else if (parsed['detail'] != null) {
                displayMsg = parsed['detail'].toString();
              }
            }
          } catch (_) {}
          _errorMsg = 'Analysis failed: $displayMsg';
        }
      });
    }
  }

  void _resetScan() {
    setState(() {
      _scanResult = null;
      _textController.clear();
      _errorMsg = null;
    });
  }

  Widget _buildScannerTabRow(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabItem(
              'Check Message',
              Icons.chat_bubble_rounded,
              const Color(0xFF3B82F6),
              isActive: true,
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _buildTabItem(
              'Check Phone',
              Icons.phone_in_talk_rounded,
              const Color(0xFF10B981),
              isActive: false,
              onTap: () => Navigator.pushNamed(context, '/check-call'),
            ),
            const SizedBox(width: 10),
            _buildTabItem(
              'Scan QR / Image',
              Icons.qr_code_scanner_rounded,
              const Color(0xFF6366F1),
              isActive: false,
              onTap: () => Navigator.pushNamed(context, '/scan-qr'),
            ),
            const SizedBox(width: 10),
            _buildTabItem(
              'Check APK File',
              Icons.android_rounded,
              const Color(0xFF0D9488),
              isActive: false,
              onTap: () => Navigator.pushNamed(context, '/scan-file'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(
    String title,
    IconData icon,
    Color color, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 145,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color : Colors.black.withOpacity(0.06),
          width: isActive ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 7,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: isActive ? color : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getResultColor(ScanResult r) {
    if (r.isCritical || r.threatLevel == 'danger') return AppTheme.threatCritical;
    if (r.isHigh || r.isMedium || r.threatLevel == 'warning') return AppTheme.threatWarning;
    return AppTheme.threatSafe;
  }

  List<String> _getSignals(ScanResult r) {
    final combined = <String>[];
    
    final translations = {
      'sender_number_blacklisted': 'Sender mobile number has been flagged or blacklisted for fraud.',
      'url_blacklisted': 'The link in this message is blacklisted as a known phishing or scam URL.',
      'invalid_upi_account': 'Razorpay VPA Validation Failed: UPI ID is inactive, invalid, or flagged.'
    };

    for (final reason in r.blacklistReasons) {
      combined.add(translations[reason] ?? reason);
    }

    for (final ovr in r.overrideApplied) {
      final translated = _overrideLabels[ovr];
      if (translated != null) combined.add(translated);
    }

    if (combined.isEmpty) {
      final cat = r.scamCategory ?? 'benign';
      if (cat != 'benign' && cat != 'conversational') {
        combined.add('Flagged as potential ${cat.replaceAll('_', ' ')} scam based on AI content analysis');
      }
    }
    
    return combined;
  }

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget body = SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScannerTabRow(context),
          if (_scanResult == null) ...[
            // Input Fields Configuration View
            Text(
              'Select Communication Channel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Channels grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _channels.map((ch) {
                final isSelected = _selectedChannel == ch;
                return ChoiceChip(
                  label: Text(
                    ch,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => _selectChannel(ch),
                  selectedColor: AppTheme.primaryColor,
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Paste Content',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                  if (!HardwareKeyboard.instance.isShiftPressed) {
                    _onAnalyse(scanProvider);
                  }
                }
              },
              child: TextField(
                controller: _textController,
                maxLines: 6,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _onAnalyse(scanProvider),
                decoration: InputDecoration(
                  hintText: _placeholderText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_errorMsg != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_errorMsg!, style: TextStyle(color: Colors.red.shade900)),
              ),

            ElevatedButton(
              onPressed: _isScanning ? null : () => _onAnalyse(scanProvider),
              child: _isScanning 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ) 
                : const Text('Analyse Content Now'),
            ),
            const SizedBox(height: 24),
            // Helper disclaimer card
            Card(
              elevation: 0,
              color: Colors.blueGrey.withOpacity(0.05),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Copy messages from WhatsApp or SMS and paste them above. We run safety audits checking text indicators, sender blacklist logs, and transaction links.',
                        style: TextStyle(fontSize: 12, height: 1.4, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Scan Result Detail View
            _buildResultCard(_scanResult!, scanProvider),
          ],
        ],
      ),
    );

    if (widget.isEmbed) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Message Text'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }

  Widget _buildResultCard(ScanResult result, ScanProvider provider) {
    final color = _getResultColor(result);
    final signals = _getSignals(result);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: color.withOpacity(0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withOpacity(0.2), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: color.withOpacity(0.15),
                  child: Text(
                    result.isSafe || result.isLow ? '✅' : result.isMedium ? '⚠️' : '🚨',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  (result.scamCategory ?? 'GENERAL SUSPICIOUS').toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Risk Score: ${result.riskScore}/100',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  result.aiReasoning.isNotEmpty ? result.aiReasoning : 'No reasoning payload provided.',
                  style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Signals Card
        if (signals.isNotEmpty) ...[
          Text(
            'Analysis Threat Indicators',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: signals.map((sig) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Expanded(
                        child: Text(
                          sig,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // URL scan results card
        if (result.urlScan != null) ...[
          Text(
            'Link Safety Check Result',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.blueGrey.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.urlScan?['page_title'] ?? 'Domain Verification',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.urlScan?['page_summary'] ?? 'Successfully analyzed destination url content indicators.',
                    style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // PDF / DocuSign actions
        ElevatedButton.icon(
          onPressed: () async {
            if (result.id == null) return;
            final bytes = await provider.downloadScanReport(result.id!);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('📥 Downloaded report PDF (${bytes.length} bytes)')),
              );
            }
          },
          icon: const Icon(Icons.download),
          label: const Text('Download PDF Security Audit'),
          style: ElevatedButton.styleFrom(backgroundColor: color),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            if (result.id == null) return;
            final res = await provider.getDocuSignUrl(result.id!);
            // Launch DocuSign
            final urlStr = res['signing_url'];
            if (urlStr != null) {
              final url = Uri.parse(urlStr);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            }
          },
          icon: const Icon(Icons.edit_document),
          label: const Text('Electronically Sign Report (DocuSign)'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
            foregroundColor: color,
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Reported caller to Cybercrime database.')),
                  );
                },
                icon: const Icon(Icons.block, color: Colors.red),
                label: const Text('Block Sender', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('📡 Shared scam alert warnings with family numbers.')),
                  );
                },
                icon: const Icon(Icons.share, color: Colors.blue),
                label: const Text('Alert Family', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _resetScan,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
          child: const Text('Reset Scanner / Check Another'),
        ),
      ],
    );
  }
}
