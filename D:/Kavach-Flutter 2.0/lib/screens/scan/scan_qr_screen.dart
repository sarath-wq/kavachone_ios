import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  
  bool _showPreview = false;
  String _decodedText = '';
  String _decodedType = 'text'; // 'url' | 'upi' | 'phone' | 'text'

  bool _torchOn = false;
  String _scanHint = 'Aim at the QR code';

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final text = barcodes.first.rawValue!;
      _scannerController.stop();
      _showQRPreview(text);
    }
  }

  void _showQRPreview(String text) {
    setState(() {
      _decodedText = text;
      _decodedType = _classifyQR(text);
      _showPreview = true;
    });
  }

  String _classifyQR(String text) {
    if (RegExp(r'^upi:\/\/', caseSensitive: false).hasMatch(text) || text.contains('pa=') && text.contains('&pn=')) {
      return 'upi';
    }
    if (RegExp(r'^https?:\/\/', caseSensitive: false).hasMatch(text) || RegExp(r'^www\.', caseSensitive: false).hasMatch(text)) {
      return 'url';
    }
    if (RegExp(r'^\+?[\d\s\-]{8,15}$').hasMatch(text.trim())) {
      return 'phone';
    }
    return 'text';
  }

  String get _typeLabel {
    switch (_decodedType) {
      case 'url': return '🔗 URL / Link';
      case 'upi': return '💳 UPI Payment';
      case 'phone': return '📞 Phone Number';
      default: return '📝 Text';
    }
  }

  String get _typeWarning {
    switch (_decodedType) {
      case 'url': return 'This QR leads to a website. DigiKavach will check if it\'s a phishing or scam site.';
      case 'upi': return 'This QR contains a UPI payment request. DigiKavach will verify the UPI ID.';
      case 'phone': return 'This QR contains a phone number. DigiKavach will check if it has been reported.';
      default: return 'DigiKavach will analyse this text for scam patterns.';
    }
  }

  Map<String, String> get _upiDetails {
    if (_decodedType != 'upi') return {};
    try {
      final uri = Uri.parse(_decodedText);
      final params = uri.queryParameters;
      return {
        if (params['pa'] != null) 'UPI ID': params['pa']!,
        if (params['pn'] != null) 'Payee Name': Uri.decodeComponent(params['pn']!),
        if (params['am'] != null) 'Amount': '₹${params['am']}',
        if (params['tn'] != null) 'Note': Uri.decodeComponent(params['tn']!),
        if (params['cu'] != null) 'Currency': params['cu']!,
      };
    } catch (_) {
      // Fallback parser if uri parsing fails
      final clean = _decodedText.replaceFirst(RegExp(r'^upi:\/\/pay\?'), '');
      final pairs = clean.split('&');
      final map = <String, String>{};
      for (final p in pairs) {
        final split = p.split('=');
        if (split.length == 2) {
          final k = split[0];
          final v = Uri.decodeComponent(split[1]);
          if (k == 'pa') map['UPI ID'] = v;
          if (k == 'pn') map['Payee Name'] = v;
          if (k == 'am') map['Amount'] = '₹$v';
          if (k == 'tn') map['Note'] = v;
        }
      }
      return map;
    }
  }

  String _buildAnalysisText() {
    if (_decodedType == 'upi') {
      final details = _upiDetails;
      final pa = details['UPI ID'] ?? '';
      final pn = details['Payee Name'] ?? '';
      final am = details['Amount'] ?? '';
      final tn = details['Note'] ?? '';
      return 'I received a QR code asking me to pay money via UPI. '
          'UPI ID: $pa. Payee name: $pn. Amount: $am. '
          '${tn.isNotEmpty ? "Transaction note: \"$tn\". " : ""}'
          'Is this UPI ID safe to pay? Could this be a scam?';
    }
    if (_decodedType == 'url') {
      return 'I scanned a QR code and it contains this link: $_decodedText. '
          'Is this a safe website or a phishing/scam link?';
    }
    if (_decodedType == 'phone') {
      return 'I scanned a QR code and it contains this phone number: $_decodedText. '
          'Has this number been reported as a scam or fraud?';
    }
    return _decodedText;
  }

  void _analyseWithKavachBot() {
    final uniqueSource = 'qr_scan_${DateTime.now().millisecondsSinceEpoch}';
    Navigator.pushReplacementNamed(
      context, 
      '/chat',
      arguments: {
        'text': _buildAnalysisText(),
        'channel': 'whatsapp',
        'source': uniqueSource,
      },
    );
  }

  Future<void> _onUploadImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      // Simulate image QR decoding
      _showQRPreview('upi://pay?pa=scammer@ybl&pn=Fake+Merchant&am=25000&tn=Electricity+Bill+Urgent');
    }
  }

  void _scanAnother() {
    setState(() {
      _showPreview = false;
      _decodedText = '';
      _scanHint = 'Aim at the QR code';
    });
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _scannerController.stop();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (!_showPreview)
            IconButton(
              icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
              onPressed: () async {
                await _scannerController.toggleTorch();
                setState(() {
                  _torchOn = !_torchOn;
                });
              },
            ),
        ],
      ),
      body: _showPreview 
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: Text('📷', style: TextStyle(fontSize: 64))),
                const SizedBox(height: 16),
                Text(
                  'QR Scanned Successfully',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                
                // Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _typeLabel,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _typeWarning,
                          style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.3),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        
                        if (_decodedType == 'upi') ...[
                          ..._upiDetails.entries.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          )),
                        ] else ...[
                          Text(
                            _decodedText,
                            style: const TextStyle(fontSize: 14, height: 1.4, fontFamily: 'monospace'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _analyseWithKavachBot,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text('Analyse with KavachBot AI', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _scanAnother,
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
                  child: const Text('Scan Another', style: TextStyle(color: Colors.black87)),
                ),
              ],
            ),
          )
        : Stack(
            children: [
              // Scanner view
              MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
              
              // Overlay cutout styling
              Positioned.fill(
                child: Container(
                  decoration: ShapeDecoration(
                    shape: QrScannerOverlayShape(
                      borderColor: AppTheme.primaryColor,
                      borderRadius: 12,
                      borderLength: 30,
                      borderWidth: 6,
                      cutOutSize: 240,
                    ),
                  ),
                ),
              ),

              // Helper title instructions
              Positioned(
                bottom: 80,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _scanHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _onUploadImage,
                      icon: const Icon(Icons.photo_library, color: Colors.white),
                      label: const Text('Upload QR from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(backgroundColor: Colors.white12),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

// Custom painter overlay for scanner target box
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.blue,
    this.borderWidth = 3.0,
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;

    final cutOutRect = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: cutOutSize,
      height: cutOutSize,
    );

    // Paint transparent background dimming overlay
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.5);
    final cutoutPath = Path()
      ..addRect(rect)
      ..addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(cutoutPath, backgroundPaint..style = PaintingStyle.fill);

    // Draw borders around scanner cutout
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final borderPath = Path();
    // Top Left Corner
    borderPath.moveTo(cutOutRect.left + borderRadius, cutOutRect.top);
    borderPath.lineTo(cutOutRect.left + borderLength, cutOutRect.top);
    borderPath.moveTo(cutOutRect.left, cutOutRect.top + borderRadius);
    borderPath.lineTo(cutOutRect.left, cutOutRect.top + borderLength);

    // Top Right Corner
    borderPath.moveTo(cutOutRect.right - borderRadius, cutOutRect.top);
    borderPath.lineTo(cutOutRect.right - borderLength, cutOutRect.top);
    borderPath.moveTo(cutOutRect.right, cutOutRect.top + borderRadius);
    borderPath.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Bottom Left Corner
    borderPath.moveTo(cutOutRect.left + borderRadius, cutOutRect.bottom);
    borderPath.lineTo(cutOutRect.left + borderLength, cutOutRect.bottom);
    borderPath.moveTo(cutOutRect.left, cutOutRect.bottom - borderRadius);
    borderPath.lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    // Bottom Right Corner
    borderPath.moveTo(cutOutRect.right - borderRadius, cutOutRect.bottom);
    borderPath.lineTo(cutOutRect.right - borderLength, cutOutRect.bottom);
    borderPath.moveTo(cutOutRect.right, cutOutRect.bottom - borderRadius);
    borderPath.lineTo(cutOutRect.right, cutOutRect.bottom - borderLength);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
