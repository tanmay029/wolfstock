// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_recommendation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AIRecommendationAdapter extends TypeAdapter<AIRecommendation> {
  @override
  final int typeId = 2;

  @override
  AIRecommendation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AIRecommendation(
      symbol: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      currentPrice: fields[3] as double,
      projectedReturn: fields[4] as double,
      timeframe: fields[5] as String,
      reasoning: fields[6] as String,
      confidence: fields[7] as double,
      pros: (fields[8] as List).cast<String>(),
      cons: (fields[9] as List).cast<String>(),
      createdAt: fields[10] as DateTime,
      riskLevel: fields[11] as String?,
      minimumInvestment: fields[12] as double?,
      sector: fields[13] as String?,
      additionalMetrics: (fields[14] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, AIRecommendation obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.symbol)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.currentPrice)
      ..writeByte(4)
      ..write(obj.projectedReturn)
      ..writeByte(5)
      ..write(obj.timeframe)
      ..writeByte(6)
      ..write(obj.reasoning)
      ..writeByte(7)
      ..write(obj.confidence)
      ..writeByte(8)
      ..write(obj.pros)
      ..writeByte(9)
      ..write(obj.cons)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.riskLevel)
      ..writeByte(12)
      ..write(obj.minimumInvestment)
      ..writeByte(13)
      ..write(obj.sector)
      ..writeByte(14)
      ..write(obj.additionalMetrics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIRecommendationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecommendationCategoryAdapter
    extends TypeAdapter<RecommendationCategory> {
  @override
  final int typeId = 3;

  @override
  RecommendationCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecommendationCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      iconName: fields[3] as String,
      recommendationIds: (fields[4] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, RecommendationCategory obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.iconName)
      ..writeByte(4)
      ..write(obj.recommendationIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
