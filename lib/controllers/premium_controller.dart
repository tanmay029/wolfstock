// lib/controllers/premium_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/premium_service.dart';
import '../services/auth_service.dart';

class PremiumController extends GetxController {
  final PremiumService _premiumService = Get.find<PremiumService>();
  final AuthService _authService = Get.find<AuthService>();
  
  RxString selectedPlan = 'yearly'.obs;
  RxBool isProcessing = false.obs;

  // Getters
  bool get isPremium => _premiumService.isPremiumUser;
  String? get currentPlan => _premiumService.currentPlan;
  int get daysUntilExpiry => _premiumService.daysUntilExpiry;
  bool get isExpiringSoon => _premiumService.isExpiringSoon;
  Map<String, dynamic>? get premiumBadge => _premiumService.premiumBadge;

  // Available plans
  Map<String, Map<String, dynamic>> get plans => PremiumService.subscriptionPlans;
  
  // Premium features
  List<String> get premiumFeatures => PremiumService.premiumFeatures;

  /// CRITICAL: Refresh premium status and trigger UI update (needed for post-payment updates)
  Future<void> refreshPremiumStatus() async {
    try {
      print('Refreshing premium status...');
      
      // Force refresh user data from Firestore
      await _authService.refreshCurrentUser();
      
      // Force update all GetBuilder widgets
      update();
      
      // Debug the refreshed state
      print('Premium status after refresh: $isPremium');
      print('Current plan after refresh: $currentPlan');
      
    } catch (e) {
      print('Error refreshing premium status: $e');
    }
  }

  /// Purchase premium subscription with Razorpay ONLY
  Future<void> purchasePremiumWithRazorpay(String planType) async {
    print('PremiumController.purchasePremiumWithRazorpay called with: $planType');
    
    if (isProcessing.value) {
      print('Already processing payment, ignoring request');
      return;
    }
    
    // Validate payment setup first
    if (!_premiumService.validatePaymentSetup()) {
      Get.snackbar(
        'Payment Error',
        'Payment system is not properly configured. Please restart the app and try again.',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 5),
      );
      return;
    }
    
    isProcessing.value = true;
    
    try {
      await _premiumService.purchasePremiumWithRazorpay(planType);
      // Note: Success handling is done in Razorpay callback
      print('Razorpay payment initiated successfully');
    } catch (e) {
      print('Error in purchasePremiumWithRazorpay: $e');
      Get.snackbar(
        'Payment Error', 
        'Failed to initiate payment: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isProcessing.value = false;
    }
  }

