import 'package:hive/hive.dart';

part 'stock_model.g.dart';

@HiveType(typeId: 0)
class Stock extends HiveObject {
  @HiveField(0)
  String symbol;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  double currentPrice;
  
  @HiveField(3)
  double changeAmount;
  
  @HiveField(4)
  double changePercent;
  
  @HiveField(5)
  double dayHigh;
  
  @HiveField(6)
  double dayLow;
  
  @HiveField(7)
  double volume;
  
  @HiveField(8)
  double marketCap;
  
  @HiveField(9)
  DateTime lastUpdated;
  
  @HiveField(10)
  List<PricePoint>? historicalData;

  Stock({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.changeAmount,
    required this.changePercent,
    required this.dayHigh,
    required this.dayLow,
    required this.volume,
    required this.marketCap,
    required this.lastUpdated,
    this.historicalData,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? json['shortName'] ?? '',
      currentPrice: (json['regularMarketPrice'] ?? json['price'] ?? 0).toDouble(),
      changeAmount: (json['regularMarketChange'] ?? json['change'] ?? 0).toDouble(),
      changePercent: (json['regularMarketChangePercent'] ?? json['changesPercentage'] ?? 0).toDouble(),
      dayHigh: (json['regularMarketDayHigh'] ?? json['dayHigh'] ?? 0).toDouble(),
      dayLow: (json['regularMarketDayLow'] ?? json['dayLow'] ?? 0).toDouble(),
      volume: (json['regularMarketVolume'] ?? json['volume'] ?? 0).toDouble(),
      marketCap: (json['marketCap'] ?? 0).toDouble(),
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'currentPrice': currentPrice,
      'changeAmount': changeAmount,
      'changePercent': changePercent,
      'dayHigh': dayHigh,
      'dayLow': dayLow,
      'volume': volume,
      'marketCap': marketCap,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  bool get isPositive => changeAmount >= 0;
}

@HiveType(typeId: 1)
class PricePoint extends HiveObject {
  @HiveField(0)
  DateTime date;
  
  @HiveField(1)
  double price;

  PricePoint({required this.date, required this.price});
}
