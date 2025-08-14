// lib/services/razorpay_service.dart
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:wolfstock/config/local_config.dart';
import 'package:wolfstock/controllers/premium_controller.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'premium_service.dart';

class RazorpayService extends GetxService {
  late Razorpay _razorpay;
  final AuthService _authService = Get.find<AuthService>();
  
  // Store current payment context
  String? _currentPlanType;
  String? _currentPlanName;

  // Razorpay API Keys (Use test keys for development)
  static const String _keyId = LocalConfig.razorpayTestKeyId; 
  static const String _keySecret = 'your_secret_key_here'; 

  @override
  void onInit() {
    super.onInit();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Process premium subscription payment
  Future<void> processPremiumPayment({
    required String planType,
    required double amount,
    required String planName,
  }) async {
    print('Processing payment: $planType, Amount: ₹$amount');
    
    final user = _authService.currentUser.value;
    if (user == null) {
      Get.snackbar('Error', 'Please login to continue');
      return;
    }

    // Store current payment context for success callback
    _currentPlanType = planType;
    _currentPlanName = planName;

    // Convert amount to paise (smallest currency unit for INR)
    final amountInPaise = (amount * 100).toInt();

    var options = {
      'key': _keyId,
      'amount': amountInPaise,
      'name': 'WolfStock',
      'description': 'Premium Subscription - $planName',
      'prefill': {
        'contact': user.phoneNumber ?? '9123456789',
        'email': user.email,
        'name': user.displayName ?? 'User',
      },
      'theme': {
        'color': '#00D4AA', // WolfStock primary color
      },
      'currency': 'INR',
      'payment_capture': 1,
      'notes': {
        'user_id': user.uid,
        'plan_type': planType,
        'plan_name': planName,
      },
    };

    try {
      print('Opening Razorpay with options: $options');
      _razorpay.open(options);
    } catch (e) {
      print('Razorpay open error: $e');
      Get.snackbar(
        'Payment Error',
        'Failed to open payment gateway: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print('Payment Success Handler Called');
    print('Payment ID: ${response.paymentId}');
    print('Order ID: ${response.orderId}');
    print('Signature: ${response.signature}');
    
    try {
      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Use stored plan type or extract from response
      final planType = _currentPlanType ?? 'yearly';
      print('Activating premium for plan: $planType');
      
      // Get PremiumService and activate premium
      final premiumService = Get.find<PremiumService>();
      final success = await premiumService.activatePremiumAfterPayment(
        planType, 
        response.paymentId ?? '',
      );
      
      Get.back(); // Close loading dialog

      if (success) {
        // CRITICAL: Force refresh user data and UI updates
        await _refreshUserDataAndUI();
        
        // Show success dialog
        Get.dialog(
          AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 30),
                const SizedBox(width: 10),
                const Text('Payment Successful!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment ID: ${response.paymentId}'),
                if (response.orderId != null)
                  Text('Order ID: ${response.orderId}'),
                const SizedBox(height: 10),
                const Text(
                  'Your premium subscription has been activated successfully!',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Get.back(); // Close success dialog
                  // Navigate to premium screen to show updated status
                  Get.offAllNamed('/premium');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4AA),
                  foregroundColor: Colors.white,
                ),
                child: const Text('View Premium Dashboard'),
              ),
            ],
          ),
        );

        // Track the successful payment
        _trackPaymentSuccess(response, planType);
        
        // Clear stored context
        _currentPlanType = null;
        _currentPlanName = null;
        
      } else {
        throw Exception('Failed to activate premium subscription');
      }

    } catch (e) {
      print('Error in payment success handler: $e');
      Get.back(); // Close loading dialog if still open
      Get.snackbar(
        'Error',
        'Payment successful but failed to activate premium: $e',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      
      // Even on error, try to refresh data in case it was actually successful
      await _refreshUserDataAndUI();
    }
  }

  /// CRITICAL: Refresh user data and trigger UI updates
  Future<void> _refreshUserDataAndUI() async {
    try {
      print('Refreshing user data and UI after payment...');
      
      // 1. Refresh AuthService user data
      await _authService.refreshCurrentUser();
      
      // 2. Force update PremiumController if registered
      if (Get.isRegistered<PremiumController>()) {
        final premiumController = Get.find<PremiumController>();
        await premiumController.refreshPremiumStatus();
        print('PremiumController updated');
      }
      
      // 3. Force update any other controllers that depend on premium status
      _updateAllDependentControllers();
      
      print('User data and UI refreshed successfully');
      
    } catch (e) {
      print('Error refreshing user data and UI: $e');
    }
  }

  /// Update all controllers that depend on premium status
  void _updateAllDependentControllers() {
    try {
      // Update any controllers that might be affected by premium status change
      final registeredControllers = [
        'BottomNavController',
        'StockController',
        'AIController', // If you have one
        'ProfileController', // If you have one
      ];
      
      for (final controllerName in registeredControllers) {
        try {
          // This is a generic way to update GetX controllers
          Get.find<GetxController>(tag: controllerName).update();
        } catch (e) {
          // Controller not registered, skip
          continue;
        }
      }
      
    } catch (e) {
      print('Error updating dependent controllers: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Payment Error Handler Called');
    print('Error Code: ${response.code}');
    print('Error Message: ${response.message}');
    
    String errorMessage = 'Payment failed';
    
    switch (response.code) {
      case Razorpay.NETWORK_ERROR:
        errorMessage = 'Network error. Please check your internet connection.';
        break;
      case Razorpay.INVALID_OPTIONS:
        errorMessage = 'Invalid payment options. Please try again.';
        break;
      case Razorpay.PAYMENT_CANCELLED:
        errorMessage = 'Payment was cancelled by user.';
        break;
      case Razorpay.TLS_ERROR:
        errorMessage = 'TLS error. Please update your device.';
        break;
      default:
        errorMessage = response.message ?? 'Unknown error occurred';
    }

    Get.snackbar(
      'Payment Failed',
      errorMessage,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );

    // Reset processing state in PremiumController
    if (Get.isRegistered<PremiumController>()) {
      Get.find<PremiumController>().onPaymentFailure(errorMessage);
    }

    // Clear stored context
    _currentPlanType = null;
    _currentPlanName = null;

    // Track the failed payment
    _trackPaymentError(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('External Wallet Handler Called');
    print('Wallet Name: ${response.walletName}');
    
    Get.snackbar(
      'External Wallet',
      'You selected: ${response.walletName}',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void _trackPaymentSuccess(PaymentSuccessResponse response, String planType) {
    // Implement analytics tracking
    print('=== Payment Success Analytics ===');
    print('Payment ID: ${response.paymentId}');
    print('Plan Type: $planType');
    print('Order ID: ${response.orderId}');
    print('Signature: ${response.signature}');
    print('User: ${_authService.currentUser.value?.email}');
    print('Timestamp: ${DateTime.now().toIso8601String()}');
    print('================================');
    
    // TODO: Send to your analytics service (Firebase Analytics, etc.)
  }

  void _trackPaymentError(PaymentFailureResponse response) {
    // Implement analytics tracking
    print('=== Payment Error Analytics ===');
    print('Error Code: ${response.code}');
    print('Error Message: ${response.message}');
    print('User: ${_authService.currentUser.value?.email}');
    print('Timestamp: ${DateTime.now().toIso8601String()}');
    print('===============================');
    
    // TODO: Send to your analytics service
  }

  /// Check if Razorpay is properly initialized
  bool get isInitialized => _razorpay != null;

  /// Get current Razorpay version info
  String get version => 'Razorpay Flutter SDK';

  /// Manual refresh trigger (for testing purposes)
  Future<void> triggerManualRefresh() async {
    await _refreshUserDataAndUI();
  }

  @override
  void onClose() {
    print('Closing RazorpayService');
    try {
      _razorpay.clear();
    } catch (e) {
      print('Error clearing Razorpay: $e');
    }
    super.onClose();
  }
}

