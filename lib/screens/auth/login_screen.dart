import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'package:sms_autofill/sms_autofill.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login Form Controllers
  final _loginIdController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _showLoginPassword = false;

  // Register Form Controllers
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regMobileController = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _showRegPassword = false;

  // Captcha placeholders (accepted as-is by backend)
  final String _dummyToken = 'no-captcha';
  final String _dummyAnswer = '0';

  String _errorMsg = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _errorMsg = '';
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginIdController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regMobileController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final username = _loginIdController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMsg = 'Please enter your credentials.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.login(username, password, _dummyToken, _dummyAnswer);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        final msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.contains('401') || msg.contains('credentials')) {
          _errorMsg = 'Incorrect credentials. Try again.';
        } else {
          _errorMsg = msg;
        }
      });
    }
  }

  Future<void> _onRegister() async {
    final name = _regNameController.text.trim();
    final email = _regEmailController.text.trim();
    final mobile = _regMobileController.text.trim();
    final password = _regPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMsg = 'Please fill in all required fields.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMsg = 'Password must be at least 8 characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // Derive a safe username from the email
      final username = email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      
      await auth.register(
        username: username,
        fullName: name,
        email: email,
        password: password,
        mobileNumber: mobile.isEmpty ? null : mobile,
        captchaToken: _dummyToken,
        captchaAnswer: _dummyAnswer,
      );
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        final msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.contains('409')) {
          _errorMsg = 'Email already registered.';
        } else {
          _errorMsg = msg;
        }
      });
    }
  }

  void _showForgotPasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ForgotPasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                ? [const Color(0xFF0F172A), const Color(0xFF0B0F19)]
                : [const Color(0xFFEFF6FF), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  // Header Logo
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/kavachbot_app_icon.jpg',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Text(
                          '🛡️',
                          style: TextStyle(fontSize: 64),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KavachBot',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'AI-powered Security Shield',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Theme.of(context).primaryColor,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [
                        Tab(text: 'Login'),
                        Tab(text: 'Register'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMsg.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMsg,
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w500),
                      ),
                    ),

                  // Tab Forms
                  SizedBox(
                    height: 360,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Login Tab View
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _loginIdController,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _onLogin(),
                              decoration: InputDecoration(
                                labelText: 'Email or Username',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _loginPasswordController,
                              obscureText: !_showLoginPassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _onLogin(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_showLoginPassword ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _showLoginPassword = !_showLoginPassword),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _onLogin,
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white) 
                                : const Text('Login'),
                            ),
                          ],
                        ),

                        // Register Tab View
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _regNameController,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _onRegister(),
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _regEmailController,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _onRegister(),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: const Icon(Icons.mail_outline),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _regMobileController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _onRegister(),
                              decoration: InputDecoration(
                                labelText: 'Mobile Number (Optional)',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.contact_phone_outlined),
                                  tooltip: 'Google One Tap Autofill',
                                  onPressed: () async {
                                    final phone = await SmsAutoFill().hint;
                                    if (phone != null) {
                                      final clean = phone.replaceFirst('+91', '').replaceAll(RegExp(r'\D'), '');
                                      _regMobileController.text = clean;
                                    }
                                  },
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _regPasswordController,
                              obscureText: !_showRegPassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _onRegister(),
                              decoration: InputDecoration(
                                labelText: 'Password (min 8 chars)',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_showRegPassword ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _showRegPassword = !_showRegPassword),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _onRegister,
                              child: _isLoading 
                                ? const CircularProgressIndicator(color: Colors.white) 
                                : const Text('Register'),
                            ),
                          ],
                        ),
                      ],
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
}

// ── Forgot Password Sheet ────────────────────────────────────────────────────

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> with CodeAutoFill {
  final ApiService _api = ApiService();

  @override
  void codeUpdated() {
    if (code != null) {
      setState(() {
        _otpController.text = code!;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    listenForCode();
  }

  String _step = 'input'; // 'input' | 'otp' | 'reset'
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _otpDisplayCode = '';
  String _resetToken = '';
  String _sheetError = '';
  bool _sheetLoading = false;

  @override
  void dispose() {
    cancel();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onRequestOtp() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty || phone.isEmpty) {
      setState(() => _sheetError = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _sheetLoading = true;
      _sheetError = '';
    });

    try {
      final res = await _api.forgotPassword(email, phone);
      setState(() {
        _sheetLoading = false;
        _step = 'otp';
        _otpDisplayCode = res['code'] ?? '';
      });
    } catch (e) {
      setState(() {
        _sheetLoading = false;
        _sheetError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _onVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _sheetError = 'Please enter the verification code.');
      return;
    }

    setState(() {
      _sheetLoading = true;
      _sheetError = '';
    });

    try {
      final res = await _api.verifyOtp(_emailController.text.trim(), _phoneController.text.trim(), otp);
      setState(() {
        _sheetLoading = false;
        _step = 'reset';
        _resetToken = res['reset_token'] ?? '';
      });
    } catch (e) {
      setState(() {
        _sheetLoading = false;
        _sheetError = 'Invalid verification code.';
      });
    }
  }

  Future<void> _onResetPassword() async {
    final pwd = _passwordController.text.trim();
    final conf = _confirmController.text.trim();

    if (pwd.isEmpty || conf.isEmpty) {
      setState(() => _sheetError = 'Please enter both password fields.');
      return;
    }

    if (pwd != conf) {
      setState(() => _sheetError = 'Passwords do not match.');
      return;
    }

    setState(() {
      _sheetLoading = true;
      _sheetError = '';
    });

    try {
      await _api.resetPasswordPublic(_emailController.text.trim(), _resetToken, pwd);
      setState(() {
        _sheetLoading = false;
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Password reset successfully. Please log in.')),
        );
      }
    } catch (e) {
      setState(() {
        _sheetLoading = false;
        _sheetError = 'Password reset failed. Ensure it has uppercase, lowercase, and a digit.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Forgot Password',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_sheetError.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(_sheetError, style: TextStyle(color: Colors.red.shade900)),
            ),
            
          if (_step == 'input') ...[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Account Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Registered Mobile Number',
                prefixIcon: const Icon(Icons.phone_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.contact_phone_outlined),
                  tooltip: 'Google One Tap Autofill',
                  onPressed: () async {
                    final phone = await SmsAutoFill().hint;
                    if (phone != null) {
                      final clean = phone.replaceFirst('+91', '').replaceAll(RegExp(r'\D'), '');
                      _phoneController.text = clean;
                    }
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _sheetLoading ? null : _onRequestOtp,
              child: _sheetLoading ? const CircularProgressIndicator() : const Text('Send Reset OTP'),
            ),
          ] else if (_step == 'otp') ...[
            // In a real app we receive SMS, but backend returns the OTP code in response for testing
            if (_otpDisplayCode.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🔑 [Test Mock Code]: $_otpDisplayCode',
                  style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold),
                ),
              ),
            const Text(
              'Enter the verification code sent to your phone number via SMS.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'OTP Verification Code',
                prefixIcon: const Icon(Icons.key_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _sheetLoading ? null : _onVerifyOtp,
              child: _sheetLoading ? const CircularProgressIndicator() : const Text('Verify Code'),
            ),
          ] else if (_step == 'reset') ...[
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _sheetLoading ? null : _onResetPassword,
              child: _sheetLoading ? const CircularProgressIndicator() : const Text('Reset Password'),
            ),
          ],
        ],
      ),
    );
  }
}
