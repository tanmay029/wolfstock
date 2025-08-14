import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/stock_model.dart';
import '../../controllers/stock_controller.dart';
import '../../services/auth_service.dart';

class StockDetailScreen extends StatefulWidget {
  @override
  _StockDetailScreenState createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final StockController _stockController = Get.find<StockController>();
  final AuthService _authService = Get.find<AuthService>();
  
  late String symbol;
  Stock? stock;
  bool isLoading = true;
  bool isInWatchlist = false;
  String selectedPeriod = '1D';
  
  final List<String> periods = ['1D', '1W', '1M', '3M', '1Y'];

  @override
  void initState() {
    super.initState();
    symbol = Get.arguments as String;
    _loadStockData();
    _checkWatchlistStatus();
  }

  void _loadStockData() async {
    final stockData = await _stockController.getStockDetail(symbol);
    setState(() {
      stock = stockData;
      isLoading = false;
    });
  }

  void _checkWatchlistStatus() {
    final user = _authService.currentUser.value;
    if (user != null) {
      setState(() {
        isInWatchlist = user.watchlist.contains(symbol);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          symbol,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isInWatchlist ? Icons.bookmark : Icons.bookmark_outline,
              color: isInWatchlist ? const Color(0xFF00D4AA) : Colors.white,
            ),
            onPressed: _toggleWatchlist,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : stock == null
              ? const Center(child: Text('Failed to load stock data'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPriceCard(),
                      const SizedBox(height: 20),
                      _buildChartCard(),
                      const SizedBox(height: 20),
                      _buildStatsCard(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPriceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: stock!.isPositive
              ? [const Color(0xFF00D4AA), const Color(0xFF007AFF)]
              : [const Color(0xFFFF3B30), const Color(0xFFFF9500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (stock!.isPositive ? const Color(0xFF00D4AA) : const Color(0xFFFF3B30))
                .withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stock!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '\$${stock!.currentPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                stock!.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 5),
              Text(
                '${stock!.isPositive ? '+' : ''}\$${stock!.changeAmount.toStringAsFixed(2)} (${stock!.changePercent.toStringAsFixed(2)}%)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price Chart',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: periods.map((period) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPeriod = period;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selectedPeriod == period
                            ? const Color(0xFF00D4AA)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: selectedPeriod == period
                              ? const Color(0xFF00D4AA)
                              : Colors.grey,
                        ),
                      ),
                      child: Text(
                        period,
                        style: TextStyle(
                          color: selectedPeriod == period
                              ? Colors.white
                              : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    if (stock?.historicalData == null || stock!.historicalData!.isEmpty) {
      return const Center(child: Text('No chart data available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: stock!.historicalData!.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.price);
            }).toList(),
            isCurved: true,
            color: stock!.isPositive ? const Color(0xFF00D4AA) : const Color(0xFFFF3B30),
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: (stock!.isPositive ? const Color(0xFF00D4AA) : const Color(0xFFFF3B30))
                  .withOpacity(0.1),
            ),
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Day High', '\$${stock!.dayHigh.toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _buildStatItem('Day Low', '\$${stock!.dayLow.toStringAsFixed(2)}'),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Volume', NumberFormat.compact().format(stock!.volume)),
              ),
              Expanded(
                child: _buildStatItem('Market Cap', NumberFormat.compact().format(stock!.marketCap)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Add buy functionality
              Get.snackbar('Info', 'Buy functionality coming soon!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Buy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // Add sell functionality
              Get.snackbar('Info', 'Sell functionality coming soon!');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B30),
              side: const BorderSide(color: Color(0xFFFF3B30)),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Sell',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleWatchlist() async {
    if (isInWatchlist) {
      await _authService.removeFromWatchlist(symbol);
    } else {
      await _authService.addToWatchlist(symbol);
    }
    
    setState(() {
      isInWatchlist = !isInWatchlist;
    });
    
    Get.snackbar(
      'Watchlist',
      isInWatchlist ? 'Added to watchlist' : 'Removed from watchlist',
      backgroundColor: const Color(0xFF00D4AA),
      colorText: Colors.white,
    );
  }
}
