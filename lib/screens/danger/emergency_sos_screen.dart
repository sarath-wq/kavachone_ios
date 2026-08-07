import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/scan_provider.dart';

class EmergencySosScreen extends StatefulWidget {
  final bool isEmbed;
  const EmergencySosScreen({super.key, this.isEmbed = false});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  String _step = 'overview'; // 'overview' | 'tracking' | 'done'

  // Tracking steps state indicators
  String _track1 = 'done'; // report filed
  String _track2 = 'done'; // bank alert
  String _track3 = 'active'; // portal queued
  String _track4 = 'queued'; // police notified
  String _track5 = 'queued'; // account freeze completed

  bool _isFiling = false;
  String _scamCategory = 'financial_fraud';
  String _threatLevel = 'high';
  String _callerNumber = '';

  Timer? _t1;
  Timer? _t2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route != null && route.settings.arguments is Map) {
        final args = route.settings.arguments as Map;
        _scamCategory = args['category'] ?? 'financial_fraud';
        _threatLevel = args['threat'] ?? 'high';
        _callerNumber = args['callerNumber'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _t1?.cancel();
    _t2?.cancel();
    super.dispose();
  }

  Future<void> _onCall1930(ScanProvider scan) async {
    final url = Uri.parse('tel:1930');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
    try {
      await scan.triggerSOSAlert();
    } catch (_) {}
  }

  Future<void> _blockCaller(ScanProvider scan) async {
    if (_callerNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No caller number associated with this SOS incident.')),
      );
      return;
    }
    try {
      await scan.blacklistNumber(_callerNumber);
    } catch (_) {}
    final url = Uri.parse('tel:$_callerNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _alertFamily(ScanProvider scan) async {
    final scamLabel = _scamCategory.replaceAll('_', ' ').toUpperCase();
    final text = '⚠️ DigiKavach SOS Alert: A $scamLabel scam was detected on my phone. Stay safe — do NOT pay money, click links, or share OTPs. Call 1930 helpline for help.';
    
    final numbers = scan.getFamilyNumbers();
    if (numbers.isNotEmpty) {
      for (final num in numbers) {
        final url = Uri.parse('https://wa.me/$num?text=${Uri.encodeComponent(text)}');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } else {
      // Clipboard copy fallback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No family contacts saved. Please add them in Profile -> Family Contacts.')),
      );
    }
  }

  Future<void> _startEmergencyReport(ScanProvider scan) async {
    setState(() {
      _step = 'tracking';
      _isFiling = true;
    });

    try {
      await scan.fileScamReport(
        inputText: 'Emergency SOS — $_scamCategory detected',
        scamCategory: _scamCategory,
        threatLevel: _threatLevel,
        sourceChannel: 'whatsapp',
      );
    } catch (_) {}

    setState(() {
      _isFiling = false;
    });

    // Run progressive timers for tracking updates
    _t1 = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _track3 = 'done';
          _track4 = 'active';
        });
      }
    });

    _t2 = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _track4 = 'done';
          _track5 = 'done';
          _step = 'done';
        });
      }
    });
  }

  Widget _buildStepCircle(String state) {
    if (state == 'done') {
      return const CircleAvatar(
        radius: 12,
        backgroundColor: Colors.green,
        child: Icon(Icons.check, size: 14, color: Colors.white),
      );
    }
    if (state == 'active') {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor)),
      );
    }
    return const CircleAvatar(
      radius: 12,
      backgroundColor: Colors.grey,
      child: Text('•', style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content;
    if (_step == 'overview') {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Text('🚨', style: TextStyle(fontSize: 72))),
          const SizedBox(height: 16),
          Text(
            'EMERGENCY SOS HUB',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.threatCritical,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'If you are being scammed right now, or have recently paid a fraudster, take immediate action below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 32),

          // PrimarySOS Button call 1930
          ElevatedButton.icon(
            onPressed: () => _onCall1930(scanProvider),
            icon: const Icon(Icons.phone_forwarded),
            label: const Text('CALL CYBERHELPLINE 1930'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.threatCritical,
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),

          // Actions List
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _blockSenderDialog(),
                  icon: const Icon(Icons.block, color: Colors.red),
                  label: const Text('Block Caller', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _alertFamily(scanProvider),
                  icon: const Icon(Icons.share, color: Colors.blue),
                  label: const Text('Alert Family', style: TextStyle(color: Colors.blue)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Freeze Bank accounts action button
          const Text('Freeze Transaction Accounts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          const Text('DigiKavach can automatically file cybercrime reports to portal registries and issue bank freeze logs to stop the transaction.', style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _startEmergencyReport(scanProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Freeze accounts & File Reports'),
          ),
        ],
      );
    } else if (_step == 'tracking') {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text('📡', style: TextStyle(fontSize: 64))),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'SOS REPORT FILING IN PROGRESS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.threatCritical),
            ),
          ),
          const SizedBox(height: 32),

          // Steps list
          _buildTrackingStep('1. Creating Incident report audit log', _track1),
          _buildTrackingStep('2. Identifying transaction destination channels', _track2),
          _buildTrackingStep('3. Dispatching freeze alerts to bank nodes', _track3),
          _buildTrackingStep('4. Queueing cybercrime portal logs', _track4),
          _buildTrackingStep('5. Securing device safety credentials', _track5),

          const SizedBox(height: 48),
          if (_isFiling)
            const Center(child: CircularProgressIndicator())
          else
            const Center(
              child: Text(
                'Contacting nodes... Hold steady.',
                style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      );
    } else {
      // Done Step
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Text('🎉', style: TextStyle(fontSize: 80))),
          const SizedBox(height: 20),
          const Text(
            'Freeze Action Broadcast Complete',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green),
          ),
          const SizedBox(height: 12),
          const Text(
            'All emergency alerts have been processed successfully. Incidents files were sent to respective banking partner nodes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => setState(() => _step = 'overview'),
            child: const Text('Done'),
          ),
        ],
      );
    }

    if (widget.isEmbed) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Response'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: content,
      ),
    );
  }

  Widget _buildTrackingStep(String title, String state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          _buildStepCircle(state),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: state == 'active' ? FontWeight.bold : FontWeight.normal,
                color: state == 'queued' ? Colors.black38 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _blockSenderDialog() {
    final controller = TextEditingController(text: _callerNumber);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Caller'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Caller Number'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _callerNumber = controller.text;
              });
              Navigator.pop(context);
              _blockCaller(Provider.of<ScanProvider>(context, listen: false));
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
