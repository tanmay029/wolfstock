import 'package:get/get.dart';
import 'package:flutter/material.dart';

class BottomNavController extends GetxController {
  final RxInt _currentIndex = 0.obs;
  
  // Getters
  int get currentIndex => _currentIndex.value;
  
  // Tab names for reference
  final List<String> tabNames = [
    'Home',
    'Watchlist', 
    'AI Picks',
    'Profile'
  ];

  // Navigation items configuration
  final List<BottomNavigationBarItem> navigationItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
      tooltip: 'Home Screen',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bookmark_outline),
      activeIcon: Icon(Icons.bookmark),
      label: 'Watchlist',
      tooltip: 'Your Watchlist',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.auto_awesome_outlined),
      activeIcon: Icon(Icons.auto_awesome),
      label: 'AI Picks',
      tooltip: 'AI Recommendations',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
      tooltip: 'User Profile',
    ),
  ];

  // Badge counts for each tab (optional feature)
  final RxList<int> _badgeCounts = [0, 0, 0, 0].obs;
  List<int> get badgeCounts => _badgeCounts;

  // Track visited tabs for analytics
  final RxList<int> _visitedTabs = <int>[].obs;
  List<int> get visitedTabs => _visitedTabs;

  // Last visit times for each tab
  final RxList<DateTime?> _lastVisitTimes = <DateTime?>[null, null, null, null].obs;
  List<DateTime?> get lastVisitTimes => _lastVisitTimes;

  @override
  void onInit() {
    super.onInit();
    // Mark home tab as initially visited
    _markTabVisited(0);
  }

  /// Change to a specific page by index
  void changePage(int index) {
    if (index >= 0 && index < tabNames.length) {
      _currentIndex.value = index;
      _markTabVisited(index);
      _updateLastVisitTime(index);
      
      // Optional: Trigger haptic feedback
      _triggerHapticFeedback();
    }
  }

  /// Navigate to Home tab
  void goToHome() => changePage(0);

  /// Navigate to Watchlist tab
  void goToWatchlist() => changePage(1);

  /// Navigate to AI Picks tab
  void goToAIPicks() => changePage(2);

  /// Navigate to Profile tab
  void goToProfile() => changePage(3);

  /// Update badge count for a specific tab
  void updateBadgeCount(int tabIndex, int count) {
    if (tabIndex >= 0 && tabIndex < _badgeCounts.length) {
      _badgeCounts[tabIndex] = count;
    }
  }

  /// Clear badge count for a specific tab
  void clearBadge(int tabIndex) {
    updateBadgeCount(tabIndex, 0);
  }

  /// Clear all badges
  void clearAllBadges() {
    _badgeCounts.value = [0, 0, 0, 0];
  }

  /// Get current tab name
  String getCurrentTabName() {
    return tabNames[currentIndex];
  }

  /// Check if a specific tab is currently active
  bool isTabActive(int index) {
    return currentIndex == index;
  }

  /// Get total badge count across all tabs
  int getTotalBadgeCount() {
    return _badgeCounts.fold(0, (sum, count) => sum + count);
  }

  /// Mark a tab as visited
  void _markTabVisited(int index) {
    if (!_visitedTabs.contains(index)) {
      _visitedTabs.add(index);
    }
  }

  /// Update last visit time for a tab
  void _updateLastVisitTime(int index) {
    if (index >= 0 && index < _lastVisitTimes.length) {
      _lastVisitTimes[index] = DateTime.now();
    }
  }

  /// Trigger haptic feedback (optional)
  void _triggerHapticFeedback() {
    // You can implement haptic feedback here if needed
    // HapticFeedback.lightImpact();
  }

  /// Reset navigation state
  void reset() {
    _currentIndex.value = 0;
    _badgeCounts.value = [0, 0, 0, 0];
    _visitedTabs.clear();
    _lastVisitTimes.value = [null, null, null, null];
    _markTabVisited(0);
  }

  /// Get navigation analytics data
  Map<String, dynamic> getAnalyticsData() {
    return {
      'currentTab': getCurrentTabName(),
      'currentIndex': currentIndex,
      'visitedTabs': _visitedTabs.map((i) => tabNames[i]).toList(),
      'totalBadges': getTotalBadgeCount(),
      'lastVisitTimes': Map.fromIterables(
        tabNames,
        _lastVisitTimes.map((time) => time?.toIso8601String()).toList(),
      ),
    };
  }

  /// Handle back button press (returns true if handled)
  bool handleBackPress() {
    if (currentIndex != 0) {
      goToHome();
      return true;
    }
    return false;
  }

  /// Animation duration for tab transitions
  Duration get transitionDuration => const Duration(milliseconds: 300);

  /// Animation curve for tab transitions
  Curve get transitionCurve => Curves.easeInOutCubic;

  @override
  void onClose() {
    // Cleanup if needed
    super.onClose();
  }

  /// Debug information
  void printDebugInfo() {
    print('=== Bottom Navigation Debug Info ===');
    print('Current Index: $currentIndex');
    print('Current Tab: ${getCurrentTabName()}');
    print('Visited Tabs: ${_visitedTabs.map((i) => tabNames[i]).toList()}');
    print('Badge Counts: ${Map.fromIterables(tabNames, _badgeCounts)}');
    print('Total Badges: ${getTotalBadgeCount()}');
    print('=====================================');
  }
}

// Extension for additional bottom navigation features
extension BottomNavControllerExtension on BottomNavController {
  /// Quick access to check if home tab is active
  bool get isHomeActive => isTabActive(0);
  
  /// Quick access to check if watchlist tab is active
  bool get isWatchlistActive => isTabActive(1);
  
  /// Quick access to check if AI picks tab is active
  bool get isAIPicksActive => isTabActive(2);
  
  /// Quick access to check if profile tab is active
  bool get isProfileActive => isTabActive(3);

  /// Get icon for current tab
  IconData getCurrentTabIcon() {
    switch (currentIndex) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.bookmark;
      case 2:
        return Icons.auto_awesome;
      case 3:
        return Icons.person;
      default:
        return Icons.home;
    }
  }

  /// Get color for current tab
  Color getCurrentTabColor() {
    return const Color(0xFF00D4AA); // WolfStock primary color
  }
}
