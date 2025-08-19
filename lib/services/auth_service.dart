import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Add for local storage
import '../models/user_model.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Rx<User?> firebaseUser = Rx<User?>(null);
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  void _setInitialScreen(User? user) {
  if (user == null) {
    // Only redirect to login if we don't have cached user data
    if (currentUser.value == null) {
      Get.offAllNamed('/login');
    }
  } else {
    _loadUserData(user.uid);
    // Only redirect if not already on home screen
    if (Get.currentRoute != '/home') {
      Get.offAllNamed('/home');
    }
  }
}

  Future<bool> signUp(String email, String password, String displayName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await _createUserDocument(user, displayName);
        return true;
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
    return false;
  }

  Future<bool> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
    return false;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    currentUser.value = null; // Clear user data on sign out
    await _clearUserFromLocal(); // Clear local storage
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
    return false;
  }

  Future<void> _createUserDocument(User user, String displayName) async {
    final userModel = UserModel(
      uid: user.uid,
      email: user.email!,
      displayName: displayName,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      // Initialize premium-related fields
      isPremiumUser: false,
      premiumExpiryDate: null,
      subscriptionPlan: null,
      subscriptionStartDate: null,
      premiumFeaturesUsed: [],
      lastPaymentId: null,
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toJson());
    currentUser.value = userModel;
    await _saveUserToLocal(userModel); // Save to local storage
  }

  Future<void> _loadUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final userData = UserModel.fromJson({
          'uid': uid,
          ...doc.data() as Map<String, dynamic>,
        });
        currentUser.value = userData;
        await _saveUserToLocal(userData); // Save to local storage
      }
    } catch (e) {
      print('Error loading user  $e');
    }
  }

  /// CRITICAL: Refresh current user data from Firestore (needed for premium status updates)
  Future<void> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      print('Refreshing user data from Firestore...');
      
      final userData = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        final updatedUser = UserModel.fromJson({
          'uid': user.uid,
          ...userData.data()!,
        });
        
        currentUser.value = updatedUser; // This triggers reactive updates
        currentUser.refresh(); 
        await _saveUserToLocal(updatedUser);
        
        print('User data refreshed successfully - isPremium: ${updatedUser.hasActivePremium}');
      }
    } catch (e) {
      print('Error refreshing user  $e');
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (firebaseUser.value != null) {
      try {
        // Add timestamp to track when data was last updated
        final updateData = {
          ...data,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
        
        await _firestore.collection('users').doc(firebaseUser.value!.uid).update(updateData);
        await _loadUserData(firebaseUser.value!.uid);
        currentUser.refresh();
        
        print('User profile updated successfully');
      } catch (e) {
        print('Error updating user profile: $e');
        rethrow;
      }
    }
  }

  Future<void> addToWatchlist(String symbol) async {
    if (currentUser.value != null) {
      List<String> updatedWatchlist = List.from(currentUser.value!.watchlist);
      if (!updatedWatchlist.contains(symbol)) {
        updatedWatchlist.add(symbol);
        await updateUserProfile({'watchlist': updatedWatchlist});
      }
    }
  }

  Future<void> removeFromWatchlist(String symbol) async {
    if (currentUser.value != null) {
      List<String> updatedWatchlist = List.from(currentUser.value!.watchlist);
      updatedWatchlist.remove(symbol);
      await updateUserProfile({'watchlist': updatedWatchlist});
    }
  }

  /// Add to portfolio symbols
  Future<void> addToPortfolio(String symbol) async {
    if (currentUser.value != null) {
      List<String> updatedPortfolio = List.from(currentUser.value!.portfolioSymbols);
      if (!updatedPortfolio.contains(symbol)) {
        updatedPortfolio.add(symbol);
        await updateUserProfile({'portfolioSymbols': updatedPortfolio});
      }
    }
  }

  /// Remove from portfolio symbols
  Future<void> removeFromPortfolio(String symbol) async {
    if (currentUser.value != null) {
      List<String> updatedPortfolio = List.from(currentUser.value!.portfolioSymbols);
      updatedPortfolio.remove(symbol);
      await updateUserProfile({'portfolioSymbols': updatedPortfolio});
    }
  }

  /// Update user preferences (theme, notifications, etc.)
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    if (currentUser.value != null) {
      await updateUserProfile({'preferences': preferences});
    }
  }

  /// Update FCM token for push notifications
  Future<void> updateFCMToken(String token) async {
    if (currentUser.value != null) {
      await updateUserProfile({
        'fcmToken': token,
        'lastActiveAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Save user data to local storage (Hive)
  Future<void> _saveUserToLocal(UserModel user) async {
    try {
      final box = await Hive.openBox('userBox');
      await box.put('currentUser', user.toJson());
      print('User data saved to local storage');
    } catch (e) {
      print('Error saving user to local storage: $e');
    }
  }

  /// Load user data from local storage
  Future<UserModel?> _loadUserFromLocal() async {
    try {
      final box = await Hive.openBox('userBox');
      final userData = box.get('currentUser');
      if (userData != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(userData));
      }
    } catch (e) {
      print('Error loading user from local storage: $e');
    }
    return null;
  }

  /// Clear user data from local storage
  Future<void> _clearUserFromLocal() async {
    try {
      final box = await Hive.openBox('userBox');
      await box.delete('currentUser');
      print('User data cleared from local storage');
    } catch (e) {
      print('Error clearing user from local storage: $e');
    }
  }

  /// Initialize user data (called on app start)
  Future<void> initializeUserData() async {
  final user = _auth.currentUser;
  if (user != null) {
    // Try to load from local storage first for faster UI
    final localUser = await _loadUserFromLocal();
    if (localUser != null) {
      currentUser.value = localUser;
      print('User loaded from local storage: ${localUser.email}');
    }
    
    // Then refresh from Firestore to ensure data is up-to-date
    await _loadUserData(user.uid);
  } else {
    // Check if we have cached user data even without Firebase user
    final localUser = await _loadUserFromLocal();
    if (localUser != null) {
      // Try to reauthenticate or handle cached data appropriately
      print('Found cached user data but no Firebase user');
      await _clearUserFromLocal();
    }
  }
}

  /// Check if user has premium access (helper method)
  bool get isPremiumUser => currentUser.value?.hasActivePremium ?? false;

  /// Get user display name safely
  String get userDisplayName => currentUser.value?.displayName ?? 'User';

  /// Get user email safely
  String get userEmail => currentUser.value?.email ?? '';

  /// Check if user is logged in
  bool get isLoggedIn => firebaseUser.value != null && currentUser.value != null;

  /// Stream of user premium status changes
  Stream<bool> get premiumStatusStream {
    return currentUser.stream.map((user) => user?.hasActivePremium ?? false);
  }

  /// Update last active timestamp
  Future<void> updateLastActive() async {
    if (currentUser.value != null) {
      await updateUserProfile({
        'lastActiveAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Delete user account (if needed)
  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Delete Firebase Auth account
        await user.delete();
        
        // Clear local data
        await _clearUserFromLocal();
        currentUser.value = null;
        
        return true;
      }
    } catch (e) {
      print('Error deleting account: $e');
      Get.snackbar('Error', 'Failed to delete account: $e');
    }
    return false;
  }

  /// Debug method to check current user state
  void debugUserState() {
    print('=== AuthService Debug ===');
    print('Firebase User: ${firebaseUser.value?.email}');
    print('Current User: ${currentUser.value?.email}');
    print('Is Premium: ${currentUser.value?.hasActivePremium}');
    print('Premium Plan: ${currentUser.value?.subscriptionPlan}');
    print('Last Payment ID: ${currentUser.value?.lastPaymentId}');
    print('========================');
  }
}
