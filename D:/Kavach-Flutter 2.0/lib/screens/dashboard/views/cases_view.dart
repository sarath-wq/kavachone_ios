import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/scan_result.dart';
import '../../../providers/scan_provider.dart';

class CasesView extends StatefulWidget {
  const CasesView({super.key});

  @override
  State<CasesView> createState() => _CasesViewState();
}

class _CasesViewState extends State<CasesView> {
  String _searchQuery = '';
  String _filter = 'all'; // 'all' | 'danger' | 'warning' | 'safe'
  final _searchController = TextEditingController();
  final Set<String> _expandedScanIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScanProvider>(context, listen: false).loadMyScans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleExpand(String? id) {
    if (id == null) return;
    setState(() {
      if (_expandedScanIds.contains(id)) {
        _expandedScanIds.remove(id);
      } else {
        _expandedScanIds.add(id);
      }
    });
  }

  List<ScanResult> _getFilteredScans(List<ScanResult> scans) {
    var items = scans;
    
    // Category Filter
    if (_filter != 'all') {
      items = items.where((s) {
        final level = (s.threatLevel ?? '').toLowerCase();
        if (_filter == 'danger') {
          return level == 'critical' || level == 'danger';
        } else if (_filter == 'warning') {
          return level == 'high' || level == 'medium';
        } else if (_filter == 'safe') {
          return level == 'safe' || level == 'low';
        }
        return true;
      }).toList();
    }

    // Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((s) {
        final content = (s.rawContent ?? '').toLowerCase();
        final cat = (s.scamCategory ?? '').toLowerCase();
        final chan = s.channel.toLowerCase();
        return content.contains(q) || cat.contains(q) || chan.contains(q);
      }).toList();
    }

    return items;
  }

  Color _getThreatColor(ScanResult s) {
    if (s.isCritical || s.threatLevel == 'danger') return AppTheme.threatCritical;
    if (s.isHigh || s.isMedium) return AppTheme.threatWarning;
    return AppTheme.threatSafe;
  }

  String _getThreatLabel(ScanResult s) {
    final lvl = s.threatLevel ?? 'SAFE';
    return lvl.toUpperCase();
  }

  String _getChannelEmoji(String channel) {
    switch (channel.toLowerCase()) {
      case 'whatsapp': return '💬';
      case 'telegram': return '✈️';
      case 'sms': return '📱';
      case 'email': return '✉️';
      case 'voip': return '📞';
      case 'qr_code': return '📷';
      case 'file_upload':
      case 'file_scan': return '📁';
      default: return '🛡️';
    }
  }

  Future<void> _downloadPdf(ScanResult scan, ScanProvider provider) async {
    if (scan.id == null) return;
    try {
      final bytes = await provider.downloadScanReport(scan.id!);
      // In a real app we'd save to disk or open. For now, simulate success:
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📥 Downloaded PDF report (${bytes.length} bytes) for Scan: ${scan.id!.substring(0, 8)}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Could not generate PDF report. Try again.')),
        );
      }
    }
  }

  Future<void> _signDocuSign(ScanResult scan, ScanProvider provider) async {
    if (scan.id == null) return;
    try {
      final res = await provider.getDocuSignUrl(scan.id!);
      if (res['success'] == true && res['signing_url'] != null) {
        final url = Uri.parse(res['signing_url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Failed to connect to DocuSign service.')),
        );
      }
    }
  }

  Future<void> _blacklistSender(ScanResult scan, ScanProvider provider) async {
    // In a real app we'd resolve sender entity from extractedEntities.
    final sender = scan.extractedEntities?['phone_numbers']?.first ?? 'Unknown';
    if (sender == 'Unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No caller number extracted from this threat scan.')),
      );
      return;
    }
    try {
      await provider.blacklistNumber(sender);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Blocked and reported sender: $sender')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);
    final scans = _getFilteredScans(scanProvider.allScans);

    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF5F7FA),
      child: Column(
      children: [
        // Search & Filter Box
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search cases, channels, categories...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
              // Filter Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFilterChip('All', 'all', Colors.blue),
                  _buildFilterChip('Danger', 'danger', AppTheme.threatCritical),
                  _buildFilterChip('Warning', 'warning', AppTheme.threatWarning),
                  _buildFilterChip('Safe', 'safe', AppTheme.threatSafe),
                ],
              ),
            ],
          ),
        ),

        // Cases List
        Expanded(
          child: scanProvider.isLoading && scanProvider.allScans.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : scans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty || _filter != 'all'
                          ? 'No matching scan results found.'
                          : 'No scan history yet.',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: scans.length,
                  itemBuilder: (context, index) {
                    final scan = scans[index];
                    final isExpanded = _expandedScanIds.contains(scan.id);
                    final color = _getThreatColor(scan);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              child: Text(
                                _getChannelEmoji(scan.channel),
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getThreatLabel(scan),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    (scan.scamCategory ?? 'General Scan').replaceAll('_', ' ').toUpperCase(),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                scan.rawContent ?? '',
                                maxLines: isExpanded ? 10 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                            ),
                            trailing: Icon(
                              isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.black38,
                            ),
                            onTap: () => _toggleExpand(scan.id),
                          ),
                          if (isExpanded) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // AI Reasoning
                                  const Text(
                                    'AI THREAT REASONING:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    scan.aiReasoning.isNotEmpty ? scan.aiReasoning : 'No reasoning payload provided.',
                                    style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                                  ),
                                  
                                  // Warnings list
                                  if (scan.overrideApplied.isNotEmpty || scan.blacklistReasons.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      'DETECTION SIGNALS:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 6),
                                    ...scan.blacklistReasons.map((r) => _buildSignalItem('🚫 Blacklisted: $r')),
                                    ...scan.overrideApplied.map((o) => _buildSignalItem('⚠️ Signal Flag: $o')),
                                  ],
                                  
                                  const SizedBox(height: 16),
                                  // Buttons Grid
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _downloadPdf(scan, scanProvider),
                                          icon: const Icon(Icons.download, size: 16),
                                          label: const Text('PDF Report', style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: color,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _signDocuSign(scan, scanProvider),
                                          icon: const Icon(Icons.edit_document, size: 16),
                                          label: const Text('DocuSign', style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            side: BorderSide(color: color),
                                            foregroundColor: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton.icon(
                                          onPressed: () => _blacklistSender(scan, scanProvider),
                                          icon: const Icon(Icons.block, size: 16, color: Colors.red),
                                          label: const Text('Block Sender', style: TextStyle(fontSize: 12, color: Colors.red)),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color activeColor) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _filter = value);
        }
      },
      selectedColor: activeColor,
      backgroundColor: Colors.black.withOpacity(0.04),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildSignalItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
