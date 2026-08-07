import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class CheckCallScreen extends StatefulWidget {
  const CheckCallScreen({super.key});

  @override
  State<CheckCallScreen> createState() => _CheckCallScreenState();
}

class _CheckCallScreenState extends State<CheckCallScreen> {
  final _numberController = TextEditingController();
  final _transcriptController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  bool get _canCheck => _numberController.text.trim().length >= 7;

  void _onCheck() {
    if (!_canCheck) return;
    
    final transcript = _transcriptController.text.trim().isEmpty
        ? 'No transcript provided — checking caller number only.'
        : _transcriptController.text.trim();

    // Navigates to chat bot screen passing parameters
    Navigator.pushNamed(
      context, 
      '/chat',
      arguments: {
        'text': transcript,
        'channel': 'voip',
        'callerNumber': _numberController.text.trim(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Call Log'),
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
            // Icon header
            const Center(
              child: Text('📞', style: TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 16),
            Text(
              'Verify suspicious callers',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check calls from unknown numbers claiming to be bank executives, CBI, post office, or lottery agents.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 32),

            // Number Input
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                if (_canCheck) _onCheck();
              },
              decoration: InputDecoration(
                labelText: 'Caller Mobile Number',
                hintText: 'e.g. 9876543210',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Transcript Input wrapped in KeyboardListener to capture physical Enter keys on Web/Desktop
            KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                  if (!HardwareKeyboard.instance.isShiftPressed) {
                    if (_canCheck) {
                      _onCheck();
                    }
                  }
                }
              },
              child: TextField(
                controller: _transcriptController,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (_canCheck) _onCheck();
                },
                decoration: InputDecoration(
                  labelText: 'What did the caller say? (Transcript)',
                  hintText: 'Paste what they said or summarize it (e.g. "They said my account is suspended and asked for OTP")',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _canCheck ? _onCheck : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Check Call for Scam', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            
            // Helper instructions
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
                        'Entering a transcript helps our 4-tier AI engine perform deep semantic analysis to detect digital arrest, lottery, or KYC phishing patterns.',
                        style: TextStyle(fontSize: 12, height: 1.4, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
