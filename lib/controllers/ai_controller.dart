import 'package:get/get.dart';
import '../models/ai_recommendation_model.dart';
import '../services/ai_service.dart';

class AIController extends GetxController {
  final AIService _aiService = Get.find<AIService>();
  
  RxList<AIRecommendation> sipRecommendations = <AIRecommendation>[].obs;
  RxList<AIRecommendation> oneTimeRecommendations = <AIRecommendation>[].obs;
  RxBool isLoading = false.obs;

  Future<void> loadRecommendations() async {
    isLoading.value = true;
    
    try {
      final sipRecs = await _aiService.getSIPRecommendations();
      final oneTimeRecs = await _aiService.getOneTimeInvestmentRecommendations();
      
      sipRecommendations.value = sipRecs;
      oneTimeRecommendations.value = oneTimeRecs;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load recommendations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> getChatResponse(String query) async {
    return await _aiService.getChatResponse(query);
  }
}
