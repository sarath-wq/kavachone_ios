import '../../providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';
import '../check/check_message_screen.dart';
import '../danger/emergency_sos_screen.dart';
import 'views/home_view.dart';
import 'views/cases_view.dart';
import 'views/profile_view.dart';
import 'views/premium_upgrade_view.dart';

// ── Digikavach Brand Colors ──────────────────────────────────────────────────
const _navy      = Color(0xFF0D1F5C);
const _navyDark  = Color(0xFF081340);
const _orange    = Color(0xFFF26522);
const _white     = Colors.white;

// ── Nav items: icon (inactive), icon (active), label ────────────────────────
const _navItems = [
  (Icons.home_outlined,         Icons.home,              'home'),
  (Icons.search_outlined,       Icons.search,            'check'),
  (Icons.assignment_outlined,   Icons.assignment,        'history'),
  (Icons.warning_amber_outlined,Icons.warning_amber,     'sos'),
  (Icons.person_outline,        Icons.person,            'profile'),
  (Icons.workspace_premium_outlined, Icons.workspace_premium, 'upgrade'),
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      HomeView(onTabChange: _onTabChange),
      const CheckMessageScreen(isEmbed: true),
      const CasesView(),
      const EmergencySosScreen(isEmbed: true),
      const ProfileView(),
      const PremiumUpgradeView(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scanProvider = Provider.of<ScanProvider>(context, listen: false);
      scanProvider.loadMyScans();
      scanProvider.startPolling();
    });
  }

  @override
  void dispose() {
    Provider.of<ScanProvider>(context, listen: false).stopPolling();
    super.dispose();
  }

  void _onTabChange(int index) => setState(() => _currentIndex = index);

  void _onLogout(AuthProvider auth) async {
    await auth.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  // ── TOP HEADER BAR ─────────────────────────────────────────────────────────
  Widget _buildHeader(AuthProvider auth) {
    final lang = Provider.of<LanguageProvider>(context);

    return Container(
      color: const Color(0xFF02183B),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF02183B),
                border: Border(bottom: BorderSide(color: Color(0x1F2B4C5E), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, color: Color(0xFF008CA8), size: 30),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'KavachBot',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x1F008CA8),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF008CA8), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_user, color: Color(0xFF10B981), size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  lang.translate('shield_active'),
                                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _onLogout(auth),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0x1FFF5722),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFF5722), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lang.translate('logout').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.logout, color: Colors.white, size: 13),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── BOTTOM NAVIGATION BAR ──────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final lang = Provider.of<LanguageProvider>(context);

    return Container(
      color: _navyDark,
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF02183B),
                border: Border(top: BorderSide(color: Color(0x1F2B4C5E), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (i) {
                  final item = _navItems[i];
                  final isSelected = _currentIndex == i;
                  final translatedText = lang.translate(item.$3.toLowerCase());

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onTabChange(i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? item.$2 : item.$1,
                            color: isSelected ? const Color(0xFF008CA8) : const Color(0xFF94A3B8),
                            size: 22,
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              translatedText.toUpperCase(),
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? const Color(0xFF008CA8) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── SCAFFOLD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 768 ? 768.0 : screenWidth;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(auth),
          Expanded(
            child: Center(
              child: SizedBox(
                width: contentWidth,
                child: IndexedStack(
                  index: _currentIndex,
                  children: _views,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}
