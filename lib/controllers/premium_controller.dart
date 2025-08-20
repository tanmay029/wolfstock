// lib/controllers/premium_controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wolfstock/models/user_model.dart';
import '../services/premium_service.dart';
import '../services/auth_service.dart';

class PremiumController extends GetxController {
  final PremiumService _premiumService = Get.find<PremiumService>();
  final AuthService _authService = Get.find<AuthService>();
  
  RxString selectedPlan = 'yearly'.obs;
  RxBool isProcessing = false.obs;

  // CRITICAL: Make premium status reactive
  RxBool isPremium = false.obs;
  RxString currentPlan = ''.obs;
  RxInt daysUntilExpiry = 0.obs;
  RxBool isExpiringSoon = false.obs;

  Timer? _debounceTimer;
  bool _isUpdating = false; // Prevent concurrent updates
  DateTime? _lastUpdateTime; // Track last successful update

  // Available plans
  Map<String, Map<String, dynamic>> get plans => PremiumService.subscriptionPlans;
  
  // Premium features
  List<String> get premiumFeatures => PremiumService.premiumFeatures;

  // Enhanced getters that use reactive variables
  Map<String, dynamic>? get premiumBadge => _premiumService.premiumBadge;

  /// Initialize reactive variables with current user data
  void initializeReactiveVariables() {
    final user = _authService.currentUser.value;
    
    print('🔧 Initializing reactive variables with user ');
    print('   User email: ${user?.email}');
    print('   User hasActivePremium: ${user?.hasActivePremium}');
    print('   User subscriptionPlan: ${user?.subscriptionPlan}');
    print('   Data timestamp: ${user?.lastUpdated}');
    
    // Only initialize if we have fresh data or no previous data
    if (_shouldAcceptUserData(user)) {
      isPremium.value = user?.hasActivePremium ?? false;
      currentPlan.value = user?.subscriptionPlan ?? '';
      daysUntilExpiry.value = user?.daysUntilPremiumExpiry ?? 0;
      isExpiringSoon.value = user?.isPremiumExpiringSoon ?? false;
      
      _lastUpdateTime = user?.lastUpdated;
      
      print('🔧 Reactive variables set to:');
      print('   isPremium: ${isPremium.value}');
      print('   currentPlan: ${currentPlan.value}');
    } else {
      print('🔧 Ignoring stale data during initialization');
    }
  }

  /// CRITICAL: More permissive data freshness validation
  bool _shouldAcceptUserData(UserModel? user) {
    if (user == null) {
      print('🔍 User is null, rejecting');
      return false;
    }

    // If user data has no timestamp, reject as potentially stale
    if (user.lastUpdated == null) {
      print('🔍 User data has no timestamp, rejecting as potentially stale');
      return false;
    }

    // If we have no previous update time, accept new data
    if (_lastUpdateTime == null) {
      print('🔍 No previous update time, accepting new data');
      return true;
    }

    // CRITICAL: Accept data that is newer OR EQUAL (same timestamp allowed)
    final isNewerOrEqual = !user.lastUpdated!.isBefore(_lastUpdateTime!);
    final timeDiff = user.lastUpdated!.difference(_lastUpdateTime!).inSeconds;
    
    print('🔍 Data freshness check:');
    print('   New timestamp: ${user.lastUpdated}');
    print('   Last timestamp: $_lastUpdateTime');
    print('   Time difference: ${timeDiff}s');
    print('   Is newer or equal: $isNewerOrEqual');
    
    return isNewerOrEqual; // Changed from isAfter() to allow equal timestamps
  }

