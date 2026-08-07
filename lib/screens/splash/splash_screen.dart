import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

// Digikavach brand colors
const _navy   = Color(0xFF0D1F5C);
const _orange = Color(0xFFF26522);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double>  _fadeAnim;
  late final Animation<Offset>  _slideAnim;
  late final Animation<double>  _scaleAnim;
  late final Animation<double>  _progressAnim;

  @override
  void initState() {
    super.initState();

    // Fade in everything
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    // Slide up bottom content
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    // Pulse logo
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Progress bar animation
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward(),
        curve: Curves.easeInOut,
      ),
    );

    // Start sequence
    _fadeCtrl.forward().then((_) => _slideCtrl.forward());

    // Navigate after 3.5s
    Timer(const Duration(milliseconds: 3500), _routeUser);
  }

  Future<void> _routeUser() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SizedBox.expand(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Image.asset(
            'assets/images/kavachbot_splash.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

