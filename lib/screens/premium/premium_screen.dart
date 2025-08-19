// lib/screens/premium/premium_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/premium_controller.dart';
import '../../services/premium_service.dart';

class PremiumScreen extends StatelessWidget {
  final PremiumController controller = Get.put(PremiumController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF2D2D2D).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Obx(
            () => controller.isPremium ? _buildPremiumUser() : _buildUpgrade(),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumUser() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          _buildPremiumStatus(),
          const SizedBox(height: 30),
          _buildPremiumFeatures(),
          const SizedBox(height: 30),
          _buildPaymentHistory(),
          const SizedBox(height: 30),
          _buildManageSubscription(),
        ],
      ),
    );
  }

  Widget _buildUpgrade() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildUpgradeHero(),
          const SizedBox(height: 20),
          _buildPaymentSystemStatus(),
          const SizedBox(height: 30),
          _buildPricingPlans(),
          const SizedBox(height: 20),
          _buildFeaturesList(),
          const SizedBox(height: 30),
          _buildPaymentOptions(),
          const SizedBox(height: 20),
          _buildRestoreButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        Expanded(
          child: GetBuilder<PremiumController>(
            builder: (controller) => Text(
              controller.isPremium ? 'Premium Dashboard' : 'Upgrade to Premium',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Add refresh button for manual refresh
        IconButton(
          onPressed: () {
            controller.forceRefresh();
          },
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh Premium Status',
        ),
      ],
    );
  }

  Widget _buildUpgradeHero() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D4AA), Color(0xFF007AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.star, size: 60, color: Color(0xFFFFD700)),
          const SizedBox(height: 16),
          const Text(
            'Unlock Premium Features',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Get advanced AI insights, portfolio analytics, and exclusive features to maximize your investment potential.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Secure payments powered by Razorpay • 100% Safe',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Payment System Status Widget with reactive updates
  Widget _buildPaymentSystemStatus() {
    return GetBuilder<PremiumController>(
      builder: (controller) {
        final isAvailable = controller.isPaymentSystemAvailable;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAvailable
                ? const Color(0xFF00D4AA).withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAvailable
                  ? const Color(0xFF00D4AA).withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isAvailable ? Icons.check_circle : Icons.error,
                color: isAvailable ? const Color(0xFF00D4AA) : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAvailable
                          ? 'Payment System Ready'
                          : 'Payment System Unavailable',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isAvailable
                            ? const Color(0xFF00D4AA)
                            : Colors.red,
                      ),
                    ),
                    Text(
                      isAvailable
                          ? 'Razorpay payment gateway is ready for secure transactions'
                          : 'Please restart the app and try again',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (!isAvailable)
                ElevatedButton(
                  onPressed: () {
                    controller.forceRefresh();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(60, 30),
                  ),
                  child: const Text('Refresh', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumStatus() {
    return GetBuilder<PremiumController>(
      builder: (controller) {
        final stats = controller.premiumStats;
        final badge = controller.premiumBadge;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(int.parse(badge?['color'] ?? '0xFF00D4AA')),
                Color(
                  int.parse(badge?['color'] ?? '0xFF00D4AA'),
                ).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.verified, color: Colors.white, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      badge?['name'] ?? 'Premium User',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _showPremiumDetails();
                    },
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Plan',
                    stats['planName'] ?? 'Premium',
                    Icons.card_membership,
                  ),
                  _buildStatItem(
                    'Days Left',
                    controller.currentPlan == 'lifetime'
                        ? '∞'
                        : stats['daysRemaining'].toString(),
                    Icons.schedule,
                  ),
                  _buildStatItem(
                    'Features',
                    stats['features'].toString(),
                    Icons.star,
                  ),
                ],
              ),
              if (controller.isExpiringSoon) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your premium subscription expires in ${controller.daysUntilExpiry} days',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _showRenewalOptions();
                        },
                        child: const Text(
                          'Renew',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildPricingPlans() {
    return GetBuilder<PremiumController>(
      builder: (controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Your Plan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save ${controller.formattedYearlySavings} with yearly plan!',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...controller.plans.entries.map((entry) {
            return _buildPlanCard(entry.key, entry.value);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String planKey, Map<String, dynamic> plan) {
    final isRecommended = planKey == 'yearly';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            controller.selectedPlan.value = planKey;
          },
          borderRadius: BorderRadius.circular(16),
          child: Obx(() {
            final isSelected = controller.selectedPlan.value == planKey;

            return GetBuilder<PremiumController>(
              builder: (controller) {
                final isSystemAvailable = controller.isPaymentSystemAvailable;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Get.isDarkMode
                        ? const Color(0xFF2D2D2D)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00D4AA)
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isRecommended
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00D4AA).withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        plan['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isRecommended) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00D4AA),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Text(
                                          'BEST VALUE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '₹${plan['price'].toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00D4AA),
                                      ),
                                    ),
                                    if (planKey == 'monthly') ...[
                                      const Text(
                                        '/month',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ] else if (planKey == 'yearly') ...[
                                      const Text(
                                        '/year',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (plan['savings'] != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Save ${plan['savings']}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Radio<String>(
                            value: planKey,
                            groupValue: controller.selectedPlan.value,
                            onChanged: isSystemAvailable
                                ? (value) {
                                    if (value != null) {
                                      controller.selectedPlan.value = value;
                                    }
                                  }
                                : null,
                            activeColor: const Color(0xFF00D4AA),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Enhanced Payment Button with proper reactive updates
                      Obx(
                        () => ElevatedButton(
                          onPressed:
                              (!controller.isProcessing.value &&
                                  isSystemAvailable)
                              ? () {
                                  print(
                                    'Payment button pressed for plan: $planKey',
                                  );
                                  _handlePayment(planKey, plan);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSystemAvailable
                                ? const Color(0xFF00D4AA)
                                : Colors.grey,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: controller.isProcessing.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : !isSystemAvailable
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Payment System Unavailable',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.payment, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Pay ₹${plan['price'].toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      if (!isSystemAvailable) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Payment system is not available. Please restart the app and try again.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.credit_card,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.account_balance,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.phone_android,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cards, UPI, Net Banking',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  void _handlePayment(String planKey, Map<String, dynamic> plan) {
    print('=== Payment Debug Info ===');
    print('Plan: $planKey');
    print('Plan  $plan');

    try {
      controller.handlePaymentRequest(planKey);
    } catch (e) {
      print('Error in _handlePayment: $e');
      Get.snackbar(
        'Payment Error',
        'Failed to process payment: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildPaymentOptions() {
    return GetBuilder<PremiumController>(
      builder: (controller) {
        final isAvailable = controller.isPaymentSystemAvailable;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.security,
                    color: isAvailable ? const Color(0xFF00D4AA) : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Secure Payment Options',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isAvailable ? null : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00D4AA),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'UNAVAILABLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPaymentMethod(Icons.credit_card, 'Cards', isAvailable),
                  _buildPaymentMethod(
                    Icons.account_balance_wallet,
                    'UPI',
                    isAvailable,
                  ),
                  _buildPaymentMethod(
                    Icons.account_balance,
                    'Banking',
                    isAvailable,
                  ),
                  _buildPaymentMethod(Icons.wallet, 'Wallets', isAvailable),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isAvailable
                    ? 'Powered by Razorpay • 256-bit SSL Encryption'
                    : 'Payment system temporarily unavailable',
                style: TextStyle(
                  fontSize: 12,
                  color: isAvailable ? Colors.grey[600] : Colors.red[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethod(IconData icon, String label, bool isActive) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF00D4AA).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isActive ? const Color(0xFF00D4AA) : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: isActive ? null : Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPaymentHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF00D4AA)),
              const SizedBox(width: 8),
              const Text(
                'Payment History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Add refresh button for payment history
              IconButton(
                onPressed: () {
                  controller.forceRefresh();
                },
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh Payment History',
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: Get.find<PremiumService>().getPaymentHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No payment history available',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.take(3).map((payment) {
                  return _buildPaymentHistoryItem(payment);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryItem(Map<String, dynamic> payment) {
    final date = DateTime.parse(payment['timestamp']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00D4AA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payment['plan']?.toString().toUpperCase()} Plan',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${payment['amount']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00D4AA),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  payment['method']?.toString().toUpperCase() ?? 'RAZORPAY',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFF00D4AA),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    return GetBuilder<PremiumController>(
      builder: (controller) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Premium Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...controller.premiumFeatures.map((feature) {
              return _buildFeatureItem(feature);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    final featureName = feature.replaceAll('_', ' ').toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF00D4AA), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(featureName, style: const TextStyle(fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'COMING SOON',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatures() {
    return GetBuilder<PremiumController>(
      builder: (controller) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Premium Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...controller.premiumFeatures.take(5).map((feature) {
              return _buildActiveFeatureItem(feature);
            }).toList(),
            if (controller.premiumFeatures.length > 5) ...[
              const SizedBox(height: 8),
              Text(
                '+${controller.premiumFeatures.length - 5} more features',
                style: const TextStyle(
                  color: Color(0xFF00D4AA),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFeatureItem(String feature) {
    final featureName = feature.replaceAll('_', ' ').toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Color(0xFF00D4AA), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(featureName, style: const TextStyle(fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF00D4AA),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageSubscription() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              controller.cancelPremium();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Manage Subscription',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: () {
        controller.restorePremium();
      },
      child: const Text(
        'Restore Previous Purchase',
        style: TextStyle(color: Color(0xFF00D4AA), fontSize: 16),
      ),
    );
  }

  void _showPremiumDetails() {
    final stats = controller.premiumStats;
    Get.dialog(
      AlertDialog(
        title: const Text('Premium Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Plan: ${stats['planName']}'),
            Text('Started: ${stats['startDate']?.toString().split(' ')[0]}'),
            if (stats['expiryDate'] != null)
              Text('Expires: ${stats['expiryDate']?.toString().split(' ')[0]}'),
            Text('Features: ${stats['features']} active'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRenewalOptions() {
    Get.dialog(
      AlertDialog(
        title: const Text('Renew Subscription'),
        content: const Text(
          'Choose a plan to renew your premium subscription:',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Navigate back to pricing plans section
              Get.offAllNamed('/premium');
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }
}
