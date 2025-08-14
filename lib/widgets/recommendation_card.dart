import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/ai_recommendation_model.dart';

class RecommendationCard extends StatelessWidget {
  final AIRecommendation recommendation;
  final VoidCallback onTap;

  const RecommendationCard({
    Key? key,
    required this.recommendation,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF007AFF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            recommendation.symbol,
                            style: const TextStyle(
                              color: Color(0xFF00D4AA),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: recommendation.type == 'SIP' 
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recommendation.type,
                        style: TextStyle(
                          color: recommendation.type == 'SIP' ? Colors.blue : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildMetric('Current Price', '\$${recommendation.currentPrice.toStringAsFixed(2)}'),
                    ),
                    Expanded(
                      child: _buildMetric('Projected Return', '${recommendation.projectedReturn.toStringAsFixed(1)}%'),
                    ),
                    Expanded(
                      child: _buildMetric('Timeframe', recommendation.timeframe),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                Text(
                  recommendation.reasoning.length > 100
                      ? '${recommendation.reasoning.substring(0, 100)}...'
                      : recommendation.reasoning,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      size: 16,
                      color: _getConfidenceColor(recommendation.confidence),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'AI Confidence: ${(recommendation.confidence * 100).toInt()}%',
                      style: TextStyle(
                        color: _getConfidenceColor(recommendation.confidence),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.red;
  }
}
