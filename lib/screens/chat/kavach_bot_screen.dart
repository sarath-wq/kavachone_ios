import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/scan_result.dart';
import '../../../providers/scan_provider.dart';
import '../../../providers/auth_provider.dart';

class ChatMessage {
  final String type; // 'user' | 'bot' | 'result'
  final String? text;
  final ScanResult? result;
  final bool isLoading;
  bool showDetails;

  ChatMessage({
    required this.type,
    this.text,
    this.result,
    this.isLoading = false,
    this.showDetails = false,
  });
}

class KavachBotScreen extends StatefulWidget {
  const KavachBotScreen({super.key});

  @override
  State<KavachBotScreen> createState() => _KavachBotScreenState();
}

class _KavachBotScreenState extends State<KavachBotScreen> {
  final List<ChatMessage> _messages = [];
  final _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _selectedChannel = 'whatsapp';
  String? _callerNumber;
  bool _isCallCheck = false;

  final Map<String, String> _channelLabels = {
    'whatsapp': '💬 WhatsApp',
    'sms': '📱 SMS',
    'telegram': '✈️ Telegram',
    'email': '✉️ Email',
    'voip': '📞 Voice Call',
  };

  final Map<String, String> _overrideLabels = {
    'OVR-A_CONFIRMED_INDICATOR': 'Matches a number or link already confirmed as a scam by other users',
    'OVR-B_THREAT_DETECTED': 'Contains explicit threats, blackmail or extortion language',
    'OVR-C_CLI_SPOOF_OFFICIAL': 'Caller ID may be spoofed to impersonate an official number',
    'OVR-D_COMMAND_COOCCURRENCE': 'Combines urgency with a request for money, OTP or personal details',
    'OVR-E_LOW_CONFIDENCE': 'Some signals are unclear — flagged for extra caution',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChat();
    });
  }

  void _initChat() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final displayName = auth.user?.fullName ?? auth.user?.username ?? 'User';

    if (args != null) {
      final text = args['text'] as String?;
      final channel = args['channel'] as String? ?? 'whatsapp';
      _selectedChannel = channel;
      _callerNumber = args['callerNumber'] as String?;
      _isCallCheck = channel == 'voip';

      setState(() {
        _messages.add(ChatMessage(
          type: 'bot',
          text: _isCallCheck ? 'Checking this call log now...' : 'Hi $displayName! Checking caller logs now...',
        ));
      });

      if (text != null && text.isNotEmpty) {
        setState(() {
          _messages.add(ChatMessage(type: 'user', text: text));
        });
        _runScan(text);
      }
    } else {
      setState(() {
        _messages.add(ChatMessage(
          type: 'bot',
          text: 'Hi $displayName! This is KavachBot, how can I assist you today?',
        ));
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runScan(String text) async {
    final provider = Provider.of<ScanProvider>(context, listen: false);

    // Insert loading item
    setState(() {
      _messages.add(ChatMessage(type: 'bot', isLoading: true));
    });
    final loadingIdx = _messages.length - 1;
    _scrollToBottom();

    // Context prefix extraction
    final contextPrefix = _buildContextPrefix();
    final langInstruction = '[RESPOND_IN_LANGUAGE: English]\n';
    final rawContent = '$langInstruction$contextPrefix${text.trim()}';

    try {
      final result = await provider.scanMessage(
        channel: _isCallCheck ? 'voip' : _selectedChannel,
        sourceIdentifier: 'interactive-bot',
        rawContent: rawContent,
      );
      
      setState(() {
        _messages[loadingIdx] = ChatMessage(
          type: 'result',
          result: result,
          showDetails: false,
        );
      });
      _scrollToBottom();
    } catch (_) {
      setState(() {
        _messages[loadingIdx] = ChatMessage(
          type: 'bot',
          text: '⚠️ Threat analysis check failed. Please check your connectivity and try again.',
        );
      });
      _scrollToBottom();
    }
  }

  String _buildContextPrefix() {
    final reversed = _messages.reversed.toList();
    final lastResultMsg = reversed.firstWhere(
      (m) => m.type == 'result' && m.result != null,
      orElse: () => ChatMessage(type: 'none'),
    );

    if (lastResultMsg.type == 'none' || lastResultMsg.result == null) return '';

    final r = lastResultMsg.result!;
    final level = r.threatLevel ?? 'unknown';
    final cat = r.scamCategory ?? 'unknown';
    final score = r.riskScore;

    return '[Previous scan in this conversation: threat=$level, category=$cat, risk=$score/100]\n\n';
  }

  void _onSend() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(type: 'user', text: text));
    });
    _scrollToBottom();
    _runScan(text);
  }

  Color _getResultColor(ScanResult r) {
    if (r.isCritical || r.threatLevel == 'danger') return AppTheme.threatCritical;
    if (r.isHigh || r.isMedium || r.threatLevel == 'warning') return AppTheme.threatWarning;
    return AppTheme.threatSafe;
  }

  List<String> _getSignals(ScanResult r) {
    final combined = <String>[];
    final translations = {
      'sender_number_blacklisted': 'Sender mobile number has been blacklisted for fraud.',
      'url_blacklisted': 'The link in this message is blacklisted.',
      'invalid_upi_account': 'UPI ID is inactive, invalid, or flagged.'
    };

    for (final reason in r.blacklistReasons) {
      combined.add(translations[reason] ?? reason);
    }
    for (final ovr in r.overrideApplied) {
      final translated = _overrideLabels[ovr];
      if (translated != null) combined.add(translated);
    }
    return combined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KavachBot Assistant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Channel selector
          if (!_isCallCheck)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.02),
              child: Row(
                children: [
                  const Text('Channel: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedChannel,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    underline: const SizedBox(),
                    items: _channelLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedChannel = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

          // Messages View
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _onSend(),
                    decoration: InputDecoration(
                      hintText: 'Type your question or paste scam text...',
                      hintStyle: const TextStyle(fontSize: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _onSend,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (msg.type == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
          child: Text(
            msg.text ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      );
    }

    if (msg.isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor)),
          ),
        ),
      );
    }

    if (msg.type == 'bot') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Text(
            msg.text ?? '',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, height: 1.4),
          ),
        ),
      );
    }

    // result type
    final r = msg.result!;
    final color = _getResultColor(r);
    final text = r.chatResponse.isNotEmpty ? r.chatResponse : r.aiReasoning;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      r.isSafe || r.isLow ? '✅ SAFE VERDICT' : r.isMedium ? '⚠️ WARNING VERDICT' : '🚨 DANGER VERDICT',
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                    ),
                    const Spacer(),
                    Text('Risk: ${r.riskScore}/100', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  text,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                ),
              ],
            ),
          ),
          
          // Toggle detail button
          InkWell(
            onTap: () {
              setState(() {
                msg.showDetails = !msg.showDetails;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: color.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Technical Details & Actions', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                  Icon(msg.showDetails ? Icons.expand_less : Icons.expand_more, color: color, size: 20),
                ],
              ),
            ),
          ),

          if (msg.showDetails) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_getSignals(r).isNotEmpty) ...[
                    const Text('Warning Flags:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
                    const SizedBox(height: 4),
                    ..._getSignals(r).map((s) => Text('• $s', style: const TextStyle(fontSize: 12, color: Colors.black87))),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final provider = Provider.of<ScanProvider>(context, listen: false);
                            final bytes = await provider.downloadScanReport(r.id!);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('📥 Downloaded PDF Report (${bytes.length} bytes)')),
                              );
                            }
                          },
                          icon: const Icon(Icons.download, size: 14),
                          label: const Text('PDF report', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: color, padding: EdgeInsets.zero),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final provider = Provider.of<ScanProvider>(context, listen: false);
                            final res = await provider.getDocuSignUrl(r.id!);
                            if (res['signing_url'] != null) {
                              final url = Uri.parse(res['signing_url']);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          icon: const Icon(Icons.edit_document, size: 14),
                          label: const Text('DocuSign', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: color),
                            foregroundColor: color,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
