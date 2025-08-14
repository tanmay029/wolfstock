// lib/services/ai_service.dart (Updated)
// import 'dart:math';
import 'package:get/get.dart';
import '../models/ai_recommendation_model.dart';
// import '../models/stock_model.dart';

class AIService extends GetxService {
  // final Random _random = Random();

  Future<List<AIRecommendation>> getSIPRecommendations() async {
    // Mock AI recommendations for SIP investments
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    
    final mockSIPStocks = [
      {
        'symbol': 'AAPL',
        'name': 'Apple Inc.',
        'currentPrice': 175.50,
        'projectedReturn': 12.5,
        'timeframe': '5 years',
        'reasoning': 'Strong ecosystem, consistent innovation, and growing services revenue make AAPL ideal for long-term SIP investment.',
        'confidence': 0.85,
        'pros': ['Market leader in premium smartphones', 'Strong brand loyalty', 'Growing services revenue'],
        'cons': ['High valuation', 'Regulatory challenges', 'Market saturation'],
        'riskLevel': 'Medium',
        'minimumInvestment': 1000.0,
        'sector': 'Technology'
      },
      {
        'symbol': 'GOOGL',
        'name': 'Alphabet Inc.',
        'currentPrice': 125.30,
        'projectedReturn': 15.2,
        'timeframe': '3-5 years',
        'reasoning': 'Dominant position in search and advertising, with strong AI capabilities and cloud growth potential.',
        'confidence': 0.82,
        'pros': ['Search market dominance', 'AI leadership', 'Cloud growth'],
        'cons': ['Regulatory scrutiny', 'Competition in cloud', 'Ad spending volatility'],
        'riskLevel': 'Medium',
        'minimumInvestment': 500.0,
        'sector': 'Technology'
      },
      {
        'symbol': 'MSFT',
        'name': 'Microsoft Corporation',
        'currentPrice': 338.50,
        'projectedReturn': 11.8,
        'timeframe': '5+ years',
        'reasoning': 'Leading cloud provider with strong enterprise relationships and growing AI integration across products.',
        'confidence': 0.88,
        'pros': ['Cloud market leadership', 'Enterprise dominance', 'AI integration'],
        'cons': ['High competition', 'Market maturity', 'Valuation concerns'],
        'riskLevel': 'Low',
        'minimumInvestment': 1500.0,
        'sector': 'Technology'
      }
    ];

    return mockSIPStocks.map((stock) => AIRecommendation(
      symbol: stock['symbol'] as String,
      name: stock['name'] as String,
      type: 'SIP',
      currentPrice: stock['currentPrice'] as double,
      projectedReturn: stock['projectedReturn'] as double,
      timeframe: stock['timeframe'] as String,
      reasoning: stock['reasoning'] as String,
      confidence: stock['confidence'] as double,
      pros: List<String>.from(stock['pros'] as List),
      cons: List<String>.from(stock['cons'] as List),
      createdAt: DateTime.now(), // Add this required parameter
      riskLevel: stock['riskLevel'] as String?,
      minimumInvestment: stock['minimumInvestment'] as double?,
      sector: stock['sector'] as String?,
    )).toList();
  }

  Future<List<AIRecommendation>> getOneTimeInvestmentRecommendations() async {
    await Future.delayed(const Duration(seconds: 1));
    
    final mockOneTimeStocks = [
      {
        'symbol': 'TSLA',
        'name': 'Tesla Inc.',
        'currentPrice': 245.80,
        'projectedReturn': 25.0,
        'timeframe': '1-2 years',
        'reasoning': 'Benefiting from EV adoption and energy storage growth. Recent price correction creates opportunity.',
        'confidence': 0.75,
        'pros': ['EV market leader', 'Energy storage growth', 'Recent correction'],
        'cons': ['High volatility', 'Execution risk', 'Competition increasing'],
        'riskLevel': 'High',
        'minimumInvestment': 2000.0,
        'sector': 'Automotive'
      },
      {
        'symbol': 'NVDA',
        'name': 'NVIDIA Corporation',
        'currentPrice': 421.13,
        'projectedReturn': 30.0,
        'timeframe': '6-18 months',
        'reasoning': 'AI boom driving massive demand for GPU chips. Market leader in AI infrastructure.',
        'confidence': 0.80,
        'pros': ['AI market leadership', 'Strong moat', 'Growing demand'],
        'cons': ['High volatility', 'Cyclical business', 'Valuation risk'],
        'riskLevel': 'High',
        'minimumInvestment': 2500.0,
        'sector': 'Technology'
      },
      {
        'symbol': 'AMD',
        'name': 'Advanced Micro Devices',
        'currentPrice': 102.65,
        'projectedReturn': 22.0,
        'timeframe': '1-2 years',
        'reasoning': 'Strong competition to Intel in CPU market and growing data center presence.',
        'confidence': 0.72,
        'pros': ['Market share gains', 'Data center growth', 'Competitive products'],
        'cons': ['Intel competition', 'Cyclical industry', 'Execution risk'],
        'riskLevel': 'Medium',
        'minimumInvestment': 1000.0,
        'sector': 'Technology'
      }
    ];

    return mockOneTimeStocks.map((stock) => AIRecommendation(
      symbol: stock['symbol'] as String,
      name: stock['name'] as String,
      type: 'OneTime',
      currentPrice: stock['currentPrice'] as double,
      projectedReturn: stock['projectedReturn'] as double,
      timeframe: stock['timeframe'] as String,
      reasoning: stock['reasoning'] as String,
      confidence: stock['confidence'] as double,
      pros: List<String>.from(stock['pros'] as List),
      cons: List<String>.from(stock['cons'] as List),
      createdAt: DateTime.now(), // Add this required parameter
      riskLevel: stock['riskLevel'] as String?,
      minimumInvestment: stock['minimumInvestment'] as double?,
      sector: stock['sector'] as String?,
    )).toList();
  }

