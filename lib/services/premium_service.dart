// lib/services/premium_service.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'razorpay_service.dart'; // Add proper import

class PremiumService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = Get.find<AuthService>();
  
  // Premium feature flags
  static const List<String> premiumFeatures = [
    'advanced_ai_insights',
    'portfolio_analytics',
    'price_alerts',
    'market_news',
    'technical_analysis',
    'export_data',
    'dark_web_integration',
    'priority_support',
    'custom_watchlists',
    'real_time_notifications'
  ];

  // Subscription plans with INR pricing for Razorpay
  static const Map<String, Map<String, dynamic>> subscriptionPlans = {
    'monthly': {
      'name': 'Monthly Premium',
      'price': 799.0, // ₹799 per month
      'currency': 'INR',
      'duration': 30,
      'features': premiumFeatures,
      'badge': 'Premium',
      'color': '0xFF00D4AA',
    },
    'yearly': {
      'name': 'Yearly Premium',
      'price': 7999.0, // ₹7,999 per year
      'currency': 'INR',
      'duration': 365,
      'features': premiumFeatures,
      'badge': 'Premium+',
      'color': '0xFF007AFF',
      'savings': '17%',
      'originalPrice': 9588.0, // 799 * 12
    },
    'lifetime': {
      'name': 'Lifetime Premium',
      'price': 24999.0, // ₹24,999 one-time
      'currency': 'INR',
      'duration': -1,
      'features': [...premiumFeatures, 'lifetime_updates'],
      'badge': 'Premium Pro',
      'color': '0xFFFFD700',
      'savings': '70%',
    },
  };

  @override
  void onInit() {
    super.onInit();
    // Listen to auth changes and check premium status
    ever(_authService.currentUser, _onUserChanged);
  }

  void _onUserChanged(UserModel? user) {
    if (user != null) {
      _checkPremiumStatus();
    }
  }

  /// Check if user has premium access
  bool get isPremiumUser {
    final user = _authService.currentUser.value;
    return user?.hasActivePremium ?? false;
  }

  /// Get current user's subscription plan
  String? get currentPlan {
    final user = _authService.currentUser.value;
    return user?.subscriptionPlan;
  }

  /// Get days until premium expires
  int get daysUntilExpiry {
    final user = _authService.currentUser.value;
    return user?.daysUntilPremiumExpiry ?? 0;
  }

  /// Check if premium is expiring soon
  bool get isExpiringSoon {
    final user = _authService.currentUser.value;
    return user?.isPremiumExpiringSoon ?? false;
  }

  /// Check if a specific feature is available
  bool hasFeature(String feature) {
    if (!isPremiumUser) return false;
    final user = _authService.currentUser.value;
    final plan = subscriptionPlans[user?.subscriptionPlan];
    return plan?['features']?.contains(feature) ?? false;
  }

  /// Get premium badge info
  Map<String, dynamic>? get premiumBadge {
    if (!isPremiumUser) return null;
    final user = _authService.currentUser.value;
    final plan = subscriptionPlans[user?.subscriptionPlan];
    return plan != null ? {
      'name': plan['badge'],
      'color': plan['color'],
    } : null;
  }

  /// Purchase premium subscription using Razorpay ONLY
  // In your premium_service.dart, update the purchasePremiumWithRazorpay method:

