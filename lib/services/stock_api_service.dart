import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../models/stock_model.dart';

class StockApiService extends GetxService {
  static const String _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart/';
  static const String _searchUrl = 'https://query2.finance.yahoo.com/v1/finance/search';
  
  final Dio _dio = Dio();

  @override
  void onInit() {
    super.onInit();
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  Future<Stock?> getStockData(String symbol) async {
    try {
      final response = await _dio.get('$_baseUrl$symbol');
      
      if (response.statusCode == 200) {
        final data = response.data['chart']['result'][0];
        final meta = data['meta'];
        // final quote = data['indicators']['quote'][0];
        
        return Stock(
          symbol: symbol.toUpperCase(),
          name: meta['longName'] ?? symbol,
          currentPrice: meta['regularMarketPrice']?.toDouble() ?? 0.0,
          changeAmount: (meta['regularMarketPrice'] - meta['previousClose'])?.toDouble() ?? 0.0,
          changePercent: ((meta['regularMarketPrice'] - meta['previousClose']) / meta['previousClose'] * 100)?.toDouble() ?? 0.0,
          dayHigh: meta['regularMarketDayHigh']?.toDouble() ?? 0.0,
          dayLow: meta['regularMarketDayLow']?.toDouble() ?? 0.0,
          volume: meta['regularMarketVolume']?.toDouble() ?? 0.0,
          marketCap: meta['marketCap']?.toDouble() ?? 0.0,
          lastUpdated: DateTime.now(),
          historicalData: _parseHistoricalData(data),
        );
      }
    } catch (e) {
      print('Error fetching stock data for $symbol: $e');
    }
    return null;
  }

  Future<List<Stock>> getMultipleStocks(List<String> symbols) async {
    final List<Stock> stocks = [];
    
    for (String symbol in symbols) {
      final stock = await getStockData(symbol);
      if (stock != null) {
        stocks.add(stock);
      }
    }
    
    return stocks;
  }

  Future<List<String>> searchStocks(String query) async {
    try {
      final response = await _dio.get(_searchUrl, queryParameters: {
        'q': query,
        'quotesCount': 10,
        'newsCount': 0,
      });

      if (response.statusCode == 200) {
        final quotes = response.data['quotes'] as List;
        return quotes
            .where((quote) => quote['typeDisp'] == 'Equity')
            .map<String>((quote) => quote['symbol'] as String)
            .toList();
      }
    } catch (e) {
      print('Error searching stocks: $e');
    }
    return [];
  }

  List<PricePoint> _parseHistoricalData(Map<String, dynamic> data) {
    final timestamps = data['timestamp'] as List?;
    final quotes = data['indicators']['quote'][0];
    final closePrices = quotes['close'] as List?;

    if (timestamps == null || closePrices == null) return [];

    List<PricePoint> points = [];
    for (int i = 0; i < timestamps.length && i < closePrices.length; i++) {
      if (closePrices[i] != null) {
        points.add(PricePoint(
          date: DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
          price: closePrices[i].toDouble(),
        ));
      }
    }
    return points;
  }

  Future<List<Stock>> getTrendingStocks() async {
    const trendingSymbols = ['AAPL', 'GOOGL', 'MSFT', 'AMZN', 'TSLA', 'META', 'NVDA', 'NFLX'];
    return await getMultipleStocks(trendingSymbols);
  }
}
