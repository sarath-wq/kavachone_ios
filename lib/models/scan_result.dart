class ScanResult {
  final String? id;
  final String channel;
  final String status;
  final String? threatLevel;
  final String? scamCategory;
  final double? confidenceScore;
  final String? rawContent;
  final Map<String, dynamic>? aiAnalysis;
  final Map<String, dynamic>? extractedEntities;

  ScanResult({
    this.id,
    required this.channel,
    required this.status,
    this.threatLevel,
    this.scamCategory,
    this.confidenceScore,
    this.rawContent,
    this.aiAnalysis,
    this.extractedEntities,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    double? parsedConfidence;
    if (json['confidence_score'] != null) {
      parsedConfidence = (json['confidence_score'] as num).toDouble();
    }
    
    return ScanResult(
      id: json['id'],
      channel: json['channel'] ?? '',
      status: json['status'] ?? '',
      threatLevel: json['threat_level'],
      scamCategory: json['scam_category'],
      confidenceScore: parsedConfidence,
      rawContent: json['raw_content'],
      aiAnalysis: json['ai_analysis'] is Map ? Map<String, dynamic>.from(json['ai_analysis']) : null,
      extractedEntities: json['extracted_entities'] is Map ? Map<String, dynamic>.from(json['extracted_entities']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel': channel,
      'status': status,
      'threat_level': threatLevel,
      'scam_category': scamCategory,
      'confidence_score': confidenceScore,
      'raw_content': rawContent,
      'ai_analysis': aiAnalysis,
      'extracted_entities': extractedEntities,
    };
  }

  // Helper getters
  bool get isCritical => threatLevel == 'critical';
  bool get isHigh => threatLevel == 'high';
  bool get isMedium => threatLevel == 'medium';
  bool get isLow => threatLevel == 'low';
  bool get isSafe => threatLevel == 'safe';

  int get riskScore => aiAnalysis?['risk_score'] ?? 0;
  
  String get aiReasoning {
    final raw = aiAnalysis?['ai_reasoning'] ?? '';
    // Strip leading bracketed content (e.g. "[WhatsApp Scan] Reasoning text...")
    return raw.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
  }

  String get chatResponse => aiAnalysis?['chat_response'] ?? '';

  List<String> get overrideApplied {
    final overrides = aiAnalysis?['override_applied'];
    if (overrides is List) {
      return overrides.map((e) => e.toString()).toList();
    }
    return [];
  }

  List<String> get blacklistReasons {
    final reasons = aiAnalysis?['blacklist_reasons'];
    if (reasons is List) {
      return reasons.map((e) => e.toString()).toList();
    }
    return [];
  }

  Map<String, dynamic>? get urlScan => aiAnalysis?['url_scan'];
}
