import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/scan_provider.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String _activeSubTab = 'personal'; // 'personal' | 'family' | 'settings' | 'help'

  // Personal Fields Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  String? _avatarBase64;
  bool _isSavingProfile = false;
  String _profileMsg = '';

  // Password Fields Controllers
  final _currPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  String _passwordMsg = '';

  // Family Fields Controllers
  final _familyNumberController = TextEditingController();
  String _familyMsg = '';

  // Help & Support Expandable FAQs State
  final Map<int, bool> _expandedFaqs = {};

  final List<Map<String, String>> _faqs = [
    {
      'q': 'How does KavachBot detect scams?',
      'a': 'Every message runs through a 4-tier detection engine — known scam-pattern matching, keyword analysis, behavioural signals (urgency, OTP requests, impersonation), and a final risk-scoring pass. You get a result in under 4 seconds.'
    },
    {
      'q': 'Is my data safe?',
      'a': 'Yes. Your messages are encrypted before they are stored, and only you (and authorised reviewers) can see your scan history. We follow DPDP Act 2023 data protection rules and keep all data within India.'
    },
    {
      'q': 'What should I do if I already paid a scammer?',
      'a': 'Act immediately — call the National Cybercrime Helpline 1930 or use the Emergency SOS tab. The faster you report, the higher the chance your bank can freeze the transaction.'
    },
    {
      'q': 'Why does my language selection not change the app text yet?',
      'a': 'KavachBot supports full translation and scam detection in Hindi, Telugu, Tamil, Kannada, Malayalam, Bengali, Marathi, and English.'
    },
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user != null) {
      _nameController.text = user.fullName ?? '';
      _mobileController.text = user.mobileNumber ?? '';
      _emailController.text = user.email ?? '';
      _avatarBase64 = user.profilePic;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _currPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _familyNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      if (bytes.length > 5 * 1024 * 1024) {
        setState(() {
          _profileMsg = 'Image file too large. Select file under 5MB.';
        });
        return;
      }
      setState(() {
        _avatarBase64 = 'data:image/jpeg;base64,${base64.encode(bytes)}';
        _profileMsg = '';
      });
    }
  }

  Future<void> _saveProfile(AuthProvider auth) async {
    setState(() {
      _isSavingProfile = true;
      _profileMsg = '';
    });
    try {
      await auth.updateProfile(
        fullName: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        profilePic: _avatarBase64,
      );
      setState(() {
        _isSavingProfile = false;
        _profileMsg = '✅ Profile updated successfully.';
      });
    } catch (e) {
      setState(() {
        _isSavingProfile = false;
        _profileMsg = '❌ ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  Future<void> _changePassword(AuthProvider auth) async {
    final curr = _currPasswordController.text.trim();
    final newPwd = _newPasswordController.text.trim();
    final conf = _confirmPasswordController.text.trim();

    if (curr.isEmpty || newPwd.isEmpty || conf.isEmpty) {
      setState(() => _passwordMsg = '❌ Fill in all password fields.');
      return;
    }

    if (newPwd != conf) {
      setState(() => _passwordMsg = '❌ New passwords do not match.');
      return;
    }

    if (newPwd.length < 8) {
      setState(() => _passwordMsg = '❌ Password must be at least 8 characters.');
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _passwordMsg = '';
    });

    try {
      await auth.changePassword(curr, newPwd);
      setState(() {
        _isChangingPassword = false;
        _passwordMsg = '✅ Password updated successfully.';
        _currPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } catch (e) {
      setState(() {
        _isChangingPassword = false;
        _passwordMsg = '❌ ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  void _addFamilyNumber(ScanProvider scanProvider) {
    setState(() => _familyMsg = '');
    final raw = _familyNumberController.text.replaceAll(RegExp(r'\D'), '');
    final normalised = raw.length == 10 ? '91$raw' : raw;

    if (normalised.length < 10 || normalised.length > 13) {
      setState(() => _familyMsg = '❌ Enter a valid 10-digit Indian mobile number.');
      return;
    }

    final currentNumbers = scanProvider.getFamilyNumbers();
    if (currentNumbers.contains(normalised)) {
      setState(() => _familyMsg = '❌ This number is already in your family list.');
      return;
    }

    if (currentNumbers.length >= 5) {
      setState(() => _familyMsg = '❌ You can save up to 5 family numbers.');
      return;
    }

    scanProvider.addFamilyNumber(normalised);
    _familyNumberController.clear();
    setState(() => _familyMsg = '✅ Family number added.');
  }

  void _deleteAccount(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Delete Account?'),
        content: const Text(
          'This action is irreversible. All your scan history, case reports, and payment details will be deleted permanently. Do you wish to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await auth.deleteAccount();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (_) {}
            },
            child: const Text('Delete Account', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final scanProvider = Provider.of<ScanProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
      child: Column(
      children: [
        // Sub-Tab Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.02),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 12),
                _buildSubTabButton('Personal Info', 'personal'),
                _buildSubTabButton('Family Alerts', 'family'),
                _buildSubTabButton('App Settings', 'settings'),
                _buildSubTabButton('Help & support', 'help'),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),

        // Main Tab Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: _buildSubTabContent(auth, scanProvider, themeProvider),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildSubTabButton(String label, String value) {
    final isSelected = _activeSubTab == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        onPressed: () => setState(() => _activeSubTab = value),
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.primaryColor : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildSubTabContent(AuthProvider auth, ScanProvider scan, ThemeProvider theme) {
    switch (_activeSubTab) {
      case 'personal':
        return _buildPersonalContent(auth);
      case 'family':
        return _buildFamilyContent(scan);
      case 'settings':
        return _buildSettingsContent(auth, theme);
      case 'help':
        return _buildHelpContent();
      default:
        return Container();
    }
  }

  Widget _buildPersonalContent(AuthProvider auth) {
    Uint8List? avatarBytes;
    if (_avatarBase64 != null && _avatarBase64!.contains('base64,')) {
      avatarBytes = base64.decode(_avatarBase64!.split('base64,')[1]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Avatar row
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: avatarBytes != null ? MemoryImage(avatarBytes) : null,
                child: avatarBytes == null 
                  ? const Text('👤', style: TextStyle(fontSize: 48)) 
                  : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  radius: 16,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    onPressed: _pickAvatar,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_profileMsg.isNotEmpty) ...[
          Text(
            _profileMsg,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 12),
        ],

        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email Address',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isSavingProfile ? null : () => _saveProfile(auth),
          child: _isSavingProfile 
            ? const CircularProgressIndicator(color: Colors.white) 
            : const Text('Save Profile Changes'),
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),

        // Change Password Section
        Text(
          'Security - Change Password',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_passwordMsg.isNotEmpty) ...[
          Text(
            _passwordMsg,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _currPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Current Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isChangingPassword ? null : () => _changePassword(auth),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
          child: _isChangingPassword 
            ? const CircularProgressIndicator(color: Colors.white) 
            : const Text('Update Password'),
        ),
      ],
    );
  }

  Widget _buildFamilyContent(ScanProvider scan) {
    final list = scan.getFamilyNumbers();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Family Alert Contacts',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Save up to 5 family contacts. In an emergency scan, tap "Alert Family" to instantly notify them on WhatsApp about detected threat scams.',
          style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 20),

        if (_familyMsg.isNotEmpty) ...[
          Text(
            _familyMsg,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 12),
        ],

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _familyNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Indian Mobile Number',
                  hintText: 'e.g. 9876543210',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _addFamilyNumber(scan),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(
              child: Text(
                'No family contacts saved yet.',
                style: TextStyle(color: Colors.black38),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final number = list[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Text('📞', style: TextStyle(fontSize: 20)),
                  title: Text(
                    number.startsWith('91') && number.length == 12
                      ? '+91 ${number.substring(2, 7)} ${number.substring(7)}'
                      : '+$number',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => scan.removeFamilyNumber(number),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSettingsContent(AuthProvider auth, ThemeProvider theme) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'App Configuration settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),

        // Dark mode switch
        SwitchListTile(
          value: theme.isDarkMode,
          onChanged: (val) => theme.toggleTheme(),
          title: Text(langProvider.translate('dark_mode'), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(langProvider.translate('dark_mode_desc')),
          secondary: const Text('🌓', style: TextStyle(fontSize: 24)),
          activeColor: AppTheme.primaryColor,
        ),
        const Divider(),

        // Language settings dropdown
        ListTile(
          leading: const Text('🌐', style: TextStyle(fontSize: 24)),
          title: Text(langProvider.translate('app_lang'), style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(langProvider.translate('select_lang')),
          trailing: DropdownButton<String>(
            value: langProvider.currentLanguage,
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'hi', child: Text('Hindi (हिन्दी)')),
              DropdownMenuItem(value: 'kn', child: Text('Kannada (ಕನ್ನಡ)')),
              DropdownMenuItem(value: 'ta', child: Text('Tamil (தமிழ்)')),
              DropdownMenuItem(value: 'te', child: Text('Telugu (తెలుగు)')),
              DropdownMenuItem(value: 'ml', child: Text('Malayalam (മലയാളം)')),
            ],
            onChanged: (val) {
              if (val != null) {
                langProvider.changeLanguage(val);
              }
            },
          ),
        ),
        const Divider(),
        const SizedBox(height: 48),

        // Delete Account button
        ElevatedButton(
          onPressed: () => _deleteAccount(auth),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(langProvider.translate('delete_account'), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildHelpContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        ...List.generate(_faqs.length, (index) {
          final faq = _faqs[index];
          final isExpanded = _expandedFaqs[index] ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ExpansionTile(
              initiallyExpanded: isExpanded,
              onExpansionChanged: (val) {
                setState(() {
                  _expandedFaqs[index] = val;
                });
              },
              title: Text(
                faq['q']!,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    faq['a']!,
                    style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black54),
                  ),
                )
              ],
            ),
          );
        }),
        const SizedBox(height: 32),
        const Center(
          child: Text(
            'App Version: 2.0.0 (Native Flutter)',
            style: TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
