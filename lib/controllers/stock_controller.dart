import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../models/stock_model.dart';
import '../services/stock_api_service.dart';

class StockController extends GetxController {
  final StockApiService _apiService = Get.find<StockApiService>();
  
  RxList<Stock> trendingStocks = <Stock>[].obs;
  RxList<Stock> searchResults = <Stock>[].obs;
  RxList<Stock> watchlistStocks = <Stock>[].obs;
  RxBool isLoading = false.obs;
  RxBool isSearching = false.obs;
  RxString searchQuery = ''.obs;
  
  late Box<Stock> _stockBox;

  @override
  void onInit() {
    super.onInit();
    _initHive();
    loadTrendingStocks();
  }

  void _initHive() async {
    _stockBox = await Hive.openBox<Stock>('stocks');
    _loadCachedStocks();
  }

  void _loadCachedStocks() {
    final cached = _stockBox.values.toList();
    if (cached.isNotEmpty) {
      trendingStocks.value = cached;
    }
  }

  Future<void> loadTrendingStocks() async {
    isLoading.value = true;
    
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        _loadCachedStocks();
        Get.snackbar('Offline', 'Showing cached data');
        return;
      }

      final stocks = await _apiService.getTrendingStocks();
      trendingStocks.value = stocks;
      
      // Cache the data
      await _stockBox.clear();
      for (var stock in stocks) {
        await _stockBox.add(stock);
      }
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to load stocks: $e');
      _loadCachedStocks();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchStocks(String query) async {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }
    
    isSearching.value = true;
    searchQuery.value = query;
    
    try {
      final symbols = await _apiService.searchStocks(query);
      final stocks = await _apiService.getMultipleStocks(symbols.take(5).toList());
      searchResults.value = stocks;
    } catch (e) {
      Get.snackbar('Error', 'Search failed: $e');
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> loadWatchlistStocks(List<String> symbols) async {
    try {
      final stocks = await _apiService.getMultipleStocks(symbols);
      watchlistStocks.value = stocks;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load watchlist: $e');
    }
  }

  Future<Stock?> getStockDetail(String symbol) async {
    try {
      return await _apiService.getStockData(symbol);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load stock details: $e');
      return null;
    }
  }

  void clearSearch() {
    searchResults.clear();
    searchQuery.value = '';
  }
}
