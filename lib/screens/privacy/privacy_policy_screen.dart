import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DigiKavach Privacy & Data Protection',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 12),
            Text(
              'Last Updated: July 2026',
              style: TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            
            Text(
              '1. Data Collection & Submissions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'KavachBot collects text messages, phone numbers, transaction parameters, and file metadata that you voluntarily submit for scanning. We only use this information to identify potential security threats, fraud, phishing links, and malware signatures.',
              style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 20),

            Text(
              '2. Compliance with DPDP Act 2023',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'In accordance with the Digital Personal Data Protection (DPDP) Act 2023 of India, we obtain explicit user consent before any scan processes. All user logs are hosted on secure database nodes within Indian territories. You retain the right to delete your profile log data permanently from our servers at any time.',
              style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 20),

            Text(
              '3. Storage Encryption & Security',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'All submission packets are encrypted in transit using SSL protocol and stored at rest using robust AES-256 standard encryption keys. Only authorized cyber threat reviewers can access blacklisted logs for verification checks. We never sell or share your personal scan logs with third-party advertising companies.',
              style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 32),
            Divider(),
            SizedBox(height: 20),
            Center(
              child: Text(
                'Digikavach Technologies Private Limited',
                style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 4),
            Center(
              child: Text(
                'support@digikavach.net',
                style: TextStyle(color: Colors.black38, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
