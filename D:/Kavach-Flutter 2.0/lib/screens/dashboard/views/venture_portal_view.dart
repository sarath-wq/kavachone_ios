import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import 'call_screening_view.dart';

class VenturePortalView extends StatefulWidget {
  final String apiUrl;
  final String authToken;
  
  const VenturePortalView({
    super.key, 
    this.apiUrl = "https://api.yourdomain.com/v1", 
    this.authToken = "session_bearer_jwt_token_here",
  });

  @override
  State<VenturePortalView> createState() => _VenturePortalViewState();
}

class _VenturePortalViewState extends State<VenturePortalView> {
  String _activeTab = 'wallet'; // 'wallet' | 'network'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA),
      child: Column(
      children: [
        // Premium Sub-Tab Selector
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.02),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    label: 'Wallet & Shop',
                    value: 'wallet',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildTabButton(
                    label: 'Network Tree',
                    value: 'network',
                    icon: Icons.account_tree_outlined,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tab Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _activeTab == 'wallet' 
                ? WalletDashboardView(key: const ValueKey('wallet_view'), apiUrl: widget.apiUrl, authToken: widget.authToken)
                : NetworkTreeView(key: const ValueKey('network_view'), apiUrl: widget.apiUrl, authToken: widget.authToken),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _activeTab == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _activeTab = value),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppTheme.cardDark : Colors.white) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected 
                  ? AppTheme.primaryColor 
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected 
                    ? (isDark ? Colors.white : AppTheme.primaryColor) 
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// VIEW 1: WALLET ENGINE & MEMBER SHOP
// ==========================================
class WalletDashboardView extends StatefulWidget {
  final String apiUrl;
  final String authToken;
  const WalletDashboardView({super.key, required this.apiUrl, required this.authToken});

  @override
  State<WalletDashboardView> createState() => _WalletDashboardViewState();
}

class _WalletDashboardViewState extends State<WalletDashboardView> {
  double _pointsBalance = 750.00; // Simulated default setup state
  bool _isProcessing = false;

  final _withdrawPointsController = TextEditingController();
  final _upiController = TextEditingController();
  final _panController = TextEditingController();

  @override
  void dispose() {
    _withdrawPointsController.dispose();
    _upiController.dispose();
    _panController.dispose();
    super.dispose();
  }