  Future<String> getChatResponse(String query) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Simple mock chatbot responses
    query = query.toLowerCase();
    
    if (query.contains('sip') || query.contains('systematic')) {
      return "For SIP investments, I recommend focusing on fundamentally strong companies like Apple (AAPL), Microsoft (MSFT), and Alphabet (GOOGL). These offer steady growth potential over 3-5 years with projected returns of 12-15%. SIP allows you to benefit from dollar-cost averaging and reduces timing risk.";
    } else if (query.contains('short term') || query.contains('1 year')) {
      return "For short-term investments (1-2 years), consider high-growth stocks like Tesla (TSLA) and NVIDIA (NVDA) which have potential for 25-30% returns due to EV adoption and AI boom, though they come with higher risk and volatility.";
    } else if (query.contains('long term') || query.contains('5 year')) {
      return "For long-term investments (5+ years), technology giants like Apple, Microsoft, and Google offer the best risk-adjusted returns. These companies have strong moats, consistent cash flow, and are well-positioned for future growth. Consider dollar-cost averaging through SIP for better results.";
    } else if (query.contains('ai') || query.contains('artificial intelligence')) {
      return "AI is transforming multiple industries. Top AI investment picks include NVIDIA (GPU leader), Microsoft (Azure AI), Google (AI research), and Tesla (autonomous driving). These stocks benefit from the AI revolution but carry higher volatility.";
    } else if (query.contains('risk') || query.contains('volatile')) {
      return "Risk tolerance is crucial for investment success. Low-risk options include Microsoft and Apple (stable growth), Medium-risk includes Google and AMD (growth with some volatility), High-risk includes Tesla and NVIDIA (high growth potential but very volatile). Diversification is key.";
    } else if (query.contains('portfolio') || query.contains('diversif')) {
      return "A well-diversified portfolio should include: 40% large-cap stable stocks (AAPL, MSFT), 30% growth stocks (GOOGL, NVDA), 20% emerging sectors (TSLA, AMD), and 10% defensive positions. This balances growth potential with risk management.";
    } else {
      return "I can help you choose stocks based on your investment timeframe and risk tolerance. Are you looking for:\n• Short-term opportunities (1-2 years)\n• Long-term growth (3-5+ years)\n• SIP investments for regular investing\n• High-growth AI stocks\n• Low-risk stable investments\n\nWhat interests you most?";
    }
  }

  // Additional utility methods for the AI service
  Future<AIRecommendation?> getStockRecommendation(String symbol) async {
    final sipRecs = await getSIPRecommendations();
    final oneTimeRecs = await getOneTimeInvestmentRecommendations();
    
    final allRecs = [...sipRecs, ...oneTimeRecs];
    
    try {
      return allRecs.firstWhere((rec) => rec.symbol.toUpperCase() == symbol.toUpperCase());
    } catch (e) {
      return null;
    }
  }

  Future<List<AIRecommendation>> getRecommendationsByRisk(String riskLevel) async {
    final sipRecs = await getSIPRecommendations();
    final oneTimeRecs = await getOneTimeInvestmentRecommendations();
    
    final allRecs = [...sipRecs, ...oneTimeRecs];
    
    return allRecs.where((rec) => rec.computedRiskLevel.toLowerCase() == riskLevel.toLowerCase()).toList();
  }

  Future<List<AIRecommendation>> getRecommendationsBySector(String sector) async {
    final sipRecs = await getSIPRecommendations();
    final oneTimeRecs = await getOneTimeInvestmentRecommendations();
    
    final allRecs = [...sipRecs, ...oneTimeRecs];
    
    return allRecs.where((rec) => rec.sector?.toLowerCase() == sector.toLowerCase()).toList();
  }

  // Get personalized recommendations based on user profile
  Future<List<AIRecommendation>> getPersonalizedRecommendations({
    String? riskTolerance,
    String? investmentExperience,
    double? portfolioValue,
    List<String>? investmentGoals,
  }) async {
    final sipRecs = await getSIPRecommendations();
    final oneTimeRecs = await getOneTimeInvestmentRecommendations();
    
    List<AIRecommendation> recommendations = [];
    
    // Filter based on risk tolerance
    if (riskTolerance != null) {
      if (riskTolerance.toLowerCase() == 'low') {
        recommendations.addAll(sipRecs.where((rec) => rec.confidence >= 0.8));
      } else if (riskTolerance.toLowerCase() == 'medium') {
        recommendations.addAll([...sipRecs, ...oneTimeRecs.where((rec) => rec.confidence >= 0.7)]);
      } else {
        recommendations.addAll([...sipRecs, ...oneTimeRecs]);
      }
    } else {
      recommendations.addAll([...sipRecs, ...oneTimeRecs]);
    }
    
    // Filter based on investment experience
    if (investmentExperience != null) {
      if (investmentExperience.toLowerCase() == 'beginner') {
        recommendations = recommendations.where((rec) => rec.computedRiskLevel != 'High').toList();
      }
    }
    
    // Sort by confidence and projected return
    recommendations.sort((a, b) {
      final confidenceCompare = b.confidence.compareTo(a.confidence);
      if (confidenceCompare != 0) return confidenceCompare;
      return b.projectedReturn.compareTo(a.projectedReturn);
    });
    
    return recommendations.take(10).toList();
  }
}
