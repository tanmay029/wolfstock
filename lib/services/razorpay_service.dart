// ignore_for_file: avoid_print

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:wolfstock/config/local_config.dart';
import 'package:wolfstock/controllers/bottom_nav_controller.dart';
import 'package:wolfstock/controllers/premium_controller.dart';
import 'package:wolfstock/controllers/stock_controller.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'premium_service.dart';

class RazorpayService extends GetxService {
  late Razorpay _razorpay;
  final AuthService _authService = Get.find<AuthService>();
  
  String? _currentPlanType;
  String? _currentPlanName;

  static const String _keyId = LocalConfig.razorpayTestKeyId; 
  // static const String _keySecret = 'your_secret_key_here'; 

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

    _currentPlanType = planType;
    _currentPlanName = planName;
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
      'theme': {'color': '#00D4AA'},
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
    print('🎉 Payment Success Handler Called');
    print('Payment ID: ${response.paymentId}');
    print('Order ID: ${response.orderId}');
    print('Signature: ${response.signature}');
    try {
      Get.dialog(
        const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA))),
              SizedBox(height: 16),
              Text('Activating your premium subscription...'),
              SizedBox(height: 8),
              Text('Please wait while we process your payment', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        barrierDismissible: false,
      );
      final planType = _currentPlanType ?? 'yearly';
      final planAmount = PremiumService.subscriptionPlans[planType]?['price']?.toDouble();
      print('📦 Activating premium for plan: $planType, amount: ₹$planAmount');
      final premiumService = Get.find<PremiumService>();
      final success = await premiumService.activatePremiumAfterPayment(
        planType, 
        response.paymentId ?? '',
        amount: planAmount,
      );
      if (Get.isDialogOpen ?? false) Get.back();
      if (success) {
        print('✅ Premium activation successful, starting UI refresh...');
        await _refreshUserDataAndUI();
        Get.snackbar(
          'Payment Successful! 🎉',
          'Your premium subscription is now active!',
          backgroundColor: const Color(0xFF00D4AA),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
        );
        await Future.delayed(const Duration(milliseconds: 1000));
        print('🏠 Navigating to home screen...');
        Get.offAllNamed('/home');
        _trackPaymentSuccess(response, planType);
      } else {
        throw Exception('Premium activation failed');
      }
    } catch (e) {
      print('❌ Error in payment success handler: $e');
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        'Payment Successful',
        'Payment completed! Activating premium features...',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      await _refreshUserDataAndUI();
      await Future.delayed(const Duration(milliseconds: 1500));
      Get.offAllNamed('/home');
    } finally {
      _currentPlanType = null;
      _currentPlanName = null;
    }
  }

  Future<void> _refreshUserDataAndUI() async {
    try {
      print('🔄 Starting user data and UI refresh after payment...');
      int retryCount = 0;
      bool refreshSuccess = false;
      while (retryCount < 3 && !refreshSuccess) {
        try {
          await _authService.refreshCurrentUser();
          refreshSuccess = true;
          print('✅ AuthService user data refreshed successfully');
        } catch (e) {
          retryCount++;
          print('⚠️ Retry $retryCount: Error refreshing user  $e');
          if (retryCount < 3) await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }
      await Future.delayed(const Duration(milliseconds: 200));
      if (Get.isRegistered<PremiumController>()) {
        try {
          final premiumController = Get.find<PremiumController>();
          await premiumController.refreshPremiumStatus();
          premiumController.update();
          print('✅ PremiumController refreshed and updated');
        } catch (e) {
          print('❌ Error updating PremiumController: $e');
        }
      }
      _updateAllDependentControllers();
      await Future.delayed(const Duration(milliseconds: 300));
      Get.forceAppUpdate();
      print('🎉 User data and UI refresh completed successfully');
    } catch (e) {
      print('❌ Error refreshing user data and UI: $e');
    }
  }

  void _updateAllDependentControllers() {
    try {
      final controllersToUpdate = [
        () {
          if (Get.isRegistered<BottomNavController>()) {
            Get.find<BottomNavController>().update();
            print('BottomNavController updated');
          }
        },
        () {
          if (Get.isRegistered<StockController>()) {
            Get.find<StockController>().update();
            print('StockController updated');
          }
        },
        () {
          if (Get.isRegistered<PremiumController>()) {
            Get.find<PremiumController>().update();
            print('PremiumController updated');
          }
        },
      ];
      for (final updateController in controllersToUpdate) {
        try {
          updateController();
        } catch (e) {
          print('Skipping controller update: $e');
          continue;
        }
      }
      print('All dependent controllers update completed');
    } catch (e) {
      print('Error updating dependent controllers: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ Payment Error Handler Called');
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
      snackPosition: SnackPosition.TOP,
    );
    if (Get.isRegistered<PremiumController>()) {
      Get.find<PremiumController>().onPaymentFailure(errorMessage);
    }
    _trackPaymentError(response);
    _currentPlanType = null;
    _currentPlanName = null;
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
    print('=== Payment Success Analytics ===');
    print('Payment ID: ${response.paymentId}');
    print('Plan Type: $planType');
    print('Order ID: ${response.orderId}');
    print('Signature: ${response.signature}');
    print('User: ${_authService.currentUser.value?.email}');
    print('Timestamp: ${DateTime.now().toIso8601String()}');
    print('================================');
    // Integrate Firebase Analytics or similar here if required
  }

  void _trackPaymentError(PaymentFailureResponse response) {
    print('=== Payment Error Analytics ===');
    print('Error Code: ${response.code}');
    print('Error Message: ${response.message}');
    print('User: ${_authService.currentUser.value?.email}');
    print('Timestamp: ${DateTime.now().toIso8601String()}');
    print('===============================');
    // Integrate Firebase Analytics or similar here if required
  }

  bool get isInitialized => _razorpay != null;
  String get version => 'Razorpay Flutter SDK';

  Future<void> triggerManualRefresh() async {
    await _refreshUserDataAndUI();
  }

  void debugPremiumStatusUpdate() async {
    print('🔍 === DEBUGGING PREMIUM STATUS UPDATE ===');
    final user = _authService.currentUser.value;
    print('AuthService User Email: ${user?.email}');
    print('AuthService User Premium: ${user?.hasActivePremium}');
    print('AuthService User Plan: ${user?.subscriptionPlan}');
    if (Get.isRegistered<PremiumService>()) {
      final premiumService = Get.find<PremiumService>();
      print('PremiumService isPremium: ${premiumService.isPremiumUser}');
      print('PremiumService currentPlan: ${premiumService.currentPlan}');
    }
    if (Get.isRegistered<PremiumController>()) {
      final premiumController = Get.find<PremiumController>();
      print('PremiumController isPremium: ${premiumController.isPremium}');
      print('PremiumController currentPlan: ${premiumController.currentPlan}');
    }
    print('🔍 === DEBUG COMPLETE ===');
  }

  Future<void> testManualRefresh() async {
    print('🧪 Testing manual refresh...');
    await _refreshUserDataAndUI();
    debugPremiumStatusUpdate();
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
