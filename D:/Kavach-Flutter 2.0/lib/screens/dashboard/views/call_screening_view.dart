import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/call_screening_service.dart';

// Brand colors matching Digikavach splash
const _navy = Color(0xFF0D1F5C);
const _orange = Color(0xFFF26522);
const _navyLight = Color(0xFF1A3A7A);
const _bgLight = Color(0xFFF5F7FA);

class CallScreeningView extends StatefulWidget {
  const CallScreeningView({super.key});

  @override
  State<CallScreeningView> createState() => _CallScreeningViewState();
}

class _CallScreeningViewState extends State<CallScreeningView>
    with SingleTickerProviderStateMixin {
  bool _screeningEnabled = false;
  bool _overlayEnabled = false;
  bool _loading = false;
  bool _enrichEnabled = true;
  List<Map<String, dynamic>> _callLog = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    if (kIsWeb) return; // Permissions only apply on Android
    final s = await CallScreeningService.isCallScreeningEnabled();
    final o = await CallScreeningService.isOverlayEnabled();
    final log = await CallScreeningService.getCallLog();
    if (mounted) {
      setState(() {
        _screeningEnabled = s;
        _overlayEnabled = o;
        _callLog = log;
      });
    }
  }

  Future<void> _onEnableAll() async {
    if (kIsWeb) {
      _showSnack('ℹ️ Call Screening only works on Android devices.');
      return;
    }
    setState(() => _loading = true);
    try {
      if (!_overlayEnabled) {
        await CallScreeningService.requestOverlayPermission();
        await Future.delayed(const Duration(milliseconds: 800));
      }
      if (!_screeningEnabled) {
        await CallScreeningService.requestCallScreeningRole();
        await Future.delayed(const Duration(milliseconds: 800));
      }
      await _refreshStatus();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clearLog() async {
    await CallScreeningService.clearCallLog();
    await _refreshStatus();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        backgroundColor: _navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool get _allEnabled => _screeningEnabled && _overlayEnabled;

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: CustomScrollView(
        slivers: [
          _buildHeroSliver(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatusCard(),
                const SizedBox(height: 16),
                _buildEnableButton(),
                const SizedBox(height: 16),
                _buildToggleCard(),
                const SizedBox(height: 16),
                _buildAnalysisModeCard(),
                const SizedBox(height: 4),
                _buildCallLogSection(),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSliver() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: _navy,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_navy, _navyLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background pattern
              Positioned.fill(
                child: CustomPaint(painter: _CircuitPainter()),
              ),
              // Hero image & text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Pulsing shield
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: _orange, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _orange.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: _orange,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Live Call Guardian',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Truecaller-style scam detection powered by Kavach AI',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status pill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: _allEnabled
                          ? const Color(0xFF22C55E).withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _allEnabled ? const Color(0xFF22C55E) : Colors.white30,
                      ),
                    ),
                    child: Text(
                      _allEnabled ? '🟢  ACTIVE — Protecting Every Call' : '🔴  Inactive — Tap to Enable',
                      style: GoogleFonts.outfit(
                        color: _allEnabled ? const Color(0xFF22C55E) : Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        title: Text(
          'Call Guardian',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12)],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Permission Status', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: _navy)),
          const SizedBox(height: 14),
          _permRow(
            icon: Icons.phone_in_talk,
            label: 'Call Screening Role',
            sub: 'Required to intercept calls (Android 10+)',
            granted: _screeningEnabled,
          ),
          const Divider(height: 20),
          _permRow(
            icon: Icons.layers,
            label: 'Draw Over Apps',
            sub: 'Shows overlay bubble over incoming calls',
            granted: _overlayEnabled,
          ),
          const Divider(height: 20),
          _permRow(
            icon: Icons.contacts_outlined,
            label: 'Contacts Access',
            sub: 'Skip API check for saved contacts (fast)',
            granted: true, // Requested at app start
          ),
        ],
      ),
    );
  }

  Widget _permRow({
    required IconData icon,
    required String label,
    required String sub,
    required bool granted,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: granted ? const Color(0xFF22C55E).withOpacity(0.1) : _orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: granted ? const Color(0xFF22C55E) : _orange, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _navy)),
              Text(sub, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Icon(
          granted ? Icons.check_circle : Icons.cancel_outlined,
          color: granted ? const Color(0xFF22C55E) : Colors.redAccent,
          size: 22,
        ),
      ],
    );
  }

  Widget _buildEnableButton() {
    return GestureDetector(
      onTap: _loading ? null : (_allEnabled ? null : _onEnableAll),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _allEnabled
                ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                : [_orange, const Color(0xFFE05A10)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_allEnabled ? const Color(0xFF22C55E) : _orange).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _allEnabled ? Icons.verified_user : Icons.touch_app,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _allEnabled
                          ? '✅  Call Screening Active'
                          : '🚀  Enable Call Screening',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildToggleCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _navy.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cell_tower, color: _navy, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Carrier & Country Info', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _navy)),
                Text('Show Numverify carrier data on overlay', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(
            value: _enrichEnabled,
            activeColor: _orange,
            onChanged: (v) => setState(() => _enrichEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisModeCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1F5C), Color(0xFF1A3A7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF0D1F5C).withOpacity(0.3), blurRadius: 12)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Color(0xFFF26522), size: 18),
              const SizedBox(width: 8),
              Text(
                '3-Layer Analysis Engine',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.5)),
                ),
                child: Text('ACTIVE', style: GoogleFonts.outfit(color: const Color(0xFF22C55E), fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _analysisLayerRow('⚡', 'Offline Engine', 'Instant pattern analysis — always works, zero API cost', true),
          const SizedBox(height: 8),
          _analysisLayerRow('📗', 'Contacts Check', 'Skip API for saved numbers — instant safe verdict', true),
          const SizedBox(height: 8),
          _analysisLayerRow('🌐', 'Numverify Enrichment', 'Carrier + country + line type — API key active ✓', true),
        ],
      ),
    );
  }

  Widget _analysisLayerRow(String icon, String title, String desc, bool active) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(desc, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ),
        Icon(
          active ? Icons.check_circle : Icons.radio_button_unchecked,
          color: active ? const Color(0xFF22C55E) : Colors.white38,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildCallLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📋  Intercepted Calls',
              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: _navy),
            ),
            if (_callLog.isNotEmpty)
              TextButton.icon(
                onPressed: _clearLog,
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                label: Text('Clear', style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_callLog.isEmpty)
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
            ),
            child: Column(
              children: [
                Icon(Icons.phone_missed, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                Text('No intercepted calls yet', style: GoogleFonts.outfit(color: Colors.grey.shade500)),
                Text('Enable screening and receive a call to see results here',
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade400), textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ...(_callLog.take(10).map((call) => _buildCallLogTile(call))),
      ],
    );
  }

  Widget _buildCallLogTile(Map<String, dynamic> call) {
    final risk = call['risk'] as String? ?? 'UNKNOWN';
    final score = call['score'] as int? ?? 0;
    final Color riskColor;
    final IconData riskIcon;

    switch (risk) {
      case 'SAFE':
        riskColor = const Color(0xFF22C55E);
        riskIcon = Icons.check_circle;
        break;
      case 'WARNING':
        riskColor = const Color(0xFFF59E0B);
        riskIcon = Icons.warning_amber;
        break;
      case 'SUSPICIOUS':
      case 'DANGER':
        riskColor = const Color(0xFFEF4444);
        riskIcon = Icons.report;
        break;
      default:
        riskColor = Colors.blueGrey;
        riskIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: riskColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(riskIcon, color: riskColor, size: 22),
        ),
        title: Text(
          call['number'] ?? 'Unknown',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: _navy),
        ),
        subtitle: Text(
          call['name'] != null && call['name'] != 'Unknown' ? call['name'] : call['time'] ?? '',
          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(risk, style: GoogleFonts.outfit(fontSize: 10, color: riskColor, fontWeight: FontWeight.w700)),
            ),
            if (score > 0) ...[
              const SizedBox(height: 3),
              Text('$score/100', style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ],
        ),
      ),
    );
  }
}

// Custom painter for the circuit-board hero background
class _CircuitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      final x = size.width * (i / 8);
      canvas.drawLine(Offset(x, 0), Offset(x + 40, size.height), paint);
    }
    for (int i = 0; i < 5; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 20), paint);
    }

    final dotPaint = Paint()
      ..color = const Color(0xFFF26522).withOpacity(0.25)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      canvas.drawCircle(
        Offset(size.width * ((i * 37 + 30) % 100) / 100, size.height * ((i * 43 + 20) % 100) / 100),
        2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
