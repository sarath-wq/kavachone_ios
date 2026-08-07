import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/local_storage.dart';
import 'providers/auth_provider.dart';
import 'providers/scan_provider.dart';
import 'providers/language_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/terms/terms_accept_screen.dart';
import 'screens/permissions/permissions_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/check/check_call_screen.dart';
import 'screens/scan/scan_qr_screen.dart';
import 'screens/scan/scan_file_screen.dart';
import 'screens/chat/kavach_bot_screen.dart';
import 'screens/privacy/privacy_policy_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Modern Edge-to-Edge System UI configuration for Android 15 compliance
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Show detailed error screen on-screen for any layout/render exceptions
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.bug_report_rounded, color: Colors.redAccent, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Kavach App Premium - Rendering Error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  details.exceptionAsString(),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 16),
                Text(
                  details.stack?.toString() ?? 'No stack trace available.',
                  style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };
  
  // Initialize Shared Preferences and Secure Storage
  final storage = LocalStorage();
  await storage.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const KavachApp(),
    ),
  );
}

class KavachApp extends StatelessWidget {
  const KavachApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Kavach App Premium',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/terms-accept': (context) => const TermsAcceptScreen(),
        '/permissions': (context) => const PermissionsScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/check-call': (context) => const CheckCallScreen(),
        '/scan-qr': (context) => const ScanQrScreen(),
        '/scan-file': (context) => const ScanFileScreen(),
        '/chat': (context) => const KavachBotScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
      },
    );
  }
}
