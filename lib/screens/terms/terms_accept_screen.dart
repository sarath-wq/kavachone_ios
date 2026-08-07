import 'package:flutter/material.dart';
import '../../core/utils/local_storage.dart';

class TermsAcceptScreen extends StatefulWidget {
  const TermsAcceptScreen({super.key});

  @override
  State<TermsAcceptScreen> createState() => _TermsAcceptScreenState();
}

class _TermsAcceptScreenState extends State<TermsAcceptScreen> {
  final LocalStorage _storage = LocalStorage();
  bool _accepted = false;

  Future<void> _onAccept() async {
    if (!_accepted) return;
    await _storage.setTermsAccepted(true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/permissions');
    }
  }

  void _onDecline() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _viewFullPrivacyPolicy() {
    Navigator.pushNamed(context, '/privacy');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Icon header
              Center(
                child: Text(
                  '📝',
                  style: const TextStyle(fontSize: 64),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Terms of Service & Privacy Agreement',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Scrollable Terms Text
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to KavachBot',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'KavachBot (Digikavach Technologies Private Limited) provides automated tools to help you identify potential scams, phishing links, fraudulent phone numbers, and malware. By using this application, you agree to our terms of service and consent to the data practices described herein.',
                          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Data Usage & Privacy',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We analyze message text, phone numbers, files, and links you submit to provide threat indicators. We follow the Digital Personal Data Protection (DPDP) Act 2023. Submissions are processed securely. Your scan history is private and accessible only via your account.',
                          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Limitations of Liability',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Our analysis uses advanced AI algorithms and public blacklists. While we strive for accuracy, threat detection cannot be 100% perfect. KavachBot does not guarantee that every scam will be identified, nor does it guarantee that a "SAFE" result is entirely free of risk. Always exercise caution when handling unsolicited requests for money or personal details.',
                          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // View Full Terms Link
              Center(
                child: TextButton(
                  onPressed: _viewFullPrivacyPolicy,
                  child: Text(
                    'Read Full Privacy Policy & Terms',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              
              // Acceptance Checkbox
              CheckboxListTile(
                value: _accepted,
                onChanged: (val) {
                  setState(() {
                    _accepted = val ?? false;
                  });
                },
                title: const Text(
                  'I agree to the Terms of Service & Privacy Policy',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onDecline,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _accepted ? _onAccept : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Accept & Continue',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
