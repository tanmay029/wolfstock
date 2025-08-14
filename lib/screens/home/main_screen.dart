// lib/screens/home/main_screen.dart (Updated)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bottom_nav_controller.dart';
import 'home_screen.dart';
import 'watchlist_screen.dart';
import 'ai_picks_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatelessWidget {
  final BottomNavController bottomNavController = Get.put(BottomNavController());

  final List<Widget> _screens = [
    HomeScreen(),
    WatchlistScreen(),
    AIPicksScreen(),
    ProfileScreen(),
  ];

  MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return !bottomNavController.handleBackPress();
      },
      child: Scaffold(
        body: Obx(() => AnimatedSwitcher(
          duration: bottomNavController.transitionDuration,
          switchInCurve: bottomNavController.transitionCurve,
          switchOutCurve: bottomNavController.transitionCurve,
          child: _screens[bottomNavController.currentIndex],
        )),
        bottomNavigationBar: Obx(() => _buildBottomNavigationBar()),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Get.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: bottomNavController.currentIndex,
          onTap: (index) {
            bottomNavController.changePage(index);
            // Clear badge when tab is tapped
            bottomNavController.clearBadge(index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Get.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          selectedItemColor: const Color(0xFF00D4AA),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          elevation: 0,
          items: bottomNavController.navigationItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final badgeCount = bottomNavController.badgeCounts[index];
            
            return BottomNavigationBarItem(
              icon: _buildIconWithBadge(item.icon as Icon, badgeCount),
              activeIcon: _buildIconWithBadge(item.activeIcon as Icon, badgeCount),
              label: item.label,
              tooltip: item.tooltip,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildIconWithBadge(Icon icon, int badgeCount) {
    if (badgeCount <= 0) {
      return icon;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              badgeCount > 99 ? '99+' : badgeCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
