import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/ai_controller.dart';
import '../../models/ai_recommendation_model.dart';
import '../../widgets/recommendation_card.dart';
import '../../widgets/ai_chat_widget.dart';

class AIPicksScreen extends StatefulWidget {
  @override
  _AIPicksScreenState createState() => _AIPicksScreenState();
}

class _AIPicksScreenState extends State<AIPicksScreen> with SingleTickerProviderStateMixin {
  final AIController _aiController = Get.put(AIController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _aiController.loadRecommendations();
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
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSIPRecommendations(),
                    _buildOneTimeRecommendations(),
                    _buildAIChatBot(),
                  ],
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF007AFF)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Investment Picks',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Smart recommendations powered by AI',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF00D4AA),
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: const [
          Tab(text: 'SIP Picks'),
          Tab(text: 'One-Time'),
          Tab(text: 'AI Chat'),
        ],
      ),
    );
  }

  Widget _buildSIPRecommendations() {
    return Obx(() {
      if (_aiController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(
            'SIP Recommendations',
            'Best stocks for systematic investment plans',
          ),
          const SizedBox(height: 15),
          ..._aiController.sipRecommendations.map((recommendation) {
            return RecommendationCard(
              recommendation: recommendation,
              onTap: () => _showRecommendationDetail(recommendation),
            );
          }),
        ],
      );
    });
  }

  Widget _buildOneTimeRecommendations() {
    return Obx(() {
      if (_aiController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(
            'One-Time Investment',
            'Best stocks for lump sum investments',
          ),
          const SizedBox(height: 15),
          ..._aiController.oneTimeRecommendations.map((recommendation) {
            return RecommendationCard(
              recommendation: recommendation,
              onTap: () => _showRecommendationDetail(recommendation),
            );
          }),
        ],
      );
    });
  }

  Widget _buildAIChatBot() {
    return const AIChatWidget();
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showRecommendationDetail(AIRecommendation recommendation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recommendation.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                recommendation.symbol,
                                style: const TextStyle(
                                  color: Color(0xFF00D4AA),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: recommendation.type == 'SIP' 
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            recommendation.type,
                            style: TextStyle(
                              color: recommendation.type == 'SIP' ? Colors.blue : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Key Metrics
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Current Price',
                            '\$${recommendation.currentPrice.toStringAsFixed(2)}',
                            Icons.attach_money,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            'Projected Return',
                            '${recommendation.projectedReturn.toStringAsFixed(1)}%',
                            Icons.trending_up,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            'Timeframe',
                            recommendation.timeframe,
                            Icons.schedule,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // AI Reasoning
                    const Text(
                      'AI Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      recommendation.reasoning,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Confidence Score
                    const Text(
                      'Confidence Score',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: recommendation.confidence,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        recommendation.confidence > 0.8 
                            ? Colors.green 
                            : recommendation.confidence > 0.6 
                                ? Colors.orange 
                                : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${(recommendation.confidence * 100).toInt()}% Confidence',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Pros and Cons
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pros',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...recommendation.pros.map((pro) => Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    const SizedBox(width: 5),
                                    Expanded(child: Text(pro, style: const TextStyle(fontSize: 14))),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cons',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...recommendation.cons.map((con) => Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Row(
                                  children: [
                                    const Icon(Icons.cancel, color: Colors.red, size: 16),
                                    const SizedBox(width: 5),
                                    Expanded(child: Text(con, style: const TextStyle(fontSize: 14))),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          Get.toNamed('/stock-detail', arguments: recommendation.symbol);
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
                          'View Stock Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00D4AA), size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}