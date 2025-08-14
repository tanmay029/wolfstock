// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockAdapter extends TypeAdapter<Stock> {
  @override
  final int typeId = 0;

  @override
  Stock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Stock(
      symbol: fields[0] as String,
      name: fields[1] as String,
      currentPrice: fields[2] as double,
      changeAmount: fields[3] as double,
      changePercent: fields[4] as double,
      dayHigh: fields[5] as double,
      dayLow: fields[6] as double,
      volume: fields[7] as double,
      marketCap: fields[8] as double,
      lastUpdated: fields[9] as DateTime,
      historicalData: (fields[10] as List?)?.cast<PricePoint>(),
    );
  }

  @override
  void write(BinaryWriter writer, Stock obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.symbol)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.currentPrice)
      ..writeByte(3)
      ..write(obj.changeAmount)
      ..writeByte(4)
      ..write(obj.changePercent)
      ..writeByte(5)
      ..write(obj.dayHigh)
      ..writeByte(6)
      ..write(obj.dayLow)
      ..writeByte(7)
      ..write(obj.volume)
      ..writeByte(8)
      ..write(obj.marketCap)
      ..writeByte(9)
      ..write(obj.lastUpdated)
      ..writeByte(10)
      ..write(obj.historicalData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PricePointAdapter extends TypeAdapter<PricePoint> {
  @override
  final int typeId = 1;

  @override
  PricePoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PricePoint(
      date: fields[0] as DateTime,
      price: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PricePoint obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PricePointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
