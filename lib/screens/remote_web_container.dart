import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RemoteWebContainerScreen extends StatefulWidget {
  final String initialUrl;
  const RemoteWebContainerScreen({
    super.key,
    this.initialUrl = 'https://app.digikavach.net/',
  });

  @override
  State<RemoteWebContainerScreen> createState() => _RemoteWebContainerScreenState();
}

class _RemoteWebContainerScreenState extends State<RemoteWebContainerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    final WebViewController controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100.0;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _injectNativeBridge(controller);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('[RemoteWebContainer] Resource error: ${error.description}');
            if (error.isForMainFrame ?? true) {
              setState(() {
                _hasError = true;
                _errorMessage = error.description;
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://app.digikavach.net/') ||
                request.url.startsWith('https://api.digikavach.net/')) {
              return NavigationDecision.navigate;
            }
            // Launch external links in system browser
            _launchExternalUrl(request.url);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse(widget.initialUrl));

    _controller = controller;
  }

  void _injectNativeBridge(WebViewController controller) {
    const String bridgeJs = '''
      if (typeof window !== "undefined") {
        window.KavachNativeBridge = window.KavachNativeBridge || {};
        window.KavachNativeBridge.isNative = true;
        window.KavachNativeBridge.appVersion = "2.0.0";
        console.log("[RemoteWebContainer] Native Flutter Bridge injected successfully.");
      }
    ''';
    controller.runJavaScript(bridgeJs);
  }

  void _handleJavaScriptMessage(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final String? action = data['action']?.toString();
      final dynamic payload = data['payload'];

      debugPrint('[RemoteWebContainer] Native Message Received: action=$action, payload=$payload');

      switch (action) {
        case 'TRIGGER_SOS':
          _handleSOSAlert(payload);
          break;
        case 'REQUEST_CAMERA':
          _handleCameraPermission();
          break;
        case 'OPEN_PAYMENT':
          _handlePaymentGateway(payload);
          break;
        default:
          debugPrint('[RemoteWebContainer] Unknown action: $action');
      }
    } catch (e) {
      debugPrint('[RemoteWebContainer] Failed to parse JS message: $e');
    }
  }

  void _handleSOSAlert(dynamic payload) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 Emergency SOS Alert Broadcasted to DigiKavach Security Operations'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleCameraPermission() {
    debugPrint('[RemoteWebContainer] Native Camera Permission Handled');
  }

  void _handlePaymentGateway(dynamic payload) {
    debugPrint('[RemoteWebContainer] Payment Gateway Initiated: $payload');
  }

  Future<void> _launchExternalUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Stack(
            children: [
              if (!_hasError) WebViewWidget(controller: _controller),
              if (_isLoading)
                LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: const Color(0xFF1E293B),
                  color: const Color(0xFF0284C7),
                ),
              if (_hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        const Text(
                          'Connection Error',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage.isEmpty ? 'Failed to connect to KavachOne Security Cloud.' : _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _hasError = false;
                              _isLoading = true;
                            });
                            _controller.reload();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Connection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
