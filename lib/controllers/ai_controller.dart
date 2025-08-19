// lib/controllers/ai_controller.dart (Enhanced with Gemini AI Chat)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wolfstock/models/chat_message.dart';
import '../models/ai_recommendation_model.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';

class AIController extends GetxController {
  final AIService _aiService = Get.find<AIService>();
  final AuthService _authService = Get.find<AuthService>();
  
  // Existing recommendation lists
  RxList<AIRecommendation> sipRecommendations = <AIRecommendation>[].obs;
  RxList<AIRecommendation> oneTimeRecommendations = <AIRecommendation>[].obs;
  RxList<AIRecommendation> personalizedRecommendations = <AIRecommendation>[].obs;
  
  // Enhanced chat and analysis features
  RxBool isLoading = false.obs;
  RxBool isChatLoading = false.obs;
  RxBool isAnalyzing = false.obs;
  RxString currentAnalysis = ''.obs;
  RxString marketInsights = ''.obs;
  
  // Filters and preferences
  RxString selectedRiskLevel = 'All'.obs;
  RxString selectedSector = 'All'.obs;
  RxString selectedTimeframe = 'All'.obs;
  
  // Enhanced chat features with Gemini AI
  RxList<ChatMessage> chatMessages = <ChatMessage>[].obs;
  RxList<String> chatHistory = <String>[].obs;
  RxBool isTyping = false.obs;
  RxString lastChatError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
    loadRecommendations();
    loadMarketInsights();
  }

  /// Initialize chat with welcome message
  void _initializeChat() {
    final userName = _authService.currentUser.value?.firstName ?? 'Investor';
    chatMessages.add(
      ChatMessage(
        text: '''👋 Hello $userName! I'm your **WolfStock AI Assistant** powered by Google Gemini.

I can help you with:
📊 **Market Analysis** - Current trends and opportunities
🔍 **Stock Research** - Detailed company analysis
💰 **Investment Planning** - SIP strategies and portfolio advice
📈 **Risk Assessment** - Personalized risk recommendations
🎓 **Financial Education** - Investment learning and tips

**Try asking:**
• "Analyze AAPL stock"
• "Best SIP recommendations for beginners"
• "Current market trends"
• "Review my portfolio"

What would you like to explore today?''',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Enhanced chat response with Gemini AI integration
  Future<String> getChatResponse(String query) async {
    isChatLoading.value = true;
    isTyping.value = true;
    lastChatError.value = '';
    
    try {
      // Add user message to chat
      chatMessages.add(
        ChatMessage(
          text: query,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );

      // Add query to history for context
      chatHistory.add('User: $query');
      
      // Get user context for personalized responses
      final user = _authService.currentUser.value;
      final userStocks = user?.portfolioSymbols ?? [];
      final userContext = _buildUserContext(user);
      
      String response;
      
      // Smart routing based on query type
      if (_isStockAnalysisQuery(query)) {
        final symbol = _extractStockSymbol(query);
        response = await _aiService.analyzeStock(symbol);
      } else if (_isPortfolioQuery(query) && userStocks.isNotEmpty) {
        final portfolioValue = user?.portfolioValue ?? 0.0;
        response = await _aiService.reviewPortfolio(userStocks, portfolioValue);
      } else if (_isMarketQuery(query)) {
        response = await _aiService.getMarketInsights();
      } else if (_isSIPQuery(query)) {
        response = await _aiService.getChatResponse(
          'Provide detailed SIP investment recommendations with specific monthly amounts and strategies',
          context: userContext,
        );
      } else if (_isRiskQuery(query)) {
        final riskLevel = _extractRiskLevel(query);
        response = await _aiService.getRiskBasedAdvice(riskLevel);
      } else if (_isSectorQuery(query)) {
        final sector = _extractSector(query);
        response = await _aiService.getSectorAnalysis(sector);
      } else {
        // General query with personalized context
        response = userStocks.isNotEmpty
            ? await _aiService.getPersonalizedAdvice(query, userStocks)
            : await _aiService.getChatResponse(query, context: userContext);
      }
      
      // Add AI response to chat
      chatMessages.add(
        ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      
      // Add response to history
      chatHistory.add('AI: $response');
      
      // Keep chat history manageable (last 20 exchanges)
      if (chatHistory.length > 40) {
        chatHistory.removeRange(0, chatHistory.length - 40);
      }
      
      // Limit chat messages in UI (last 50 messages)
      if (chatMessages.length > 50) {
        chatMessages.removeRange(0, chatMessages.length - 50);
      }
      
      return response;
      
    } catch (e) {
      print('Error getting chat response: $e');
      lastChatError.value = e.toString();
      
      final errorResponse = '''🤖 **WolfStock AI**

I apologize for the temporary issue. Here are some things I can help you with:

📊 **Market Analysis**: "What are today's market trends?"
🔍 **Stock Research**: "Analyze AAPL stock"
💰 **Investment Planning**: "Best SIP recommendations"
📈 **Portfolio Review**: "Review my investments"
🎓 **Learning**: "Explain P/E ratios"

Please try asking again! I'm powered by Google Gemini for the best investment insights.''';

      chatMessages.add(
        ChatMessage(
          text: errorResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      
      return errorResponse;
    } finally {
      isChatLoading.value = false;
      isTyping.value = false;
    }
  }

  /// Build user context for personalized AI responses
  String _buildUserContext(dynamic user) {
    if (user == null) return 'New user exploring investment options.';
    
    final context = StringBuffer();
    context.write('User profile: ');
    context.write('Risk tolerance: ${user.riskTolerance ?? "Medium"}, ');
    context.write('Experience: ${user.investmentExperience ?? "Beginner"}, ');
    
    if (user.portfolioSymbols != null && user.portfolioSymbols.isNotEmpty) {
      context.write('Current holdings: ${user.portfolioSymbols.join(", ")}, ');
    }
    
    if (user.investmentGoals != null && user.investmentGoals.isNotEmpty) {
      context.write('Goals: ${user.investmentGoals.join(", ")}, ');
    }
    
    if (user.portfolioValue != null && user.portfolioValue > 0) {
      context.write('Portfolio value: \$${user.portfolioValue.toStringAsFixed(0)}');
    }
    
    return context.toString();
  }

  /// Smart query detection methods
  bool _isStockAnalysisQuery(String query) {
    final lowerQuery = query.toLowerCase();
    final stockSymbols = ['aapl', 'googl', 'msft', 'tsla', 'nvda', 'amd', 'amzn', 'meta', 'nflx'];
    return stockSymbols.any((symbol) => lowerQuery.contains(symbol)) ||
           (lowerQuery.contains('analyze') && lowerQuery.contains('stock'));
  }

  bool _isPortfolioQuery(String query) {
    final lowerQuery = query.toLowerCase();
    return lowerQuery.contains('portfolio') || 
           lowerQuery.contains('my investments') ||
           lowerQuery.contains('my holdings');
  }

  bool _isMarketQuery(String query) {
    final lowerQuery = query.toLowerCase();
    return lowerQuery.contains('market') || 
           lowerQuery.contains('trends') ||
           lowerQuery.contains('outlook');
  }

  bool _isSIPQuery(String query) {
    final lowerQuery = query.toLowerCase();
    return lowerQuery.contains('sip') || 
           lowerQuery.contains('systematic') ||
           lowerQuery.contains('monthly invest');
  }

  bool _isRiskQuery(String query) {
    final lowerQuery = query.toLowerCase();
    return lowerQuery.contains('risk') && 
           (lowerQuery.contains('low') || 
            lowerQuery.contains('medium') || 
            lowerQuery.contains('high'));
  }

  bool _isSectorQuery(String query) {
    final lowerQuery = query.toLowerCase();
    final sectors = ['technology', 'healthcare', 'finance', 'energy', 'automotive', 'retail'];
    return sectors.any((sector) => lowerQuery.contains(sector));
  }

  /// Extract specific information from queries
  String _extractStockSymbol(String query) {
    final stockSymbols = ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'NVDA', 'AMD', 'AMZN', 'META', 'NFLX'];
    for (final symbol in stockSymbols) {
      if (query.toUpperCase().contains(symbol)) {
        return symbol;
      }
    }
    return 'AAPL'; // Default fallback
  }

  String _extractRiskLevel(String query) {
    final lowerQuery = query.toLowerCase();
    if (lowerQuery.contains('low risk')) return 'low';
    if (lowerQuery.contains('medium risk')) return 'medium';
    if (lowerQuery.contains('high risk')) return 'high';
    return 'medium';
  }

  String _extractSector(String query) {
    final lowerQuery = query.toLowerCase();
    final sectors = ['technology', 'healthcare', 'finance', 'energy', 'automotive', 'retail'];
    for (final sector in sectors) {
      if (lowerQuery.contains(sector)) {
        return sector;
      }
    }
    return 'technology';
  }

  /// Clear chat messages
  void clearChat() {
    chatMessages.clear();
    chatHistory.clear();
    _initializeChat();
  }

  /// Send quick predefined questions
  Future<void> sendQuickQuestion(String question) async {
    await getChatResponse(question);
  }

  /// Get conversation summary
  String getChatSummary() {
    if (chatMessages.isEmpty) return 'No conversation yet';
    
    final userMessages = chatMessages.where((msg) => msg.isUser).length;
    final aiMessages = chatMessages.where((msg) => !msg.isUser).length;
    
    return 'Conversation: $userMessages questions, $aiMessages responses';
  }

  /// Export chat history
  List<Map<String, dynamic>> exportChatHistory() {
    return chatMessages.map((msg) => {
      'text': msg.text,
      'isUser': msg.isUser,
      'timestamp': msg.timestamp.toIso8601String(),
    }).toList();
  }

  // === EXISTING METHODS (Keep all your existing functionality) ===

  /// Load all AI recommendations
  Future<void> loadRecommendations() async {
    isLoading.value = true;
    
    try {
      final sipRecs = await _aiService.getSIPRecommendations();
      final oneTimeRecs = await _aiService.getOneTimeInvestmentRecommendations();
      
      sipRecommendations.value = sipRecs;
      oneTimeRecommendations.value = oneTimeRecs;
      
      await loadPersonalizedRecommendations();
      
      Get.snackbar(
        'AI Recommendations Updated',
        'Latest investment insights loaded successfully',
        backgroundColor: const Color(0xFF00D4AA),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error loading recommendations: $e');
      Get.snackbar(
        'Error', 
        'Failed to load recommendations. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPersonalizedRecommendations() async {
    try {
      final user = _authService.currentUser.value;
      if (user == null) return;

      final riskTolerance = user.riskTolerance;
      final experience = user.investmentExperience;
      final portfolioValue = user.portfolioValue;
      
      final personalizedRecs = await _aiService.getPersonalizedRecommendations(
        riskTolerance: riskTolerance,
        investmentExperience: experience,
        portfolioValue: portfolioValue,
        investmentGoals: user.investmentGoals,
      );
      
      personalizedRecommendations.value = personalizedRecs;
    } catch (e) {
      print('Error loading personalized recommendations: $e');
    }
  }

  Future<void> loadMarketInsights() async {
    try {
      final insights = await _aiService.getMarketInsights();
      marketInsights.value = insights;
    } catch (e) {
      print('Error loading market insights: $e');
      marketInsights.value = '''📊 **Market Overview**

Stay tuned for the latest market insights powered by AI. 

In the meantime, explore our AI recommendations for:
• Long-term SIP investments
• Short-term trading opportunities  
• Sector-specific picks
• Risk-based portfolios''';
    }
  }

  Future<String> analyzeStock(String symbol) async {
    isAnalyzing.value = true;
    
    try {
      final analysis = await _aiService.analyzeStock(symbol);
      currentAnalysis.value = analysis;
      return analysis;
    } catch (e) {
      print('Error analyzing stock: $e');
      return 'Unable to analyze $symbol at the moment. Please try again later.';
    } finally {
      isAnalyzing.value = false;
    }
  }

  Future<String> getPortfolioReview() async {
    try {
      final user = _authService.currentUser.value;
      if (user == null) {
        return 'Please log in to get a personalized portfolio review.';
      }

      final userStocks = user.portfolioSymbols;
      if (userStocks == null || userStocks.isEmpty) {
        return '''📈 **Portfolio Review**

You don't have any stocks in your portfolio yet. Here's how to get started:

1. **Research stocks** using our AI recommendations
2. **Start with SIP** for consistent investing
3. **Diversify** across different sectors
4. **Monitor regularly** and rebalance quarterly

Would you like me to recommend some starter stocks for your portfolio?''';
      }

      final portfolioValue = user.portfolioValue ?? 0.0;
      return await _aiService.reviewPortfolio(userStocks, portfolioValue);
    } catch (e) {
      print('Error getting portfolio review: $e');
      return 'Unable to review portfolio at the moment. Please try again later.';
    }
  }

  // Keep all your existing filter methods
  void filterByRisk(String riskLevel) {
    selectedRiskLevel.value = riskLevel;
    if (riskLevel == 'All') {
      loadRecommendations();
      return;
    }
    _filterRecommendations();
  }

  void filterBySector(String sector) {
    selectedSector.value = sector;
    if (sector == 'All') {
      loadRecommendations();
      return;
    }
    _filterRecommendations();
  }

  void filterByTimeframe(String timeframe) {
    selectedTimeframe.value = timeframe;
    if (timeframe == 'All') {
      loadRecommendations();
      return;
    }
    _filterRecommendations();
  }

  void _filterRecommendations() async {
    isLoading.value = true;
    
    try {
      List<AIRecommendation> filteredSIP = [];
      List<AIRecommendation> filteredOneTime = [];
      
      final allSIP = await _aiService.getSIPRecommendations();
      final allOneTime = await _aiService.getOneTimeInvestmentRecommendations();
      
      if (selectedRiskLevel.value != 'All') {
        filteredSIP = allSIP.where((rec) => 
          rec.computedRiskLevel.toLowerCase() == selectedRiskLevel.value.toLowerCase()
        ).toList();
        filteredOneTime = allOneTime.where((rec) => 
          rec.computedRiskLevel.toLowerCase() == selectedRiskLevel.value.toLowerCase()
        ).toList();
      } else {
        filteredSIP = allSIP;
        filteredOneTime = allOneTime;
      }
      
      if (selectedSector.value != 'All') {
        filteredSIP = filteredSIP.where((rec) => 
          rec.sector?.toLowerCase() == selectedSector.value.toLowerCase()
        ).toList();
        filteredOneTime = filteredOneTime.where((rec) => 
          rec.sector?.toLowerCase() == selectedSector.value.toLowerCase()
        ).toList();
      }
      
      if (selectedTimeframe.value != 'All') {
        if (selectedTimeframe.value == 'Short-term') {
          filteredSIP = filteredSIP.where((rec) => 
            rec.timeframe.contains('1') || rec.timeframe.contains('2')
          ).toList();
          filteredOneTime = filteredOneTime.where((rec) => 
            rec.timeframe.contains('1') || rec.timeframe.contains('2')
          ).toList();
        } else if (selectedTimeframe.value == 'Long-term') {
          filteredSIP = filteredSIP.where((rec) => 
            rec.timeframe.contains('5') || rec.timeframe.contains('year')
          ).toList();
          filteredOneTime = filteredOneTime.where((rec) => 
            rec.timeframe.contains('5') || rec.timeframe.contains('year')
          ).toList();
        }
      }
      
      sipRecommendations.value = filteredSIP;
      oneTimeRecommendations.value = filteredOneTime;
      
    } catch (e) {
      print('Error filtering recommendations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void clearFilters() {
    selectedRiskLevel.value = 'All';
    selectedSector.value = 'All';
    selectedTimeframe.value = 'All';
    loadRecommendations();
  }

  Future<String> getSectorAnalysis(String sector) async {
    try {
      return await _aiService.getSectorAnalysis(sector);
    } catch (e) {
      print('Error getting sector analysis: $e');
      return 'Unable to analyze $sector sector at the moment. Please try again later.';
    }
  }

  Future<String> getRiskBasedAdvice(String riskLevel) async {
    try {
      return await _aiService.getRiskBasedAdvice(riskLevel);
    } catch (e) {
      print('Error getting risk-based advice: $e');
      return 'Unable to provide risk-based advice at the moment. Please try again later.';
    }
  }

  AIRecommendation? getRecommendationBySymbol(String symbol) {
    try {
      final sipRec = sipRecommendations.firstWhere(
        (rec) => rec.symbol.toUpperCase() == symbol.toUpperCase(),
      );
      return sipRec;
    } catch (e) {
      try {
        final oneTimeRec = oneTimeRecommendations.firstWhere(
          (rec) => rec.symbol.toUpperCase() == symbol.toUpperCase(),
        );
        return oneTimeRec;
      } catch (e) {
        return null;
      }
    }
  }

  List<AIRecommendation> get allRecommendations {
    return [...sipRecommendations, ...oneTimeRecommendations];
  }

  List<AIRecommendation> get topRecommendations {
    final all = allRecommendations;
    all.sort((a, b) => b.confidence.compareTo(a.confidence));
    return all.take(5).toList();
  }

  List<AIRecommendation> get highRiskRecommendations {
    return allRecommendations
        .where((rec) => rec.computedRiskLevel == 'High')
        .toList();
  }

  List<AIRecommendation> get conservativeRecommendations {
    return allRecommendations
        .where((rec) => rec.computedRiskLevel == 'Low' || rec.computedRiskLevel == 'Medium')
        .toList();
  }

  List<String> get availableRiskLevels {
    final risks = allRecommendations
        .map((rec) => rec.computedRiskLevel)
        .toSet()
        .toList();
    return ['All', ...risks];
  }

  List<String> get availableSectors {
    final sectors = allRecommendations
        .where((rec) => rec.sector != null)
        .map((rec) => rec.sector!)
        .toSet()
        .toList();
    return ['All', ...sectors];
  }

  void clearChatHistory() {
    chatHistory.clear();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadRecommendations(),
      loadMarketInsights(),
      loadPersonalizedRecommendations(),
    ]);
    
    Get.snackbar(
      'Data Refreshed',
      'All AI insights have been updated with the latest information',
      backgroundColor: const Color(0xFF00D4AA),
      colorText: Colors.white,
    );
  }

  void debugAIStatus() {
    print('=== AI Controller Debug ===');
    print('SIP Recommendations: ${sipRecommendations.length}');
    print('One-Time Recommendations: ${oneTimeRecommendations.length}');
    print('Personalized Recommendations: ${personalizedRecommendations.length}');
    print('Chat Messages: ${chatMessages.length}');
    print('Is Loading: ${isLoading.value}');
    print('Is Chat Loading: ${isChatLoading.value}');
    print('Chat History Length: ${chatHistory.length}');
    print('Selected Filters: Risk=${selectedRiskLevel.value}, Sector=${selectedSector.value}');
    print('==========================');
  }
}