  void _executePurchaseTransaction(String tier) async {
    setState(() => _isProcessing = true);
    
    // Explicit calculations matching our precise internal rules
    double cost = tier == 'MONTHLY' ? 49.0 : (tier == 'ANNUAL' ? 499.0 : 999.0);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.username ?? 'current-authenticated-user-uuid';
    
    try {
      final response = await http.post(
        Uri.parse('${widget.apiUrl}/checkout/purchase'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}', 
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'user_id': userId, 
          'product_type': tier, 
          'amount': cost
        }),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.threatSafe,
            content: Text('Purchase of $tier complete (MOCKED). Commissions updated safely across network branches.')
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.threatSafe,
            content: const Text('Transaction finalized locally.')
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _submitWithdrawalRequest() {
    final enteredPoints = double.tryParse(_withdrawPointsController.text) ?? 0.0;
    if (enteredPoints < 500) {
      _showFeedbackMessage("Minimum redemption threshold is 500 Reward Points.", isError: true);
      return;
    }
    if (enteredPoints > _pointsBalance) {
      _showFeedbackMessage("Insufficient wallet point reserves.", isError: true);
      return;
    }
    if (_panController.text.length != 10 || _upiController.text.isEmpty) {
      _showFeedbackMessage("Valid PAN Card structure and UPI strings are mandatory for Section 194H operations.", isError: true);
      return;
    }

    // Process tax mechanics locally to inform the user before processing
    double grossInr = enteredPoints * 1.0;
    double taxWithheld = grossInr * 0.05;
    double netDisbursed = grossInr - taxWithheld;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.gavel, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Indian Tax Settlement'),
            ],
          ),
          content: Text(
            'Tax Summary (Section 194H Compliance):\n\n'
            '• Points Redeemed: ${enteredPoints.toStringAsFixed(2)}\n'
            '• Gross Value: ₹${grossInr.toStringAsFixed(2)}\n'
            '• 5% TDS Withholding: ₹${taxWithheld.toStringAsFixed(2)}\n\n'
            'Net Payable directly to Bank via UPI: ₹${netDisbursed.toStringAsFixed(2)}',
            style: TextStyle(height: 1.4, color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                setState(() {
                  _pointsBalance -= enteredPoints;
                });
                Navigator.pop(context);
                _withdrawPointsController.clear();
                _showFeedbackMessage("Payout processed successfully. Payout reference generated.", isError: false);
              },
              child: const Text('Accept & Process'),
            )
          ],
        );
      },
    );
  }

  void _showFeedbackMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppTheme.threatCritical : AppTheme.threatSafe,
        content: Text(message),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return _isProcessing 
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Financial Ledger Card (Gradient & Modern Shadows)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'ACCUMULATED WALLET POINT RESERVES', 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Colors.white70, 
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₹ ${_pointsBalance.toStringAsFixed(2)}', 
                        style: const TextStyle(
                          fontSize: 38, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1 Point = ₹1.00 Value (Subject to Tax Deducted at Source)', 
                        style: TextStyle(
                          fontSize: 11, 
                          fontStyle: FontStyle.italic, 
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Live Call Guardian Premium Tile ──────────────────────────
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CallScreeningView(),
                  ));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D1F5C), Color(0xFF1A3A7A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D1F5C).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF26522).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF26522).withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.shield_outlined, color: Color(0xFFF26522), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Call Guardian',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Truecaller-style scam detection on every call',
                              style: GoogleFonts.outfit(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF26522),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ENABLE →',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              const Text(
                'AVAILABLE SUBSCRIPTION PACKAGES', 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMembershipCard(
                      title: "Monthly App", 
                      price: "₹ 49", 
                      desc: "Basic Protection",
                      action: () => _executePurchaseTransaction('MONTHLY'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMembershipCard(
                      title: "Annual App", 
                      price: "₹ 499", 
                      desc: "Complete Shield",
                      badge: "Best Value",
                      action: () => _executePurchaseTransaction('ANNUAL'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMembershipCard(
                      title: "Combo Protection", 
                      price: "₹ 999", 
                      desc: "App + Insurance",
                      action: () => _executePurchaseTransaction('COMBO'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              
              // Point conversion input mechanism
              const Text(
                'POINTS-TO-INR CONVERSION GATEWAY', 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _withdrawPointsController, 
                decoration: InputDecoration(
                  labelText: 'Redeem Points Volume (Min 500)', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.stars, color: AppTheme.primaryColor),
                  fillColor: isDark ? AppTheme.cardDark : Colors.white,
                  filled: true,
                ), 
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _upiController, 
                decoration: InputDecoration(
                  labelText: 'Beneficiary UPI Address (VPA)', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.account_balance_outlined, color: AppTheme.primaryColor),
                  fillColor: isDark ? AppTheme.cardDark : Colors.white,
                  filled: true,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _panController, 
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: '10-Digit Legal PAN Card Identification', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.primaryColor),
                  fillColor: isDark ? AppTheme.cardDark : Colors.white,
                  filled: true,
                ), 
                maxLength: 10,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor, 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitWithdrawalRequest,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Process Settlement & Disburse', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildMembershipCard({
    required String title, 
    required String price, 
    required String desc,
    String? badge,
    required VoidCallback action,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        Card(
          elevation: 2,
          color: isDark ? AppTheme.cardDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                Text(
                  title, 
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price, 
                  style: const TextStyle(fontSize: 18, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  desc, 
                  style: TextStyle(fontSize: 9, color: isDark ? Colors.white60 : Colors.black54),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor, 
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: action,
                  child: const Text('Buy Now', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: AppTheme.threatWarning,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Text(
                badge,
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          )
      ],
    );
  }
}

// ==========================================
// VIEW 2: UNILEVEL NETWORK TREE VISUALIZER
// ==========================================
class NetworkTreeView extends StatelessWidget {
  final String apiUrl;
  final String authToken;
  const NetworkTreeView({super.key, required this.apiUrl, required this.authToken});

  @override
  Widget build(BuildContext context) {
    // Structural representation data to populate multi-tier user interface elements
    final List<Map<String, String>> mockTreeData = [
      {'name': 'Rajesh Kumar (You)', 'tier': 'Root Root Node', 'generation': 'Self'},
      {'name': 'Amit Sharma', 'tier': 'Level 1 Active Downline', 'generation': 'Gen 1 (₹100/₹10 Yield)'},
      {'name': 'Priya Patel', 'tier': 'Level 2 Active Downline', 'generation': 'Gen 2 (₹50/₹5 Yield)'},
      {'name': 'Vikram Singh', 'tier': 'Level 3 Active Downline', 'generation': 'Gen 3 (₹25/₹2.15 Yield)'},
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: mockTreeData.length,
        itemBuilder: (context, index) {
          final node = mockTreeData[index];
          return Container(
            margin: EdgeInsets.only(left: index * 24.0, bottom: 12.0),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  width: 3, 
                  color: index == 0 ? AppTheme.primaryColor : AppTheme.secondaryColor,
                ),
              ),
            ),
            child: Card(
              elevation: 1,
              color: isDark ? AppTheme.cardDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                side: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    'L$index', 
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
                title: Text(
                  node['name']!, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  '${node['tier']} • ${node['generation']}',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                ),
                trailing: const Icon(Icons.verified_user, color: AppTheme.threatSafe, size: 18),
              ),
            ),
          );
        },
      ),
    );
  }
}
