// ignore_for_file: avoid_print

import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hive/hive.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:wolfstock/config/local_config.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'premium_service.dart';

class RazorpayService extends GetxService {
  late Razorpay _razorpay;
  final AuthService _authService = Get.find<AuthService>();
  
  String? _currentPlanType;
  String? _currentPlanName;

  static const String _keyId = LocalConfig.razorpayTestKeyId; 

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
    print('💳 Processing payment: $planType, Amount: ₹$amount');
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
      print('🚀 Opening Razorpay with options');
      _razorpay.open(options);
    } catch (e) {
      print('❌ Razorpay open error: $e');
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
    
    try {
      // Show processing dialog
      Get.dialog(
        const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
              ),
              SizedBox(height: 16),
              Text('Processing your payment...'),
              SizedBox(height: 8),
              Text(
                'Please wait while we activate your premium features',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Activate premium in Firestore
      final planType = _currentPlanType ?? 'monthly';
      final planAmount = PremiumService.subscriptionPlans[planType]?['price']?.toDouble();
      print('📦 Activating premium for plan: $planType, amount: ₹$planAmount');
      
      final premiumService = Get.find<PremiumService>();
      final success = await premiumService.activatePremiumAfterPayment(
        planType, 
        response.paymentId ?? '',
        amount: planAmount,
      );
      
      // Close processing dialog
      try {
        if (Get.isDialogOpen ?? false) {
          Get.back();
          print('✅ Processing dialog closed');
        }
      } catch (e) {
        print('Error closing dialog: $e');
      }

      if (success) {
        print('✅ Premium activation successful');
        
        // Clear local cache to ensure fresh start
        await _clearLocalStorageCache();
        
        // Show countdown dialog and restart app
        await _showCountdownAndRestart(planType);
        
      } else {
        throw Exception('Premium activation failed');
      }

    } catch (e) {
      print('❌ Error in payment success handler: $e');
      
      // Safe cleanup
      try {
        if (Get.isDialogOpen ?? false) Get.back();
      } catch (cleanupError) {
        print('Error in cleanup: $cleanupError');
      }
      
      // Show error but still restart (payment succeeded)
      Get.snackbar(
        'Payment Successful',
        'Payment completed! Restarting app to activate premium features...',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
      
      // Wait briefly then restart anyway
      await Future.delayed(const Duration(seconds: 3));
      await _clearLocalStorageCache();
      Phoenix.rebirth(Get.key.currentContext!);
      
    } finally {
      // Track analytics
      _trackPaymentSuccess(response, _currentPlanType ?? 'monthly');
      
      // Clear stored context
      _currentPlanType = null;
      _currentPlanName = null;
    }
  }

  /// Show 5-second countdown and restart app
  Future<void> _showCountdownAndRestart(String planType) async {
    print('⏰ Starting countdown before app restart');
    
    // Reactive countdown value
    RxInt countdown = 5.obs;
    
    // Show countdown dialog
    Get.dialog(
      Obx(() => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF00D4AA),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful! 🎉',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00D4AA),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Updating app with premium features...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00D4AA), width: 3),
              ),
              child: Center(
                child: Text(
                  '${countdown.value}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00D4AA),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'App will restart in ${countdown.value} seconds',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      )),
      barrierDismissible: false,
    );
    
    // Start countdown timer
    for (int i = 5; i > 0; i--) {
      countdown.value = i;
      print('⏰ Countdown: ${i}s');
      await Future.delayed(const Duration(seconds: 1));
    }
    
    // Close countdown dialog
    try {
      if (Get.isDialogOpen ?? false) {
        Get.back();
        print('✅ Countdown dialog closed');
      }
    } catch (e) {
      print('Error closing countdown dialog: $e');
    }
    
    // Show final message
    Get.snackbar(
      'Premium Activated! 🚀',
      'Restarting app now...',
      backgroundColor: const Color(0xFF00D4AA),
      colorText: Colors.white,
      duration: const Duration(milliseconds: 500),
      snackPosition: SnackPosition.TOP,
    );
    
    // Brief pause for snackbar
    await Future.delayed(const Duration(milliseconds: 600));
    
    // 🚀 RESTART THE APP
    print('🔄 Restarting app with Phoenix...');
    Phoenix.rebirth(Get.key.currentContext!);
  }

  /// Clear local storage cache
  Future<void> _clearLocalStorageCache() async {
    try {
      final box = await Hive.openBox('userBox');
      await box.clear();
      print('📱 Local storage cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
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

    _trackPaymentError(response);
    
    // Clear stored context
    _currentPlanType = null;
    _currentPlanName = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('💳 External Wallet Handler Called');
    print('Wallet Name: ${response.walletName}');
    
    Get.snackbar(
      'External Wallet',
      'You selected: ${response.walletName}',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _trackPaymentSuccess(PaymentSuccessResponse response, String planType) {
    print('=== Payment Success Analytics ===');
    print('Payment ID: ${response.paymentId}');
    print('Plan Type: $planType');
    print('Order ID: ${response.orderId}');
    print('Signature: ${response.signature}');
    print('User: ${_authService.currentUser.value?.email}');
    print('User ID: ${_authService.currentUser.value?.uid}');
    print('Amount: ${PremiumService.subscriptionPlans[planType]?['price']}');
    print('Currency: INR');
    print('Timestamp: ${DateTime.now().toIso8601String()}');
    print('================================');
    
    // TODO: Integrate with your analytics service
    // FirebaseAnalytics.instance.logPurchase(...)
  }

  void _trackPaymentError(PaymentFailureResponse response) {
    print('=== Payment Error Analytics ===');
    print('Error Code: ${response.code}');
    print('Error Message: ${response.message}');
    print('User: ${_authService.currentUser.value?.email}');
    print('User ID: ${_authService.currentUser.value?.uid}');
    print('Plan Type: $_currentPlanType');
    print('Timestamp: ${DateTime.now().toIso8601String()}');
    print('===============================');
    
    // TODO: Integrate with your analytics service
  }

  /// Check if Razorpay is properly initialized
  bool get isInitialized => _razorpay != null;

  /// Get current Razorpay version info
  String get version => 'Razorpay Flutter SDK';

  /// Manual restart trigger (for testing)
  Future<void> triggerManualRestart() async {
    print('🧪 Manual restart triggered');
    await _clearLocalStorageCache();
    Phoenix.rebirth(Get.key.currentContext!);
  }

  @override
  void onClose() {
    print('🔄 Closing RazorpayService...');
    try {
      _razorpay.clear();
      print('✅ Razorpay cleared successfully');
    } catch (e) {
      print('❌ Error clearing Razorpay: $e');
    }
    super.onClose();
  }
}




// // ignore_for_file: avoid_print

// import 'package:hive/hive.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:get/get.dart';
// import 'package:flutter/material.dart';
// import 'package:wolfstock/config/local_config.dart';
// import 'package:wolfstock/controllers/bottom_nav_controller.dart';
// import 'package:wolfstock/controllers/premium_controller.dart';
// import 'package:wolfstock/controllers/stock_controller.dart';
// import '../models/user_model.dart';
// import 'auth_service.dart';
// import 'premium_service.dart';

// class RazorpayService extends GetxService {
//   late Razorpay _razorpay;
//   final AuthService _authService = Get.find<AuthService>();
  
//   String? _currentPlanType;
//   String? _currentPlanName;

//   static const String _keyId = LocalConfig.razorpayTestKeyId; 
//   // static const String _keySecret = 'your_secret_key_here'; 

//   @override
//   void onInit() {
//     super.onInit();
//     _initializeRazorpay();
//   }

//   void _initializeRazorpay() {
//     _razorpay = Razorpay();
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
//   }

//   Future<void> processPremiumPayment({
//     required String planType,
//     required double amount,
//     required String planName,
//   }) async {
//     print('Processing payment: $planType, Amount: ₹$amount');
//     final user = _authService.currentUser.value;
//     if (user == null) {
//       Get.snackbar('Error', 'Please login to continue');
//       return;
//     }

//     _currentPlanType = planType;
//     _currentPlanName = planName;
//     final amountInPaise = (amount * 100).toInt();

//     var options = {
//       'key': _keyId,
//       'amount': amountInPaise,
//       'name': 'WolfStock',
//       'description': 'Premium Subscription - $planName',
//       'prefill': {
//         'contact': user.phoneNumber ?? '9123456789',
//         'email': user.email,
//         'name': user.displayName ?? 'User',
//       },
//       'theme': {'color': '#00D4AA'},
//       'currency': 'INR',
//       'payment_capture': 1,
//       'notes': {
//         'user_id': user.uid,
//         'plan_type': planType,
//         'plan_name': planName,
//       },
//     };

//     try {
//       print('Opening Razorpay with options: $options');
//       _razorpay.open(options);
//     } catch (e) {
//       print('Razorpay open error: $e');
//       Get.snackbar(
//         'Payment Error',
//         'Failed to open payment gateway: $e',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//     }
//   }

//   void _handlePaymentSuccess(PaymentSuccessResponse response) async {
//     print('🎉 Payment Success Handler Called');
//     print('Payment ID: ${response.paymentId}');
//     print('Order ID: ${response.orderId}');
//     print('Signature: ${response.signature}');
    
//     try {
//       // Show loading dialog
//       Get.dialog(
//         const AlertDialog(
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA))),
//               SizedBox(height: 16),
//               Text('Activating your premium subscription...'),
//               SizedBox(height: 8),
//               Text('Please wait while we process your payment', style: TextStyle(fontSize: 12, color: Colors.grey)),
//             ],
//           ),
//         ),
//         barrierDismissible: false,
//       );

//       // Use stored plan type or extract from response
//       final planType = _currentPlanType ?? 'yearly';
//       final planAmount = PremiumService.subscriptionPlans[planType]?['price']?.toDouble();
//       print('📦 Activating premium for plan: $planType, amount: ₹$planAmount');
      
//       // Get PremiumService and activate premium
//       final premiumService = Get.find<PremiumService>();
//       final success = await premiumService.activatePremiumAfterPayment(
//         planType, 
//         response.paymentId ?? '',
//         amount: planAmount,
//       );
      
//       // SAFE DIALOG CLOSING
//       try {
//         if (Get.isDialogOpen ?? false) {
//           Get.back();
//           print('Dialog closed safely');
//         }
//       } catch (e) {
//         print('Error closing dialog: $e');
//       }

//       if (success) {
//         print('✅ Premium activation successful, starting UI refresh...');

//         // Clear cached data first to prevent stale reads
//         await _clearLocalStorageCache();

//         // CRITICAL: Wait longer for Firestore to propagate changes (5 seconds)
//         print('⏳ Waiting for Firestore data propagation...');
//         await Future.delayed(const Duration(seconds: 5));
        
//         // CRITICAL: Force comprehensive refresh with multiple retries
//         await _refreshUserDataAndUI();
        
//         // Show success message
//         Get.snackbar(
//           'Payment Successful! 🎉',
//           'Your premium subscription is now active!',
//           backgroundColor: const Color(0xFF00D4AA),
//           colorText: Colors.white,
//           duration: const Duration(seconds: 3),
//           snackPosition: SnackPosition.TOP,
//         );

//         // Wait for snackbar display and final data settling
//         await Future.delayed(const Duration(milliseconds: 3500));

//         // Navigate directly to home
//         print('🏠 Navigating directly to home...');
//         await _navigateToHome();

//         // Track the successful payment
//         _trackPaymentSuccess(response, planType);
        
//       } else {
//         throw Exception('Premium activation failed');
//       }

//     } catch (e) {
//       print('❌ Error in payment success handler: $e');
      
//       // Safe cleanup - ensure dialog is closed
//       try {
//         if (Get.isDialogOpen ?? false) Get.back();
//       } catch (cleanupError) {
//         print('Error in cleanup: $cleanupError');
//       }
      
//       // Still show positive message since payment succeeded
//       Get.snackbar(
//         'Payment Successful',
//         'Payment completed! Updating your premium status...',
//         backgroundColor: Colors.orange,
//         colorText: Colors.white,
//         duration: const Duration(seconds: 4),
//         snackPosition: SnackPosition.TOP,
//       );
      
//       // Even on error, try to refresh data
//       await _clearLocalStorageCache();
//       await Future.delayed(const Duration(seconds: 3));
//       await _refreshUserDataAndUI();
      
//       // Navigate to home after delay
//       await Future.delayed(const Duration(milliseconds: 2000));
//       await _navigateToHome();
      
//     } finally {
//       // Always clear stored context
//       _currentPlanType = null;
//       _currentPlanName = null;
//     }
//   }

//   /// Clear local storage cache to force fresh data fetch
//   Future<void> _clearLocalStorageCache() async {
//     try {
//       final box = await Hive.openBox('userBox');
//       await box.clear();
//       print('📱 Local storage cache cleared completely');
//     } catch (e) {
//       print('❌ Error clearing local storage cache: $e');
//     }
//   }

//   /// CRITICAL: Enhanced comprehensive data refresh with smart retries
//   Future<void> _refreshUserDataAndUI() async {
//     try {
//       print('🔄 Starting comprehensive data refresh...');
      
//       // 1. Multiple retry attempts for user data refresh with exponential backoff
//       int retryCount = 0;
//       bool refreshSuccess = false;
      
//       while (retryCount < 6 && !refreshSuccess) {
//         try {
//           print('🔄 Attempt ${retryCount + 1}: Refreshing user data from Firestore...');
//           await _authService.refreshCurrentUser();
          
//           // Verify the refresh worked by checking premium status
//           final user = _authService.currentUser.value;
//           if (user?.hasActivePremium == true) {
//             refreshSuccess = true;
//             print('✅ AuthService user data refreshed successfully - Premium: ${user!.hasActivePremium}');
//             break;
//           } else {
//             print('⚠️ Refresh completed but premium status still false, retrying...');
//             throw Exception('Premium status not updated yet');
//           }
//         } catch (e) {
//           retryCount++;
//           print('⚠️ Retry $retryCount: Error refreshing user  $e');
//           if (retryCount < 6) {
//             // Exponential backoff: 1s, 2s, 4s, 8s, 16s
//             final delay = Duration(seconds: 1 << (retryCount - 1));
//             print('⏳ Waiting ${delay.inSeconds}s before retry...');
//             await Future.delayed(delay);
//           }
//         }
//       }
      
//       if (!refreshSuccess) {
//         print('⚠️ Failed to refresh user data after all retries');
//       }
      
//       // 2. Wait for data propagation across all systems
//       await Future.delayed(const Duration(milliseconds: 1500));
      
//       // 3. Force update PremiumController with fresh data
//       if (Get.isRegistered<PremiumController>()) {
//         try {
//           final premiumController = Get.find<PremiumController>();
//           print('🔄 Refreshing PremiumController...');
          
//           await premiumController.refreshPremiumStatus();
//           premiumController.forceUpdateNow();
          
//           // Verify controller was updated
//           print('✅ PremiumController updated - isPremium: ${premiumController.isPremium.value}');
//         } catch (e) {
//           print('❌ Error updating PremiumController: $e');
//         }
//       }
      
//       // 4. Update all other dependent controllers
//       _updateAllDependentControllers();
      
//       // 5. Force complete app refresh to ensure UI consistency
//       Get.forceAppUpdate();
      
//       // 6. Final wait for all updates to settle
//       await Future.delayed(const Duration(milliseconds: 500));
      
//       print('🎉 Comprehensive data refresh completed successfully');
      
//       // 7. Debug verification
//       _debugFinalState();
      
//     } catch (e) {
//       print('❌ Error in comprehensive data refresh: $e');
//     }
//   }

//   /// Debug method to verify final state after refresh
//   void _debugFinalState() {
//     final user = _authService.currentUser.value;
//     print('🔍 Final State Verification:');
//     print('  AuthService isPremium: ${user?.hasActivePremium}');
//     print('  AuthService plan: ${user?.subscriptionPlan}');
//     print('  Data timestamp: ${user?.lastUpdated}');
    
//     if (Get.isRegistered<PremiumController>()) {
//       try {
//         final controller = Get.find<PremiumController>();
//         print('  Controller isPremium: ${controller.isPremium.value}');
//         print('  Controller plan: ${controller.currentPlan.value}');
//       } catch (e) {
//         print('  Controller check failed: $e');
//       }
//     }
//   }

//   void _updateAllDependentControllers() {
//     try {
//       final controllersToUpdate = [
//         () {
//           if (Get.isRegistered<BottomNavController>()) {
//             Get.find<BottomNavController>().update();
//             print('✅ BottomNavController updated');
//           }
//         },
//         () {
//           if (Get.isRegistered<StockController>()) {
//             Get.find<StockController>().update();
//             print('✅ StockController updated');
//           }
//         },
//         () {
//           if (Get.isRegistered<PremiumController>()) {
//             Get.find<PremiumController>().update();
//             print('✅ PremiumController updated');
//           }
//         },
//       ];
      
//       for (final updateController in controllersToUpdate) {
//         try {
//           updateController();
//         } catch (e) {
//           print('⚠️ Skipping controller update: $e');
//           continue;
//         }
//       }
      
//       print('🎯 All dependent controllers update completed');
//     } catch (e) {
//       print('❌ Error updating dependent controllers: $e');
//     }
//   }

//   void _handlePaymentError(PaymentFailureResponse response) {
//     print('❌ Payment Error Handler Called');
//     print('Error Code: ${response.code}');
//     print('Error Message: ${response.message}');
    
//     String errorMessage = 'Payment failed';
    
//     switch (response.code) {
//       case Razorpay.NETWORK_ERROR:
//         errorMessage = 'Network error. Please check your internet connection.';
//         break;
//       case Razorpay.INVALID_OPTIONS:
//         errorMessage = 'Invalid payment options. Please try again.';
//         break;
//       case Razorpay.PAYMENT_CANCELLED:
//         errorMessage = 'Payment was cancelled by user.';
//         break;
//       case Razorpay.TLS_ERROR:
//         errorMessage = 'TLS error. Please update your device.';
//         break;
//       default:
//         errorMessage = response.message ?? 'Unknown error occurred';
//     }

//     Get.snackbar(
//       'Payment Failed',
//       errorMessage,
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 4),
//       snackPosition: SnackPosition.TOP,
//     );

//     if (Get.isRegistered<PremiumController>()) {
//       try {
//         Get.find<PremiumController>().onPaymentFailure(errorMessage);
//       } catch (e) {
//         print('Error notifying controller of payment failure: $e');
//       }
//     }

//     _trackPaymentError(response);
    
//     // Clear stored context
//     _currentPlanType = null;
//     _currentPlanName = null;
//   }

//   void _handleExternalWallet(ExternalWalletResponse response) {
//     print('💳 External Wallet Handler Called');
//     print('Wallet Name: ${response.walletName}');
    
//     Get.snackbar(
//       'External Wallet',
//       'You selected: ${response.walletName}',
//       backgroundColor: Colors.blue,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 3),
//     );
//   }

//   void _trackPaymentSuccess(PaymentSuccessResponse response, String planType) {
//     print('=== Payment Success Analytics ===');
//     print('Payment ID: ${response.paymentId}');
//     print('Plan Type: $planType');
//     print('Order ID: ${response.orderId}');
//     print('Signature: ${response.signature}');
//     print('User: ${_authService.currentUser.value?.email}');
//     print('User ID: ${_authService.currentUser.value?.uid}');
//     print('Amount: ${PremiumService.subscriptionPlans[planType]?['price']}');
//     print('Currency: INR');
//     print('Timestamp: ${DateTime.now().toIso8601String()}');
//     print('Final Premium Status: ${_authService.currentUser.value?.hasActivePremium}');
//     print('================================');
    
//     // TODO: Integrate with your analytics service
//     // FirebaseAnalytics.instance.logPurchase(...)
//   }

//   void _trackPaymentError(PaymentFailureResponse response) {
//     print('=== Payment Error Analytics ===');
//     print('Error Code: ${response.code}');
//     print('Error Message: ${response.message}');
//     print('User: ${_authService.currentUser.value?.email}');
//     print('User ID: ${_authService.currentUser.value?.uid}');
//     print('Plan Type: $_currentPlanType');
//     print('Timestamp: ${DateTime.now().toIso8601String()}');
//     print('===============================');
    
//     // TODO: Integrate with your analytics service
//   }

//   /// Safe snackbar closing to prevent controller errors
//   void _safeCloseSnackbar() {
//     try {
//       if (Get.isSnackbarOpen ?? false) {
//         Get.back();
//         print('✅ Snackbar closed safely');
//       }
//     } catch (e) {
//       print('❌ Error closing snackbar: $e');
//     }
//   }

//   /// Enhanced safe navigation method with verification
//   Future<void> _navigateToHome() async {
//     try {
//       // Verify we have updated user data before navigation
//       final user = _authService.currentUser.value;
//       print('🧭 Navigating to home - User premium status: ${user?.hasActivePremium}');
      
//       // Ensure we're not already on home screen
//       if (Get.currentRoute != '/home') {
//         Get.offAllNamed('/home');
//         print('✅ Successfully navigated to home screen');
//       } else {
//         print('🏠 Already on home screen, forcing app refresh');
//         Get.forceAppUpdate();
//       }
//     } catch (e) {
//       print('❌ Error navigating to home: $e');
//       // Fallback navigation
//       try {
//         Get.offAllNamed('/');
//       } catch (fallbackError) {
//         print('❌ Fallback navigation also failed: $fallbackError');
//       }
//     }
//   }

//   /// Check if Razorpay is properly initialized
//   bool get isInitialized => _razorpay != null;

//   /// Get current Razorpay version info
//   String get version => 'Razorpay Flutter SDK';

//   /// Manual refresh trigger (for testing purposes)
//   Future<void> triggerManualRefresh() async {
//     print('🧪 Manual refresh triggered');
//     await _refreshUserDataAndUI();
//   }

//   /// Enhanced debug method with comprehensive state checking
//   void debugPremiumStatusUpdate() async {
//     print('🔍 === COMPREHENSIVE PREMIUM STATUS DEBUG ===');
    
//     final user = _authService.currentUser.value;
//     print('📱 AuthService State:');
//     print('  User Email: ${user?.email}');
//     print('  User Premium: ${user?.hasActivePremium}');
//     print('  User Plan: ${user?.subscriptionPlan}');
//     print('  Last Updated: ${user?.lastUpdated}');
//     print('  Payment ID: ${user?.lastPaymentId}');
    
//     if (Get.isRegistered<PremiumService>()) {
//       try {
//         final premiumService = Get.find<PremiumService>();
//         print('🏪 PremiumService State:');
//         print('  isPremium: ${premiumService.isPremiumUser}');
//         print('  currentPlan: ${premiumService.currentPlan}');
//       } catch (e) {
//         print('❌ PremiumService check failed: $e');
//       }
//     }
    
//     if (Get.isRegistered<PremiumController>()) {
//       try {
//         final premiumController = Get.find<PremiumController>();
//         print('🎮 PremiumController State:');
//         print('  isPremium: ${premiumController.isPremium.value}');
//         print('  currentPlan: ${premiumController.currentPlan.value}');
//         print('  isProcessing: ${premiumController.isProcessing.value}');
//       } catch (e) {
//         print('❌ PremiumController check failed: $e');
//       }
//     }
    
//     print('🔍 === DEBUG COMPLETE ===');
//   }

//   /// Test method to manually refresh everything with full debugging
//   Future<void> testManualRefresh() async {
//     print('🧪 === TESTING MANUAL REFRESH ===');
//     await _clearLocalStorageCache();
//     await Future.delayed(const Duration(seconds: 2));
//     await _refreshUserDataAndUI();
//     debugPremiumStatusUpdate();
//     print('🧪 === TEST COMPLETE ===');
//   }

//   @override
//   void onClose() {
//     print('🔄 Closing RazorpayService...');
//     try {
//       _razorpay.clear();
//       print('✅ Razorpay cleared successfully');
//     } catch (e) {
//       print('❌ Error clearing Razorpay: $e');
//     }
//     super.onClose();
//   }
// }
