// lib/screens/home/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wolfstock/services/premium_service.dart';
import '../../services/auth_service.dart';
import '../../controllers/theme_controller.dart';

class ProfileScreen extends StatelessWidget {
  final AuthService _authService = Get.find<AuthService>();
  final ThemeController _themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Get.isDarkMode 
                ? [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)]
                : [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 30),
                _buildProfileStats(),
                const SizedBox(height: 30),
                _buildPremiumCard(), // Add premium card
                const SizedBox(height: 30),
                _buildSettingsSection(),
                const SizedBox(height: 30),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Obx(() {
      final user = _authService.currentUser.value;
      final premiumService = Get.find<PremiumService>();
      
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00D4AA), Color(0xFF007AFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D4AA).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              user?.displayName ?? 'User',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            
            // Dynamic Premium Badge
            if (premiumService.isPremiumUser) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFFFD700),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      premiumService.premiumBadge?['name'] ?? 'Premium',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Show expiry warning if needed
              if (premiumService.isExpiringSoon) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: Text(
                    'Expires in ${premiumService.daysUntilExpiry} days',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ] else ...[
              GestureDetector(
                onTap: () => Get.toNamed('/premium'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.star_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '⭐ Upgrade to Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildProfileStats() {
    return Obx(() {
      final user = _authService.currentUser.value;
      final premiumService = Get.find<PremiumService>();
      
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Watchlist',
              '${user?.watchlist.length ?? 0}',
              Icons.bookmark,
              const Color(0xFF00D4AA),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              'Portfolio',
              premiumService.isPremiumUser ? '5' : '0',
              Icons.pie_chart,
              Colors.orange,
              isPremium: !premiumService.isPremiumUser,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              'Alerts',
              premiumService.isPremiumUser ? '3' : '0',
              Icons.notifications,
              Colors.red,
              isPremium: !premiumService.isPremiumUser,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isPremium = false}) {
    return GestureDetector(
      onTap: isPremium ? () => Get.toNamed('/premium') : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: isPremium ? Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            width: 1,
          ) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Icon(icon, color: isPremium ? Colors.grey : color, size: 24),
                if (isPremium)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Icon(
                      Icons.star,
                      color: const Color(0xFFFFD700),
                      size: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isPremium ? Colors.grey : null,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: isPremium ? Colors.grey : Colors.grey,
                fontSize: 12,
              ),
            ),
            if (isPremium) ...[
              const SizedBox(height: 4),
              const Text(
                'PREMIUM',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // New Premium Card Widget
  Widget _buildPremiumCard() {
    return Obx(() {
      final premiumService = Get.find<PremiumService>();
      
      if (premiumService.isPremiumUser) {
        // Premium user card
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    premiumService.premiumBadge?['name'] ?? 'Premium User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.toNamed('/premium'),
                    icon: const Icon(Icons.settings, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Plan',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          premiumService.currentPlan?.toUpperCase() ?? 'PREMIUM',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Days Left',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          premiumService.currentPlan == 'lifetime' 
                              ? '∞' 
                              : '${premiumService.daysUntilExpiry}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Features',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const Text(
                          '10+',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        // Upgrade to premium card
        return GestureDetector(
          onTap: () => Get.toNamed('/premium'),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF007AFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4AA).withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFD700), size: 30),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unlock Premium Features',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Advanced AI insights, portfolio analytics & more',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🚀 Premium features coming soon! Get early access.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            'Dark Mode',
            'Toggle dark/light theme',
            Icons.dark_mode,
            trailing: Obx(() => Switch(
              value: _themeController.isDarkMode.value,
              onChanged: (value) => _themeController.toggleTheme(),
              activeColor: const Color(0xFF00D4AA),
            )),
          ),
          _buildDivider(),
          _buildSettingsTile(
            'Premium Features',
            'Manage your subscription',
            Icons.star,
            onTap: () => Get.toNamed('/premium'),
            isPremiumFeature: true,
          ),
          _buildDivider(),
          _buildSettingsTile(
            'Notifications',
            'Manage alert preferences',
            Icons.notifications_outlined,
            onTap: () {
              final premiumService = Get.find<PremiumService>();
              if (premiumService.checkFeatureAccess('price_alerts')) {
                Get.snackbar('Coming Soon', 'Notification settings will be available soon');
              }
            },
            isPremiumFeature: true,
          ),
          _buildDivider(),
          _buildSettingsTile(
            'Security',
            'Password and security settings',
            Icons.security,
            onTap: () => Get.snackbar('Coming Soon', 'Security settings will be available soon'),
          ),
          _buildDivider(),
          _buildSettingsTile(
            'Privacy Policy',
            'Read our privacy policy',
            Icons.privacy_tip_outlined,
            onTap: () => Get.snackbar('Coming Soon', 'Privacy policy will be available soon'),
          ),
          _buildDivider(),
          _buildSettingsTile(
            'Help & Support',
            'Get help and contact support',
            Icons.help_outline,
            onTap: () => Get.snackbar('Coming Soon', 'Help center will be available soon'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    Widget? trailing,
    bool isPremiumFeature = false,
  }) {
    final premiumService = Get.find<PremiumService>();
    final hasAccess = !isPremiumFeature || premiumService.isPremiumUser;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF00D4AA).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Icon(
              icon, 
              color: hasAccess ? const Color(0xFF00D4AA) : Colors.grey, 
              size: 20,
            ),
            if (isPremiumFeature && !hasAccess)
              Positioned(
                right: -2,
                top: -2,
                child: Icon(
                  Icons.star,
                  color: const Color(0xFFFFD700),
                  size: 10,
                ),
              ),
          ],
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: hasAccess ? null : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: hasAccess ? Colors.grey : Colors.grey.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
      trailing: trailing ?? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPremiumFeature && !hasAccess) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.withOpacity(0.2),
      height: 1,
      indent: 60,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Get.snackbar('Coming Soon', 'Edit profile will be available soon'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _showLogoutDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Get.isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _authService.signOut();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
