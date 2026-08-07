import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/local_storage.dart';
import '../../providers/language_provider.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final LocalStorage _storage = LocalStorage();

  // Unified modules to enable
  bool _cameraEnabled = true;
  bool _notificationsEnabled = true;
  bool _storageEnabled = true;
  bool _locationEnabled = true;

  bool _isActivating = false;

  Future<void> _activateShield() async {
    setState(() {
      _isActivating = true;
    });

    // Simulate quick module registration/handshake
    await Future.delayed(const Duration(milliseconds: 600));

    // Save states to local storage
    await _storage.setPermissionsDone(true);
    await _storage.setOnboarded(true);
    await _storage.setTermsAccepted(true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Widget _buildModuleTile({
    required String icon,
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: value 
              ? const Color(0xFF028090).withOpacity(0.25) 
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)), 
          width: 1.5,
        ),
      ),
      color: value 
          ? const Color(0xFF028090).withOpacity(0.04) 
          : (isDark ? Colors.white.withOpacity(0.02) : Colors.white),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: value 
                    ? const Color(0xFF028090).withOpacity(0.12) 
                    : (isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF028090),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Container(
                constraints: BoxConstraints(maxWidth: isWide ? 450 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Shield Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF028090).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.gpp_maybe_rounded,
                          color: Color(0xFF028090),
                          size: 56,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Titles
                    Text(
                      langProvider.translate('permissions_title'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      langProvider.translate('permissions_desc'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Modules list
                    _buildModuleTile(
                      icon: '📷',
                      title: langProvider.translate('perm_camera_title'),
                      desc: langProvider.translate('perm_camera_desc'),
                      value: _cameraEnabled,
                      onChanged: (val) => setState(() => _cameraEnabled = val ?? false),
                    ),
                    _buildModuleTile(
                      icon: '🔔',
                      title: langProvider.translate('perm_noti_title'),
                      desc: langProvider.translate('perm_noti_desc'),
                      value: _notificationsEnabled,
                      onChanged: (val) => setState(() => _notificationsEnabled = val ?? false),
                    ),
                    _buildModuleTile(
                      icon: '📁',
                      title: langProvider.translate('perm_file_title'),
                      desc: langProvider.translate('perm_file_desc'),
                      value: _storageEnabled,
                      onChanged: (val) => setState(() => _storageEnabled = val ?? false),
                    ),
                    _buildModuleTile(
                      icon: '📍',
                      title: langProvider.translate('perm_loc_title'),
                      desc: langProvider.translate('perm_loc_desc'),
                      value: _locationEnabled,
                      onChanged: (val) => setState(() => _locationEnabled = val ?? false),
                    ),

                    const SizedBox(height: 24),

                    // Activate Button
                    ElevatedButton(
                      onPressed: _isActivating ? null : _activateShield,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF028090),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isActivating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              langProvider.translate('btn_activate'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
