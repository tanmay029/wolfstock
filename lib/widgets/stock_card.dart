import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:intl/intl.dart';
import '../models/stock_model.dart';
import '../services/auth_service.dart';

class StockCard extends StatelessWidget {
  final Stock stock;
  final VoidCallback onTap;
  final bool showWatchlistIcon;

  const StockCard({
    Key? key,
    required this.stock,
    required this.onTap,
    this.showWatchlistIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: stock.isPositive 
                    ? const Color(0xFF00D4AA).withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                // Stock Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: stock.isPositive 
                        ? const Color(0xFF00D4AA).withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: stock.isPositive ? const Color(0xFF00D4AA) : Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                
                // Stock Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              stock.symbol,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '\$${stock.currentPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              stock.name.length > 20 
                                  ? '${stock.name.substring(0, 20)}...'
                                  : stock.name,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: stock.isPositive 
                                  ? const Color(0xFF00D4AA).withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  stock.isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 12,
                                  color: stock.isPositive ? const Color(0xFF00D4AA) : Colors.red,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${stock.isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: stock.isPositive ? const Color(0xFF00D4AA) : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Watchlist Icon
                if (showWatchlistIcon) ...[
                  const SizedBox(width: 10),
                  Obx(() {
                    final user = authService.currentUser.value;
                    final isInWatchlist = user?.watchlist.contains(stock.symbol) ?? false;
                    
                    return IconButton(
                      onPressed: () {
                        if (isInWatchlist) {
                          authService.removeFromWatchlist(stock.symbol);
                        } else {
                          authService.addToWatchlist(stock.symbol);
                        }
                      },
                      icon: Icon(
                        isInWatchlist ? Icons.bookmark : Icons.bookmark_outline,
                        color: isInWatchlist ? const Color(0xFF00D4AA) : Colors.grey,
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
