import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:wolfstock/controllers/bottom_nav_controller.dart';
import '../../controllers/stock_controller.dart';
import '../../services/auth_service.dart';
import '../../widgets/stock_card.dart';

class WatchlistScreen extends StatefulWidget {
  @override
  _WatchlistScreenState createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final StockController _stockController = Get.find<StockController>();
  final AuthService _authService = Get.find<AuthService>();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  void _loadWatchlist() {
    final user = _authService.currentUser.value;
    if (user != null && user.watchlist.isNotEmpty) {
      _stockController.loadWatchlistStocks(user.watchlist);
    }
  }

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
              Expanded(
                child: SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  child: Obx(() {
                    final user = _authService.currentUser.value;
                    
                    if (user == null) {
                      return const Center(
                        child: Text('Please log in to view your watchlist'),
                      );
                    }

                    if (user.watchlist.isEmpty) {
                      return _buildEmptyState();
                    }

                    if (_stockController.watchlistStocks.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _stockController.watchlistStocks.length,
                      itemBuilder: (context, index) {
                        final stock = _stockController.watchlistStocks[index];
                        return Dismissible(
                          key: Key(stock.symbol),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          onDismissed: (direction) {
                            _removeFromWatchlist(stock.symbol);
                          },
                          child: StockCard(
                            stock: stock,
                            onTap: () => Get.toNamed('/stock-detail', arguments: stock.symbol),
                            showWatchlistIcon: false,
                          ),
                        );
                      },
                    );
                  }),
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
          const Text(
            'My Watchlist',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Obx(() {
            final user = _authService.currentUser.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${user?.watchlist.length ?? 0} stocks',
                style: const TextStyle(
                  color: Color(0xFF00D4AA),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.bookmark_outline,
              size: 60,
              color: Color(0xFF00D4AA),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Watchlist is Empty',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add stocks to your watchlist to track\ntheir performance',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Get.find<BottomNavController>().changePage(0), // Assuming you have a bottom nav controller
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Explore Stocks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeFromWatchlist(String symbol) async {
    await _authService.removeFromWatchlist(symbol);
    _loadWatchlist();
    
    Get.snackbar(
      'Watchlist',
      'Removed $symbol from watchlist',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _onRefresh() async {
    _loadWatchlist();
    _refreshController.refreshCompleted();
  }
}
