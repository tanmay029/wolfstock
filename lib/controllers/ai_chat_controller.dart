// // lib/controllers/ai_chat_controller.dart (Enhanced for Gemini)
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../services/ai_service.dart';
// import '../services/auth_service.dart';

// class Message {
//   final String text;
//   final bool isUser;
//   final DateTime timestamp;
//   final bool isTyping;

//   Message({
//     required this.text,
//     required this.isUser,
//     required this.timestamp,
//     this.isTyping = false,
//   });
// }

// class AIChatController extends GetxController {
//   final AIService _aiService = Get.find<AIService>();
//   final AuthService _authService = Get.find<AuthService>();
//   final TextEditingController messageController = TextEditingController();
  
//   RxList<Message> messages = <Message>[].obs;
//   RxBool isLoading = false.obs;
//   RxBool isTyping = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     _addWelcomeMessage();
//   }

//   void _addWelcomeMessage() {
//     final userName = _authService.currentUser.value?.displayName?.split(' ').first ?? 'Investor';
//     messages.add(
//       Message(
//         text: '''👋 Hello $userName! I'm your **WolfStock AI Assistant** powered by Google Gemini.

// I provide real-time investment insights and can help you with:

// 📊 **Market Analysis** - Live trends and opportunities  
// 🔍 **Stock Research** - Individual stock deep-dives (AAPL, NVDA, TSLA, etc.)
// 💰 **SIP Planning** - Systematic investment strategies
// 📈 **Portfolio Review** - Optimization and diversification
// 🎓 **Investment Education** - Learning and best practices

// **Try these commands**:
// • "Analyze AAPL stock"
// • "Current market trends"  
// • "Best SIP recommendations"
// • "Review my portfolio"
// • "AI investment opportunities"

// What would you like to explore today?''',
//         isUser: false,
//         timestamp: DateTime.now(),
//       ),
//     );
//   }

//   Future<void> sendMessage(String text) async {
//     if (text.trim().isEmpty) return;

//     // Add user message
//     messages.add(
//       Message(
//         text: text,
//         isUser: true,
//         timestamp: DateTime.now(),
//       ),
//     );

//     messageController.clear();
//     isLoading.value = true;
//     isTyping.value = true;

//     // Add typing indicator
//     messages.add(
//       Message(
//         text: 'WolfStock AI is analyzing your request...',
//         isUser: false,
//         timestamp: DateTime.now(),
//         isTyping: true,
//       ),
//     );

//     try {
//       String response;
      
//       // Get user's portfolio for context
//       final userStocks = _authService.currentUser.value?.portfolioSymbols ?? [];
      
//       // Smart routing to appropriate AI methods
//       if (text.toLowerCase().contains('portfolio') && userStocks.isNotEmpty) {
//         final portfolioValue = _calculatePortfolioValue(userStocks);
//         response = await _aiService.reviewPortfolio(userStocks, portfolioValue);
//       } else if (_isStockQuery(text)) {
//         final symbol = _extractStockSymbol(text);
//         response = await _aiService.analyzeStock(symbol);
//       } else if (text.toLowerCase().contains('market') || text.toLowerCase().contains('trend')) {
//         response = await _aiService.getMarketInsights();
//       } else if (text.toLowerCase().contains('sip') || text.toLowerCase().contains('systematic')) {
//         response = await _aiService.getChatResponse('Provide SIP investment recommendations with monthly amounts and strategy');
//       } else if (_isRiskQuery(text)) {
//         final riskLevel = _extractRiskLevel(text);
//         response = await _aiService.getRiskBasedAdvice(riskLevel);
//       } else if (_isSectorQuery(text)) {
//         final sector = _extractSector(text);
//         response = await _aiService.getSectorAnalysis(sector);
//       } else {
//         // General query with user context
//         response = await _aiService.getPersonalizedAdvice(text, userStocks);
//       }

//       // Remove typing indicator
//       messages.removeWhere((msg) => msg.isTyping);
      
//       // Add AI response
//       messages.add(
//         Message(
//           text: response,
//           isUser: false,
//           timestamp: DateTime.now(),
//         ),
//       );
//     } catch (e) {
//       messages.removeWhere((msg) => msg.isTyping);
      
//       messages.add(
//         Message(
//           text: '''🤖 **WolfStock AI**

// I apologize for the temporary issue. Here are some quick options:

// 📊 **Market Insights**: "What are today's market trends?"
// 🔍 **Stock Analysis**: "Analyze AAPL stock" 
// 💰 **Investment Planning**: "Best SIP recommendations"
// 📈 **Portfolio Help**: "Review my portfolio"

// Please try asking again! I'm powered by Google Gemini for the best investment insights.''',
//           isUser: false,
//           timestamp: DateTime.now(),
//         ),
//       );
//     } finally {
//       isLoading.value = false;
//       isTyping.value = false;
//     }
//   }

//   // Helper methods for intelligent query routing
//   bool _isStockQuery(String text) {
//     final stockSymbols = ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'NVDA', 'AMD', 'AMZN', 'META', 'NFLX', 'ORCL'];
//     return stockSymbols.any((symbol) => 
//       text.toUpperCase().contains(symbol) || 
//       text.toLowerCase().contains('analyze') && text.toLowerCase().contains('stock')
//     );
//   }

//   String _extractStockSymbol(String text) {
//     final stockSymbols = ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'NVDA', 'AMD', 'AMZN', 'META', 'NFLX', 'ORCL'];
//     for (final symbol in stockSymbols) {
//       if (text.toUpperCase().contains(symbol)) {
//         return symbol;
//       }
//     }
//     return 'AAPL'; // Default fallback
//   }

//   bool _isRiskQuery(String text) {
//     return text.toLowerCase().contains('risk') && 
//            (text.toLowerCase().contains('low') || 
//             text.toLowerCase().contains('medium') || 
//             text.toLowerCase().contains('high'));
//   }

//   String _extractRiskLevel(String text) {
//     if (text.toLowerCase().contains('low risk')) return 'low';
//     if (text.toLowerCase().contains('medium risk')) return 'medium';
//     if (text.toLowerCase().contains('high risk')) return 'high';
//     return 'medium';
//   }

//   bool _isSectorQuery(String text) {
//     final sectors = ['technology', 'healthcare', 'finance', 'energy', 'automotive'];
//     return sectors.any((sector) => text.toLowerCase().contains(sector));
//   }

//   String _extractSector(String text) {
//     final sectors = ['technology', 'healthcare', 'finance', 'energy', 'automotive'];
//     for (final sector in sectors) {
//       if (text.toLowerCase().contains(sector)) {
//         return sector;
//       }
//     }
//     return 'technology';
//   }

//   double _calculatePortfolioValue(List<String> stocks) {
//     // Mock calculation - replace with real portfolio values
//     return stocks.length * 5000.0; // $5k per stock average
//   }

//   void sendQuickQuestion(String question) {
//     sendMessage(question);
//   }

//   void clearChat() {
//     messages.clear();
//     _addWelcomeMessage();
//   }

//   @override
//   void onClose() {
//     messageController.dispose();
//     super.onClose();
//   }
// }
