import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/stock_controller.dart';
import '../../controllers/theme_controller.dart';
// import '../../models/stock_model.dart';
import '../../widgets/stock_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StockController _stockController = Get.find<StockController>();
  final ThemeController _themeController = Get.find<ThemeController>();
  final TextEditingController _searchController = TextEditingController();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Get.isDarkMode 
                ? [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)]
                : [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(
                child: SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMarketOverview(),
                        const SizedBox(height: 20),
                        _buildTrendingSection(),
                        const SizedBox(height: 20),
                        _buildSearchResults(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good Morning! 👋',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'WolfStock',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _themeController.toggleTheme(),
                icon: Obx(() => Icon(
                  _themeController.isDarkMode.value 
                      ? Icons.light_mode 
                      : Icons.dark_mode,
                  color: const Color(0xFF00D4AA),
                )),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF00D4AA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          if (value.isNotEmpty) {
            _stockController.searchStocks(value);
          } else {
            _stockController.clearSearch();
          }
        },
        decoration: InputDecoration(
          hintText: 'Search stocks (e.g., AAPL, GOOGL)',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _stockController.clearSearch();
                  },
                )
              : null,
          filled: true,
          fillColor: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D4AA), Color(0xFF007AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Market Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMarketStat('S&P 500', '+1.2%', '4,185.47'),
              _buildMarketStat('NASDAQ', '+0.8%', '12,843.81'),
              _buildMarketStat('DOW', '+0.5%', '33,745.40'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStat(String name, String change, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          change,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trending Stocks',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Obx(() {
          if (_stockController.isLoading.value) {
            return _buildShimmerList();
          }
          
          if (_stockController.trendingStocks.isEmpty) {
            return const Center(
              child: Text('No trending stocks available'),
            );
          }
          
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stockController.trendingStocks.length,
            itemBuilder: (context, index) {
              final stock = _stockController.trendingStocks[index];
              return StockCard(
                stock: stock,
                onTap: () => Get.toNamed('/stock-detail', arguments: stock.symbol),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Obx(() {
      if (_stockController.searchQuery.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Results for "${_stockController.searchQuery.value}"',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          if (_stockController.isSearching.value)
            _buildShimmerList()
          else if (_stockController.searchResults.isEmpty)
            const Center(
              child: Text('No results found'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stockController.searchResults.length,
              itemBuilder: (context, index) {
                final stock = _stockController.searchResults[index];
                return StockCard(
                  stock: stock,
                  onTap: () => Get.toNamed('/stock-detail', arguments: stock.symbol),
                );
              },
            ),
        ],
      );
    });
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Get.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: Get.isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          );
        },
      ),
    );
  }

  void _onRefresh() async {
    await _stockController.loadTrendingStocks();
    _refreshController.refreshCompleted();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }
}