  /// Restore premium subscription - only works with real payment history
  Future<void> restorePremium() async {
    if (isProcessing.value) return;
    
    isProcessing.value = true;
    
    try {
      final success = await _premiumService.restorePremium();
      if (success) {
        await refreshPremiumStatus(); // Use the new refresh method
      }
    } catch (e) {
      print('Error restoring premium: $e');
      Get.snackbar('Error', 'Failed to restore subscription: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Cancel premium subscription
  Future<void> cancelPremium() async {
    if (isProcessing.value) return;
    
    isProcessing.value = true;
    
    try {
      await _premiumService.cancelPremium();
      await refreshPremiumStatus(); // Use the new refresh method
    } catch (e) {
      print('Error cancelling premium: $e');
      Get.snackbar('Error', 'Failed to cancel subscription: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Check if user has access to a feature
  bool hasFeature(String feature) {
    return _premiumService.hasFeature(feature);
  }

  /// Check feature access and show dialog if needed
  bool checkFeatureAccess(String feature, {bool showDialog = true}) {
    return _premiumService.checkFeatureAccess(feature, showDialog: showDialog);
  }

  /// Get premium statistics
  Map<String, dynamic> get premiumStats => _premiumService.getPremiumStats();

  /// Get recommended plan
  String get recommendedPlan {
    if (isPremium) return currentPlan ?? 'yearly';
    return 'yearly'; // Yearly plan offers best value
  }

  /// Calculate savings for yearly plan
  double get yearlySavings {
    final monthly = plans['monthly']?['price'] ?? 0.0;
    final yearly = plans['yearly']?['price'] ?? 0.0;
    return (monthly * 12) - yearly;
  }

  /// Get formatted savings amount
  String get formattedYearlySavings {
    return _premiumService.getYearlySavings();
  }

  /// Check if Razorpay payment system is available
  bool get isPaymentSystemAvailable => _premiumService.isRazorpayAvailable;

  /// Validate if the user can make a payment
  bool canMakePayment() {
    if (isPremium) {
      Get.snackbar(
        'Already Premium',
        'You already have an active premium subscription.',
        backgroundColor: Get.theme.colorScheme.secondary,
        colorText: Get.theme.colorScheme.onSecondary,
      );
      return false;
    }

    if (!isPaymentSystemAvailable) {
      Get.snackbar(
        'Payment Unavailable',
        'Payment system is not available. Please restart the app and try again.',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }

    return true;
  }

  /// Handle payment button press with validation
  Future<void> handlePaymentRequest(String planType) async {
    print('Payment request for plan: $planType');
    
    // Validate before processing
    if (!canMakePayment()) {
      return;
    }

    // Show confirmation dialog for expensive plans
    if (planType == 'lifetime' && plans[planType]!['price'] > 20000) {
      final confirmed = await _showPaymentConfirmation(planType);
      if (!confirmed) {
        print('Payment cancelled by user');
        return;
      }
    }

    // Process payment
    await purchasePremiumWithRazorpay(planType);
  }

  /// Show payment confirmation dialog for expensive plans
  Future<bool> _showPaymentConfirmation(String planType) async {
    final plan = plans[planType];
    if (plan == null) return false;

    return await Get.dialog<bool>(
      AlertDialog(
        title: Text('Confirm ${plan['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to purchase:'),
            const SizedBox(height: 8),
            Text(
              '${plan['name']} - ₹${plan['price'].toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('This will give you access to all premium features.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
            ),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Debug method to check controller status
  void debugControllerStatus() {
    print('=== Premium Controller Debug ===');
    print('Is Premium: $isPremium');
    print('Current Plan: $currentPlan');
    print('Selected Plan: ${selectedPlan.value}');
    print('Is Processing: ${isProcessing.value}');
    print('Payment System Available: $isPaymentSystemAvailable');
    print('Days Until Expiry: $daysUntilExpiry');
    print('Is Expiring Soon: $isExpiringSoon');
    print('==============================');
  }

  /// Method to handle post-payment success (called from Razorpay callback)
  void onPaymentSuccess(String planType, String paymentId) async {
    print('Payment success callback - Plan: $planType, Payment ID: $paymentId');
    
    // Force refresh premium status
    await refreshPremiumStatus();
    
    // Reset processing state
    isProcessing.value = false;
    
    // Show success message (optional, as Razorpay service already shows one)
    Get.snackbar(
      'Payment Successful! 🎉',
      'Your premium subscription is now active!',
      backgroundColor: const Color(0xFF00D4AA),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Method to handle payment failure (called from Razorpay callback)
  void onPaymentFailure(String error) {
    print('Payment failure callback - Error: $error');
    
    // Reset processing state
    isProcessing.value = false;
    
    // Update UI
    update();
  }

  /// Force refresh all premium-related data (useful for manual refresh)
  Future<void> forceRefresh() async {
    try {
      isProcessing.value = true;
      await refreshPremiumStatus();
      
      Get.snackbar(
        'Refreshed',
        'Premium status updated successfully',
        backgroundColor: const Color(0xFF00D4AA),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to refresh: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Listen to premium status changes (reactive updates)
  void listenToPremiumChanges() {
    ever(_authService.currentUser, (user) {
      if (user != null) {
        update(); // Trigger UI updates when user data changes
        print('User data changed - Premium status: ${user.hasActivePremium}');
      }
    });
  }

  /// Get premium status stream for reactive widgets
  Stream<bool> get premiumStatusStream {
    return _authService.currentUser.stream
        .map((user) => user?.hasActivePremium ?? false)
        .distinct(); // Only emit when status actually changes
  }

  /// Check if user's premium has expired and needs renewal
  bool get needsRenewal {
    if (!isPremium) return false;
    return isExpiringSoon || daysUntilExpiry <= 7;
  }

  /// Get renewal urgency level
  String get renewalUrgency {
    if (!needsRenewal) return 'none';
    if (daysUntilExpiry <= 1) return 'critical';
    if (daysUntilExpiry <= 3) return 'urgent';
    if (daysUntilExpiry <= 7) return 'reminder';
    return 'none';
  }

  @override
  void onInit() {
    super.onInit();
    
    // Set up reactive listeners
    listenToPremiumChanges();
    
    // Debug payment system status on init
    if (Get.testMode || Get.isLogEnable) {
      debugControllerStatus();
    }
  }

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}
