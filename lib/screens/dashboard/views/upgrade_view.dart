import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/scan_provider.dart';

class UpgradeView extends StatefulWidget {
  const UpgradeView({super.key});

  @override
  State<UpgradeView> createState() => _UpgradeViewState();
}

class _UpgradeViewState extends State<UpgradeView> {
  String _selectedPlan = 'yearly'; // 'monthly' | 'yearly'
  bool _isProcessing = false;
  String _message = '';

  Future<void> _onUpgrade(AuthProvider auth, ScanProvider scan) async {
    setState(() {
      _isProcessing = true;
      _message = '';
    });

    try {
      // 1. Create order on backend
      final orderRes = await scan.createBillingOrder(_selectedPlan);
      final String orderId = orderRes['id'] ?? 'mock_order_123';

      if (!mounted) return;

      // 2. Present payment dialog (mocking Razorpay callback flow)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('💳 Complete Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('KavachBot Premium upgrade payment via Razorpay secure portal.'),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedPlan == 'yearly' ? 'Yearly Protection' : 'Monthly Protection'),
                subtitle: Text(_selectedPlan == 'yearly' ? '₹799 / Year (Save 33%)' : '₹99 / Month'),
                trailing: Text('Order ID: ${orderId.substring(0, 8)}', style: const TextStyle(fontSize: 10)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isProcessing = false;
                  _message = '❌ Payment cancelled by user.';
                });
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _verifyPayment(orderId, auth, scan);
              },
              child: const Text('Simulate Success Pay', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _message = '❌ Failed to initialize upgrade: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  Future<void> _verifyPayment(String orderId, AuthProvider auth, ScanProvider scan) async {
    try {
      // Generate mock signature/payment tokens representing Razorpay success response
      final verifyRes = await scan.verifyBillingPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        razorpaySignature: 'sig_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (verifyRes['success'] == true) {
        // Upgrade role in provider cache
        await auth.upgradeToPremium();
        setState(() {
          _isProcessing = false;
          _message = '🎉 Congratulations! Your KavachBot Premium features are now active.';
        });
      } else {
        setState(() {
          _isProcessing = false;
          _message = '❌ Payment verification failed: ${verifyRes['message'] ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _message = '❌ Verification error: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final scan = Provider.of<ScanProvider>(context);
    final user = auth.user;

    final isPremium = user?.role == 'premium' || user?.role == 'admin';

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Logo
          Center(
            child: Text(
              '💎',
              style: const TextStyle(fontSize: 64),
            ),
          ),
          const SizedBox(height: 12),
          
          if (isPremium) ...[
            Text(
              'Premium Active',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have full unlimited security scans, file reputation audits, and real-time helpline alerts active on your account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 32),
            _buildBenefitItem('🛡️', 'Unlimited Threat Scans', 'Analyze as many messages and links as you want.'),
            _buildBenefitItem('📁', 'Deep File Reputation Scan', 'Submit APKs & PDFs to VirusTotal engines directly.'),
            _buildBenefitItem('🚨', 'SOS Family Alerts Broadcast', 'Instantly push WhatsApp alerts to family contacts.'),
            _buildBenefitItem('📞', '24/7 Helpline integrations', 'Speedy shortcuts to verify caller logs & helpline lines.'),
          ] else ...[
            Text(
              'Upgrade to Premium',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Unlock advanced cyber protection features for you and your family.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 24),

            if (_message.isNotEmpty) ...[
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],

            // Pricing Options
            Row(
              children: [
                Expanded(
                  child: _buildPlanCard(
                    title: 'Monthly Protection',
                    price: '₹99',
                    period: '/ Month',
                    isSelected: _selectedPlan == 'monthly',
                    onTap: () => setState(() => _selectedPlan = 'monthly'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPlanCard(
                    title: 'Yearly Shield',
                    price: '₹799',
                    period: '/ Year',
                    isSelected: _selectedPlan == 'yearly',
                    badge: 'Save 33%',
                    onTap: () => setState(() => _selectedPlan = 'yearly'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Benefits List
            _buildBenefitItem('⚡', 'Unlimited AI scam checks (No daily caps)', 'Free users are capped at 5 daily scans.'),
            _buildBenefitItem('🛡️', 'Full APK manifest & malware scans', 'Inspect package permissions client-side.'),
            _buildBenefitItem('📡', 'Automatic family alert broadcasting', 'Keep your loved ones in the loop when scammed.'),
            
            const Spacer(),
            ElevatedButton(
              onPressed: _isProcessing ? null : () => _onUpgrade(auth, scan),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isProcessing 
                ? const CircularProgressIndicator(color: Colors.white) 
                : Text('Upgrade Now (${_selectedPlan == 'yearly' ? '₹799/Yr' : '₹99/Mo'})'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.black.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.threatSafe,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  period,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