  /// Listen to premium status changes with smart debouncing and filtering
  void _listenToPremiumChanges() {
    ever(_authService.currentUser, (UserModel? user) {
      // Skip if already processing an update
      if (_isUpdating) {
        print('👂 Skipping update - already processing');
        return;
      }
      
      print('👂 User data changed - Email: ${user?.email}');
      print('👂 Fresh data - isPremium: ${user?.hasActivePremium}');
      print('👂 Fresh data - plan: ${user?.subscriptionPlan}');
      print('👂 Data timestamp: ${user?.lastUpdated}');
      
      // CRITICAL: Filter out stale data
      if (!_shouldAcceptUserData(user)) {
        print('👂 Rejecting stale or invalid user data');
        return;
      }
      
      // Cancel previous debounce timer
      _debounceTimer?.cancel();
      
      // Debounce with 300ms delay (reduced from 500ms for faster response)
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _isUpdating = true;
        
        if (user != null) {
          print('📝 Applying fresh update:');
          
          // CRITICAL: Double-check data freshness (within last 60 seconds)
          final dataAge = DateTime.now().difference(user.lastUpdated!).inSeconds;
          
          if (dataAge <= 60) {
            // Update reactive variables
            isPremium.value = user.hasActivePremium;
            currentPlan.value = user.subscriptionPlan ?? '';
            daysUntilExpiry.value = user.daysUntilPremiumExpiry;
            isExpiringSoon.value = user.isPremiumExpiringSoon;
            
            // Track this successful update
            _lastUpdateTime = user.lastUpdated;
            
            update();
            
            print('📝 Updated - isPremium: ${isPremium.value}, plan: ${currentPlan.value}');
          } else {
            print('📝 Data too old (${dataAge}s), ignoring');
          }
        }
        
        _isUpdating = false;
      });
    });
  }

  /// CRITICAL: Enhanced refresh with better error handling
  Future<void> refreshPremiumStatus() async {
    try {
      print('🔄 Refreshing premium status...');
      
      // Force refresh user data from Firestore
      await _authService.refreshCurrentUser();
      
      // Wait a moment for the reactive listener to process
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Update reactive variables based on latest data
      final user = _authService.currentUser.value;
      
      if (_shouldAcceptUserData(user)) {
        isPremium.value = user?.hasActivePremium ?? false;
        currentPlan.value = user?.subscriptionPlan ?? '';
        daysUntilExpiry.value = user?.daysUntilPremiumExpiry ?? 0;
        isExpiringSoon.value = user?.isPremiumExpiringSoon ?? false;
        
        _lastUpdateTime = user?.lastUpdated;
        
        // Force update all GetBuilder widgets
        update();
        
        print('✅ Premium status refreshed successfully:');
        print('   isPremium: ${isPremium.value}');
        print('   currentPlan: ${currentPlan.value}');
        print('   dataTimestamp: ${user?.lastUpdated}');
      } else {
        print('⚠️ Refresh completed but received stale data');
      }
      
    } catch (e) {
      print('❌ Error refreshing premium status: $e');
    }
  }

  /// CRITICAL: Override for successful payment - bypasses all timestamp checks
  void confirmPaymentSuccess(String planType) {
    print('💳 Confirming payment success for plan: $planType');
    
    // Force update regardless of timestamps
    isPremium.value = true;
    currentPlan.value = planType;
    
    // Calculate days until expiry based on plan
    final plan = plans[planType];
    if (plan != null && planType != 'lifetime') {
      final expiryDate = DateTime.now().add(Duration(days: plan['duration']));
      daysUntilExpiry.value = expiryDate.difference(DateTime.now()).inDays;
      isExpiringSoon.value = daysUntilExpiry.value <= 7;
    } else if (planType == 'lifetime') {
      daysUntilExpiry.value = 999999;
      isExpiringSoon.value = false;
    }
    
    // Update timestamp tracking
    _lastUpdateTime = DateTime.now();
    
    update();
    
    print('💳 Payment confirmation complete - isPremium: ${isPremium.value}');
    print('💳 Plan: ${currentPlan.value}, Days: ${daysUntilExpiry.value}');
  }

  /// Purchase premium subscription with Razorpay ONLY
  Future<void> purchasePremiumWithRazorpay(String planType) async {
    print('💳 PremiumController.purchasePremiumWithRazorpay called with: $planType');
    
    if (isProcessing.value) {
      print('⚠️ Already processing payment, ignoring request');
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
      print('✅ Razorpay payment initiated successfully');
    } catch (e) {
      print('❌ Error in purchasePremiumWithRazorpay: $e');
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
        await refreshPremiumStatus();
      }
    } catch (e) {
      print('❌ Error restoring premium: $e');
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
      await refreshPremiumStatus();
    } catch (e) {
      print('❌ Error cancelling premium: $e');
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
    if (isPremium.value) return currentPlan.value.isEmpty ? 'yearly' : currentPlan.value;
    return 'yearly';
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
    if (isPremium.value) {
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
    print('💰 Payment request for plan: $planType');
    
    if (!canMakePayment()) return;

    if (planType == 'lifetime' && plans[planType]!['price'] > 20000) {
      final confirmed = await _showPaymentConfirmation(planType);
      if (!confirmed) {
        print('❌ Payment cancelled by user');
        return;
      }
    }

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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4AA)),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Enhanced debug method with comprehensive state checking
  void debugControllerStatus() {
    print('=== Premium Controller Debug ===');
    print('Is Premium (Reactive): ${isPremium.value}');
    print('Current Plan (Reactive): ${currentPlan.value}');
    print('Selected Plan: ${selectedPlan.value}');
    print('Is Processing: ${isProcessing.value}');
    print('Payment System Available: $isPaymentSystemAvailable');
    print('Days Until Expiry (Reactive): ${daysUntilExpiry.value}');
    print('Is Expiring Soon (Reactive): ${isExpiringSoon.value}');
    print('Last Update Time: $_lastUpdateTime');
    print('Service isPremium: ${_premiumService.isPremiumUser}');
    print('Auth User Premium: ${_authService.currentUser.value?.hasActivePremium}');
    print('Auth User Timestamp: ${_authService.currentUser.value?.lastUpdated}');
    print('==============================');
  }

  /// Method to handle post-payment success (called from Razorpay callback)
  void onPaymentSuccess(String planType, String paymentId) async {
    print('🎉 Payment success callback - Plan: $planType, Payment ID: $paymentId');
    
    // Immediately confirm payment success (bypasses all timestamp checks)
    confirmPaymentSuccess(planType);
    
    // Wait a moment for Firestore to update
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Try to refresh from server data as well
    await refreshPremiumStatus();
    
    isProcessing.value = false;
    
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
    print('❌ Payment failure callback - Error: $error');
    isProcessing.value = false;
    update();
  }

  /// Force refresh all premium-related data (useful for manual refresh)
  Future<void> forceRefresh() async {
    try {
      isProcessing.value = true;
      
      // Clear stale data tracking
      _lastUpdateTime = null;
      
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

  /// Get premium status stream for reactive widgets
  Stream<bool> get premiumStatusStream {
    return _authService.currentUser.stream
        .map((user) => user?.hasActivePremium ?? false)
        .distinct();
  }

  /// Check if user's premium has expired and needs renewal
  bool get needsRenewal {
    if (!isPremium.value) return false;
    return isExpiringSoon.value || daysUntilExpiry.value <= 7;
  }

  /// Get renewal urgency level
  String get renewalUrgency {
    if (!needsRenewal) return 'none';
    if (daysUntilExpiry.value <= 1) return 'critical';
    if (daysUntilExpiry.value <= 3) return 'urgent';
    if (daysUntilExpiry.value <= 7) return 'reminder';
    return 'none';
  }

  /// Force update method for external calls
  void forceUpdate() {
    initializeReactiveVariables();
    update();
  }

  /// Enhanced force immediate update (for post-payment)
  void forceUpdateNow() {
    print('⚡ FORCE UPDATE - bypassing debounce and stale checks');
    _debounceTimer?.cancel();
    _isUpdating = false;
    
    final user = _authService.currentUser.value;
    if (user != null) {
      print('⚡ Forcing with data - isPremium: ${user.hasActivePremium}');
      
      // CRITICAL: For post-payment, prioritize server data over local timestamp checks
      if (user.hasActivePremium) {
        isPremium.value = user.hasActivePremium;
        currentPlan.value = user.subscriptionPlan ?? '';
        daysUntilExpiry.value = user.daysUntilPremiumExpiry;
        isExpiringSoon.value = user.isPremiumExpiringSoon;
        
        // Update our tracking with current time if server shows premium
        _lastUpdateTime = DateTime.now();
        
        update();
        
        print('⚡ Force complete - isPremium: ${isPremium.value}');
      } else {
        print('⚡ Server data shows non-premium, checking timestamp...');
        
        // Only update if timestamp logic allows it
        if (_shouldAcceptUserData(user)) {
          isPremium.value = user.hasActivePremium;
          currentPlan.value = user.subscriptionPlan ?? '';
          daysUntilExpiry.value = user.daysUntilPremiumExpiry;
          isExpiringSoon.value = user.isPremiumExpiringSoon;
          
          _lastUpdateTime = user.lastUpdated;
          
          update();
          
          print('⚡ Force complete - isPremium: ${isPremium.value}');
        } else {
          print('⚡ Timestamp check failed, keeping current state');
        }
      }
    }
  }

  /// Reset controller state (useful for testing or manual resets)
  void resetControllerState() {
    print('🔄 Resetting controller state...');
    
    _debounceTimer?.cancel();
    _isUpdating = false;
    _lastUpdateTime = null;
    
    isPremium.value = false;
    currentPlan.value = '';
    daysUntilExpiry.value = 0;
    isExpiringSoon.value = false;
    isProcessing.value = false;
    
    print('✅ Controller state reset completed');
    
    // Reinitialize with fresh data
    initializeReactiveVariables();
  }

  @override
  void onInit() {
    super.onInit();
    print('🚀 PremiumController onInit called');
    
    // Initialize reactive variables
    initializeReactiveVariables();
    
    // Set up smart listeners with data filtering
    _listenToPremiumChanges();
    
    // Debug payment system status on init
    if (Get.testMode || Get.isLogEnable) {
      debugControllerStatus();
    }
  }

  @override
  void onClose() {
    print('🔚 PremiumController onClose called');
    _debounceTimer?.cancel();
    super.onClose();
  }
}
