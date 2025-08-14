import 'package:hive/hive.dart';

part 'ai_recommendation_model.g.dart';

@HiveType(typeId: 2)
class AIRecommendation extends HiveObject {
  @HiveField(0)
  String symbol;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String type; // 'SIP' or 'OneTime'
  
  @HiveField(3)
  double currentPrice;
  
  @HiveField(4)
  double projectedReturn;
  
  @HiveField(5)
  String timeframe;
  
  @HiveField(6)
  String reasoning;
  
  @HiveField(7)
  double confidence;
  
  @HiveField(8)
  List<String> pros;
  
  @HiveField(9)
  List<String> cons;
  
  @HiveField(10)
  DateTime createdAt;
  
  @HiveField(11)
  String? riskLevel; // 'Low', 'Medium', 'High'
  
  @HiveField(12)
  double? minimumInvestment;
  
  @HiveField(13)
  String? sector;
  
  @HiveField(14)
  Map<String, dynamic>? additionalMetrics;

  AIRecommendation({
    required this.symbol,
    required this.name,
    required this.type,
    required this.currentPrice,
    required this.projectedReturn,
    required this.timeframe,
    required this.reasoning,
    required this.confidence,
    required this.pros,
    required this.cons,
    required this.createdAt,
    this.riskLevel,
    this.minimumInvestment,
    this.sector,
    this.additionalMetrics,
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
  return AIRecommendation(
    symbol: json['symbol'] ?? '',
    name: json['name'] ?? '',
    type: json['type'] ?? 'OneTime',
    currentPrice: (json['currentPrice'] ?? 0).toDouble(),
    projectedReturn: (json['projectedReturn'] ?? 0).toDouble(),
    timeframe: json['timeframe'] ?? '',
    reasoning: json['reasoning'] ?? '',
    confidence: (json['confidence'] ?? 0).toDouble(),
    pros: List<String>.from(json['pros'] ?? []),
    cons: List<String>.from(json['cons'] ?? []),
    createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(), // Provide default value
    riskLevel: json['riskLevel'],
    minimumInvestment: json['minimumInvestment']?.toDouble(),
    sector: json['sector'],
    additionalMetrics: json['additionalMetrics'],
  );
}

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'type': type,
      'currentPrice': currentPrice,
      'projectedReturn': projectedReturn,
      'timeframe': timeframe,
      'reasoning': reasoning,
      'confidence': confidence,
      'pros': pros,
      'cons': cons,
      'createdAt': createdAt.toIso8601String(),
      'riskLevel': riskLevel,
      'minimumInvestment': minimumInvestment,
      'sector': sector,
      'additionalMetrics': additionalMetrics,
    };
  }

  // Utility getters
  bool get isHighConfidence => confidence >= 0.8;
  bool get isMediumConfidence => confidence >= 0.6 && confidence < 0.8;
  bool get isLowConfidence => confidence < 0.6;

  String get confidenceLevel {
    if (isHighConfidence) return 'High';
    if (isMediumConfidence) return 'Medium';
    return 'Low';
  }

  bool get isSIPRecommendation => type.toLowerCase() == 'sip';
  bool get isOneTimeRecommendation => type.toLowerCase() == 'onetime';

  String get formattedProjectedReturn => '${projectedReturn.toStringAsFixed(1)}%';
  String get formattedPrice => '\$${currentPrice.toStringAsFixed(2)}';
  String get formattedConfidence => '${(confidence * 100).toInt()}%';

  // Risk assessment based on projected return and confidence
  String get computedRiskLevel {
    if (riskLevel != null) return riskLevel!;
    
    if (projectedReturn > 20 || confidence < 0.6) return 'High';
    if (projectedReturn > 10 || confidence < 0.8) return 'Medium';
    return 'Low';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIRecommendation &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          type == other.type;

  @override
  int get hashCode => symbol.hashCode ^ type.hashCode;

  @override
  String toString() {
    return 'AIRecommendation{symbol: $symbol, name: $name, type: $type, projectedReturn: $projectedReturn%, confidence: $formattedConfidence}';
  }
}

// Supporting model for recommendation categories
@HiveType(typeId: 3)
class RecommendationCategory extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String description;
  
  @HiveField(3)
  String iconName;
  
  @HiveField(4)
  List<String> recommendationIds;

  RecommendationCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.recommendationIds = const [],
  });

  factory RecommendationCategory.fromJson(Map<String, dynamic> json) {
    return RecommendationCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconName: json['iconName'],
      recommendationIds: List<String>.from(json['recommendationIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'recommendationIds': recommendationIds,
    };
  }
}