Future<bool> purchasePremiumWithRazorpay(String planType) async {
  print('PremiumService.purchasePremiumWithRazorpay called with: $planType');
  
  try {
    final user = _authService.currentUser.value;
    if (user == null) {
      Get.snackbar('Error', 'Please log in to purchase premium');
      return false;
    }

    final plan = subscriptionPlans[planType];
    if (plan == null) {
      Get.snackbar('Error', 'Invalid subscription plan');
      return false;
    }

    // Check if RazorpayService is available - REQUIRED
    if (!Get.isRegistered<RazorpayService>()) {
      Get.snackbar(
        'Payment Error',
        'Payment service is not available. Please restart the app and try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return false;
    }

    // Get Razorpay service
    final razorpayService = Get.find<RazorpayService>();
    
    print('Calling RazorpayService.processPremiumPayment');
    try {
      await razorpayService.processPremiumPayment(
        planType: planType,
        amount: plan['price'].toDouble(),
        planName: plan['name'],
      );

      // Payment initiated successfully - actual success/failure will be handled in Razorpay callbacks
      return true;
      
    } catch (e) {
      print('Payment processing failed: $e');
      return false;
    }

  } catch (e) {
    print('Error in purchasePremiumWithRazorpay: $e');
    Get.snackbar(
      'Payment Error',
      'Failed to process payment: $e',
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    return false;
  }
}


  // REMOVED: Mock purchasePremium method - no longer available

  /// Activate premium after successful Razorpay payment
  Future<bool> activatePremiumAfterPayment(String planType, String paymentId, {double? amount}) async {
  print('Activating premium for plan: $planType, paymentId: $paymentId');
  
  try {
    final plan = subscriptionPlans[planType];
    if (plan == null) {
      print('Invalid plan type: $planType');
      return false;
    }

    // Calculate expiry date
    DateTime? expiryDate;
    if (planType != 'lifetime') {
      expiryDate = DateTime.now().add(Duration(days: plan['duration']));
    }

    // Update user premium status with payment ID and amount
    await _updatePremiumStatus(
      isPremium: true,
      plan: planType,
      expiryDate: expiryDate,
      startDate: DateTime.now(),
      paymentId: paymentId,
      amount: amount ?? plan['price'],
    );

    print('Premium activated successfully');
    return true;

  } catch (e) {
    print('Error activating premium: $e');
    return false;
  }
}

Future<List<Map<String, dynamic>>> getDetailedPurchaseHistory() async {
  final user = _authService.currentUser.value;
  if (user == null) return [];

  try {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('purchase_history')
        .orderBy('purchaseDate', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  } catch (e) {
    print('Error fetching detailed purchase history: $e');
    return [];
  }
}

  /// Restore premium subscription - only works with real payment history
  Future<bool> restorePremium() async {
    try {
      final user = _authService.currentUser.value;
      if (user == null) return false;

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Check for actual payment history instead of mock restore
      final paymentHistory = await getPaymentHistory();
      
      if (paymentHistory.isEmpty) {
        Get.back();
        Get.snackbar(
          'No Purchases Found',
          'No previous purchases found to restore.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return false;
      }

      // Find the most recent completed payment
      final latestPayment = paymentHistory.first;
      final plan = latestPayment['plan'] as String?;
      
      if (plan == null) {
        Get.back();
        Get.snackbar('Error', 'Invalid payment record found');
        return false;
      }

      // Restore based on actual payment
      await _updatePremiumStatus(
        isPremium: true,
        plan: plan,
        expiryDate: DateTime.now().add(Duration(days: subscriptionPlans[plan]?['duration'] ?? 365)),
        startDate: DateTime.now(),
        paymentId: latestPayment['paymentId'],
      );

      Get.back();

      Get.snackbar(
        'Restored! 🎉',
        'Your premium subscription has been restored',
        backgroundColor: const Color(0xFF00D4AA),
        colorText: Colors.white,
      );

      return true;

    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Failed to restore subscription: $e');
      return false;
    }
  }

  /// Cancel premium subscription
  Future<bool> cancelPremium() async {
    try {
      final user = _authService.currentUser.value;
      if (user == null || !user.hasActivePremium) return false;

      Get.dialog(
        AlertDialog(
          title: const Text('Cancel Premium?'),
          content: const Text(
            'Are you sure you want to cancel your premium subscription? '
            'You\'ll lose access to premium features at the end of your billing cycle.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: const Text('Keep Premium'),
            ),
            TextButton(
              onPressed: () async {
                Get.back();
                
                // Mark subscription as cancelled but keep it active until expiry
                await _updatePremiumStatus(
                  isPremium: user.hasActivePremium,
                  plan: user.subscriptionPlan,
                  expiryDate: user.premiumExpiryDate,
                  startDate: user.subscriptionStartDate,
                  paymentId: user.lastPaymentId,
                  cancelled: true,
                );

                Get.snackbar(
                  'Subscription Cancelled',
                  'You\'ll keep premium features until ${user.premiumExpiryDate?.toString().split(' ')[0]}',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      return true;

    } catch (e) {
      Get.snackbar('Error', 'Failed to cancel subscription: $e');
      return false;
    }
  }

  /// Update premium status in Firestore - ONLY for Razorpay payments
  Future<void> _updatePremiumStatus({
  required bool isPremium,
  String? plan,
  DateTime? expiryDate,
  DateTime? startDate,
  String? paymentId,
  bool cancelled = false,
  double? amount, // Add amount parameter
}) async {
  final user = _authService.currentUser.value;
  if (user == null) return;

  print('Updating premium status for user: ${user.uid}');
  print('Plan: $plan, isPremium: $isPremium, paymentId: $paymentId');

  final updateData = {
    'isPremiumUser': isPremium,
    'subscriptionPlan': plan,
    'premiumExpiryDate': expiryDate?.toIso8601String(),
    'subscriptionStartDate': startDate?.toIso8601String(),
    'subscriptionCancelled': cancelled,
    'lastPaymentId': paymentId,
    'lastUpdated': DateTime.now().toIso8601String(),
  };

  try {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .update(updateData);

    // Store detailed payment record ONLY for real Razorpay payments
    if (paymentId != null && plan != null) {
      final planDetails = subscriptionPlans[plan];
      final purchaseAmount = amount ?? planDetails?['price'] ?? 0.0;
      
      // Generate a unique reference number
      final referenceNumber = 'WS${DateTime.now().millisecondsSinceEpoch}${user.uid.substring(0, 6).toUpperCase()}';
      
      // Calculate validity based on plan
      String validity;
      if (plan == 'lifetime') {
        validity = 'Lifetime';
      } else if (plan == 'yearly') {
        validity = '1 Year';
      } else if (plan == 'monthly') {
        validity = '1 Month';
      } else {
        validity = planDetails?['duration']?.toString() ?? 'N/A';
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('purchase_history')
          .doc(paymentId)
          .set({
        'referenceNumber': referenceNumber,
        'paymentId': paymentId,
        'plan': plan,
        'planName': planDetails?['name'] ?? plan,
        'amount': purchaseAmount,
        'currency': planDetails?['currency'] ?? 'INR',
        'validity': validity,
        'validityDays': planDetails?['duration'] ?? -1,
        'purchaseDate': DateTime.now().toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'status': 'completed',
        'method': 'razorpay',
        'features': planDetails?['features'] ?? [],
        'badge': planDetails?['badge'] ?? 'Premium',
        'savings': planDetails?['savings'],
        'userEmail': user.email,
        'userName': user.displayName ?? 'User',
      });

      print('Purchase history entry created with reference: $referenceNumber');
    }

    // Update local user data
    await _authService.updateUserProfile(updateData);
    
    print('Premium status updated successfully');

  } catch (e) {
    print('Error updating premium status: $e');
    rethrow;
  }
}

  /// Check premium status and update if expired
  Future<void> _checkPremiumStatus() async {
    final user = _authService.currentUser.value;
    if (user == null || !user.isPremiumUser) return;

    // Check if premium has expired
    if (!user.hasActivePremium && user.subscriptionPlan != 'lifetime') {
      await _updatePremiumStatus(
        isPremium: false,
        plan: null,
        expiryDate: null,
        startDate: null,
      );

      Get.snackbar(
        'Premium Expired',
        'Your premium subscription has expired. Renew to continue enjoying premium features.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Track premium feature usage
  Future<void> trackFeatureUsage(String feature) async {
    if (!hasFeature(feature)) return;

    final user = _authService.currentUser.value;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('feature_usage')
          .add({
        'feature': feature,
        'timestamp': DateTime.now().toIso8601String(),
        'plan': user.subscriptionPlan,
      });
    } catch (e) {
      print('Error tracking feature usage: $e');
    }
  }

  /// Show premium required dialog
  void showPremiumRequired(String feature) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.star,
              color: Color(0xFFFFD700),
            ),
            const SizedBox(width: 8),
            const Text('Premium Feature'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This feature requires a premium subscription. '
              'Upgrade now to unlock $feature and many more advanced features!',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✨ Premium features are currently under development\n'
                '🚀 Coming soon with amazing new capabilities!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed('/premium');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  /// Get feature availability with premium check
  bool checkFeatureAccess(String feature, {bool showDialog = true}) {
    if (hasFeature(feature)) {
      trackFeatureUsage(feature);
      return true;
    }

    if (showDialog) {
      showPremiumRequired(feature);
    }
    return false;
  }

  /// Get premium statistics
  Map<String, dynamic> getPremiumStats() {
    final user = _authService.currentUser.value;
    if (user == null || !user.hasActivePremium) {
      return {
        'isPremium': false,
        'plan': null,
        'daysRemaining': 0,
        'features': 0,
      };
    }

    final plan = subscriptionPlans[user.subscriptionPlan];
    return {
      'isPremium': true,
      'plan': user.subscriptionPlan,
      'planName': plan?['name'],
      'badge': plan?['badge'],
      'daysRemaining': user.daysUntilPremiumExpiry,
      'features': plan?['features']?.length ?? 0,
      'startDate': user.subscriptionStartDate,
      'expiryDate': user.premiumExpiryDate,
      'isExpiringSoon': user.isPremiumExpiringSoon,
    };
  }

  /// Get formatted price for display
  String getFormattedPrice(String planType) {
    final plan = subscriptionPlans[planType];
    if (plan == null) return '₹0';
    
    final price = plan['price'] as double;
    return '₹${price.toStringAsFixed(0)}';
  }

  /// Get savings amount for yearly plan
  String getYearlySavings() {
    final monthlyPrice = subscriptionPlans['monthly']?['price'] as double? ?? 0;
    final yearlyPrice = subscriptionPlans['yearly']?['price'] as double? ?? 0;
    final savings = (monthlyPrice * 12) - yearlyPrice;
    return '₹${savings.toStringAsFixed(0)}';
  }

  /// Check if Razorpay is available (must be true for payments to work)
  bool get isRazorpayAvailable => Get.isRegistered<RazorpayService>();

  /// Get payment history - only real Razorpay payments
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    final user = _authService.currentUser.value;
    if (user == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('payments')
          .where('method', isEqualTo: 'razorpay') // Only Razorpay payments
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }

  /// Utility method for debugging
  void debugPremiumStatus() {
    final user = _authService.currentUser.value;
    print('=== Premium Status Debug ===');
    print('User: ${user?.email}');
    print('Is Premium: $isPremiumUser');
    print('Current Plan: $currentPlan');
    print('Days Until Expiry: $daysUntilExpiry');
    print('Razorpay Available: $isRazorpayAvailable');
    print('Razorpay Service Registered: ${Get.isRegistered<RazorpayService>()}');
    print('===========================');
  }

  /// Validate payment setup
  bool validatePaymentSetup() {
    if (!Get.isRegistered<RazorpayService>()) {
      print('❌ RazorpayService not registered');
      return false;
    }
    
    final razorpayService = Get.find<RazorpayService>();
    if (!razorpayService.isInitialized) {
      print('❌ RazorpayService not initialized');
      return false;
    }
    
    print('✅ Payment setup is valid');
    return true;
  }
}
