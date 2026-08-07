import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class PremiumUpgradeView extends StatefulWidget {
  const PremiumUpgradeView({super.key});

  @override
  State<PremiumUpgradeView> createState() => _PremiumUpgradeViewState();
}

class _PremiumUpgradeViewState extends State<PremiumUpgradeView> {
  int _deviceCount = 1; // 1, 3, or 5
  bool _isAnnual = true;
  bool _isLoading = false;

  int _getPrice() {
    if (_deviceCount == 1) {
      return _isAnnual ? 499 : 49;
    } else if (_deviceCount == 3) {
      return _isAnnual ? 999 : 99;
    } else { // 5 devices
      return _isAnnual ? 1499 : 149;
    }
  }

  String _getPeriodText() {
    return _isAnnual ? '/ yr' : '/ mo';
  }

  String _getPlanTitle() {
    final devText = _deviceCount == 1 ? '1 Device' : '$_deviceCount Devices';
    final billingText = _isAnnual ? 'Annually' : 'Monthly';
    return 'Kavach App Premium ($devText - $billingText)';
  }

  void _processMockPayment(AuthProvider auth) async {
    setState(() => _isLoading = true);
    
    try {
      // Simulate secure gateway validation delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Perform database upgrade sequence
      await auth.upgradeToPremium();
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Payment Successful'),
              ],
            ),
            content: Text(
              'Your account has been upgraded to ${_getPlanTitle()} successfully! Welcome to premium digital safety.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upgrade failed: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF0D1F5C);
    final accentColor = const Color(0xFFF26522);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/kavachbot_app_icon.jpg',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upgrade to Kavach App Premium',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1F5C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Protect your digital footprints. Choose a plan tailored to your devices and stay safe from scams.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              // ── 1. SELECT DEVICE COUNT ──
              const Text(
                'Select Number of Devices',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1F5C),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildDevicePill(1, '1 Device')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDevicePill(3, '3 Devices')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDevicePill(5, '5 Devices')),
                ],
              ),
              const SizedBox(height: 24),

              // ── 2. SELECT BILLING CYCLE ──
              const Text(
                'Select Billing Option',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1F5C),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildBillingCard(
                      title: 'Monthly Billing',
                      price: _deviceCount == 1 ? '₹49' : (_deviceCount == 3 ? '₹99' : '₹149'),
                      period: '/ mo',
                      isSelected: !_isAnnual,
                      onTap: () => setState(() => _isAnnual = false),
                      primaryColor: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBillingCard(
                      title: 'Yearly Billing',
                      price: _deviceCount == 1 ? '₹499' : (_deviceCount == 3 ? '₹999' : '₹1499'),
                      period: '/ yr',
                      isSelected: _isAnnual,
                      badge: 'SAVE ~15%',
                      onTap: () => setState(() => _isAnnual = true),
                      primaryColor: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── 3. FEATURES LIST ──
              const Text(
                'Premium Features Included',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1F5C),
                ),
              ),
              const SizedBox(height: 12),
              _buildFeatureRow('Multi-device Protection Coverage'),
              _buildFeatureRow('Unlimited Threat & Scam Scan Assessments'),
              _buildFeatureRow('Priority Real-time Database Access'),
              _buildFeatureRow('Automatic URL Phishing Shield Blocking'),
              _buildFeatureRow('Unlimited AI Cyber Assistant Conversations'),

              const SizedBox(height: 36),

              // ── 4. CHECKOUT BUTTON ──
              ElevatedButton(
                onPressed: _isLoading ? null : () => _processMockPayment(auth),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Proceed to Payment - ₹${_getPrice()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDevicePill(int count, String label) {
    final isSelected = _deviceCount == count;
    final primaryColor = const Color(0xFF0D1F5C);
    
    return GestureDetector(
      onTap: () => setState(() => _deviceCount = count),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: primaryColor.withOpacity(0.15), blurRadius: 6, spreadRadius: 1)]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildBillingCard({
    required String title,
    required String price,
    required String period,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: primaryColor.withOpacity(0.08), blurRadius: 8, spreadRadius: 1)]
              : [],
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF26522),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? primaryColor : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFFF26522), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
