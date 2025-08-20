import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wolfstock/controllers/premium_controller.dart';
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
    currentUser.value = null;
    await _clearUserFromLocal();
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
      lastUpdated: DateTime.now(), // CRITICAL: Add timestamp
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
    await _saveUserToLocal(userModel);
  }

  /// Enhanced data loading with stale data filtering
  Future<void> _loadUserData(String uid) async {
    try {
      print('Loading user data from Firestore for UID: $uid');
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final rawData = doc.data() as Map<String, dynamic>;
        
        // CRITICAL: Add current timestamp if not present
        if (!rawData.containsKey('lastUpdated')) {
          rawData['lastUpdated'] = DateTime.now().toIso8601String();
        }
        
        final userData = UserModel.fromJson({
          'uid': uid,
          ...rawData,
        });
        
        // CRITICAL: Only update if data is fresher than current
        if (_shouldUpdateUserData(userData)) {
          currentUser.value = userData;
          currentUser.refresh();
          await _saveUserToLocal(userData);
          
          print('User data loaded - isPremium: ${userData.hasActivePremium}');
          print('User plan: ${userData.subscriptionPlan}');
          print('Data timestamp: ${userData.lastUpdated}');
        } else {
          print('Skipping user data update - current data is fresher');
        }
      }
    } catch (e) {
      print('Error loading user  $e');
    }
  }

  /// CRITICAL: Enhanced refresh with smart cache handling and stale data filtering
  Future<void> refreshCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      print('Refreshing user data from Firestore...');
      
      // Reload Firebase user first
      await user.reload();
      
      // Force fresh fetch from server with retry logic
      for (int attempt = 0; attempt < 3; attempt++) {
        final userData = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          final isFromCache = userData.metadata.isFromCache;
          final hasPendingWrites = userData.metadata.hasPendingWrites;
          
          print('Data from cache: $isFromCache');
          print('Has pending writes: $hasPendingWrites');
          
          // CRITICAL: Skip cached data on first attempts, wait for server data
          if (isFromCache && attempt < 2) {
            print('Got cached data on attempt $attempt, waiting for server data...');
            await Future.delayed(Duration(seconds: attempt + 1));
            continue;
          }
          
          final rawData = userData.data() as Map<String, dynamic>;
          
          // CRITICAL: Ensure timestamp exists for comparison
          if (!rawData.containsKey('lastUpdated')) {
            rawData['lastUpdated'] = DateTime.now().toIso8601String();
          }
          
          final updatedUser = UserModel.fromJson({
            'uid': user.uid,
            ...rawData,
          });
          
          // CRITICAL: Only update if this is fresher data
          if (_shouldUpdateUserData(updatedUser)) {
            final dataAge = DateTime.now().difference(updatedUser.lastUpdated ?? DateTime.now()).inSeconds;
            
            print('User data age: ${dataAge}s');
            print('Fresh data - isPremium: ${updatedUser.hasActivePremium}');
            print('Fresh data - plan: ${updatedUser.subscriptionPlan}');
            
            currentUser.value = updatedUser;
            currentUser.refresh();
            await _saveUserToLocal(updatedUser);
            
            // Notify dependent controllers with fresh data
            _notifyDependentControllers();
          } else {
            print('Received stale data, keeping current data');
          }
          
          break; // Exit retry loop on success
        }
      }
    } catch (e) {
      print('Error refreshing user  $e');
    }
  }

  /// CRITICAL: Smart data freshness validation
  bool _shouldUpdateUserData(UserModel newUser) {
    final currentUserData = currentUser.value;
    
    // If no current data, accept new data
    if (currentUserData == null) {
      print('No current user data, accepting new data');
      return true;
    }
    
    // If new data has no timestamp, reject it as potentially stale
    if (newUser.lastUpdated == null) {
      print('New data has no timestamp, rejecting as potentially stale');
      return false;
    }
    
    // If current data has no timestamp, accept new data
    if (currentUserData.lastUpdated == null) {
      print('Current data has no timestamp, accepting new data');
      return true;
    }
    
    // Compare timestamps - only accept if new data is newer
    final isNewer = newUser.lastUpdated!.isAfter(currentUserData.lastUpdated!);
    print('Timestamp comparison - New: ${newUser.lastUpdated}, Current: ${currentUserData.lastUpdated}, IsNewer: $isNewer');
    
    return isNewer;
  }

  /// Enhanced controller notification with error handling
  void _notifyDependentControllers() {
    try {
      if (Get.isRegistered<PremiumController>()) {
        final controller = Get.find<PremiumController>();
        controller.initializeReactiveVariables();
        controller.update();
        print('PremiumController notified of data update');
      }
    } catch (e) {
      print('Error updating PremiumController: $e');
    }
  }

  /// Real-time listener with cache filtering
  void startUserDocumentListener() {
    final user = _auth.currentUser;
    if (user == null) return;
    
    _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
      if (snapshot.exists) {
        final isFromCache = snapshot.metadata.isFromCache;
        final hasPendingWrites = snapshot.metadata.hasPendingWrites;
        
        print('Real-time update - fromCache: $isFromCache, pendingWrites: $hasPendingWrites');
        
        // CRITICAL: Only process server data, ignore cache
        if (!isFromCache) {
          final rawData = snapshot.data() as Map<String, dynamic>;
          
          // Ensure timestamp exists
          if (!rawData.containsKey('lastUpdated')) {
            rawData['lastUpdated'] = DateTime.now().toIso8601String();
          }
          
          final userData = UserModel.fromJson({
            'uid': user.uid,
            ...rawData,
          });
          
          // Only update if fresher data
          if (_shouldUpdateUserData(userData)) {
            currentUser.value = userData;
            currentUser.refresh();
            
            print('Real-time update applied - isPremium: ${userData.hasActivePremium}');
            
            // Notify dependent controllers
            _notifyDependentControllers();
          } else {
            print('Real-time update ignored - stale data');
          }
        } else {
          print('Ignoring cached snapshot update');
        }
      }
    });
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (firebaseUser.value != null) {
      try {
        // CRITICAL: Always add timestamp to track when data was last updated
        final updateData = {
          ...data,
          'lastUpdated': DateTime.now().toIso8601String(),
        };

        await _firestore
            .collection('users')
            .doc(firebaseUser.value!.uid)
            .update(updateData);
        
        // Wait a moment for Firestore to propagate
        await Future.delayed(const Duration(milliseconds: 500));
        
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

  Future<void> addToPortfolio(String symbol) async {
    if (currentUser.value != null) {
      List<String> updatedPortfolio = List.from(
        currentUser.value!.portfolioSymbols,
      );
      if (!updatedPortfolio.contains(symbol)) {
        updatedPortfolio.add(symbol);
        await updateUserProfile({'portfolioSymbols': updatedPortfolio});
      }
    }
  }

  Future<void> removeFromPortfolio(String symbol) async {
    if (currentUser.value != null) {
      List<String> updatedPortfolio = List.from(
        currentUser.value!.portfolioSymbols,
      );
      updatedPortfolio.remove(symbol);
      await updateUserProfile({'portfolioSymbols': updatedPortfolio});
    }
  }

  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    if (currentUser.value != null) {
      await updateUserProfile({'preferences': preferences});
    }
  }

  Future<void> updateFCMToken(String token) async {
    if (currentUser.value != null) {
      await updateUserProfile({
        'fcmToken': token,
        'lastActiveAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Enhanced local storage with metadata
  Future<void> _saveUserToLocal(UserModel user) async {
    try {
      final box = await Hive.openBox('userBox');
      final dataWithMetadata = {
        ...user.toJson(),
        'savedAt': DateTime.now().toIso8601String(),
      };
      await box.put('currentUser', dataWithMetadata);
      print('User data saved to local storage with timestamp: ${user.lastUpdated}');
    } catch (e) {
      print('Error saving user to local storage: $e');
    }
  }

  Future<UserModel?> _loadUserFromLocal() async {
    try {
      final box = await Hive.openBox('userBox');
      final userData = box.get('currentUser');
      if (userData != null) {
        final data = Map<String, dynamic>.from(userData);
        print('User loaded from local storage: ${data['email']}');
        print('Local data timestamp: ${data['lastUpdated']}');
        return UserModel.fromJson(data);
      }
    } catch (e) {
      print('Error loading user from local storage: $e');
    }
    return null;
  }

  Future<void> _clearUserFromLocal() async {
    try {
      final box = await Hive.openBox('userBox');
      await box.clear();
      print('User data cleared from local storage');
    } catch (e) {
      print('Error clearing user from local storage: $e');
    }
  }

  /// Enhanced initialization with smart caching
  Future<void> initializeUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      print('Initializing user data...');
      
      // Force reload Firebase user first
      await user.reload();
      
      // Load from local cache first for immediate UI
      final localUser = await _loadUserFromLocal();
      if (localUser != null) {
        currentUser.value = localUser;
        print('Loaded user from local cache: ${localUser.email}');
      }
      
      // Then refresh from Firestore to get latest data
      await refreshCurrentUser();
      
      // Start real-time listener for future updates
      startUserDocumentListener();
      
      print('User initialization complete');
    }
  }

  // Helper methods and getters remain the same...
  bool get isPremiumUser => currentUser.value?.hasActivePremium ?? false;
  String get userDisplayName => currentUser.value?.displayName ?? 'User';
  String get userEmail => currentUser.value?.email ?? '';
  bool get isLoggedIn => firebaseUser.value != null && currentUser.value != null;

  Stream<bool> get premiumStatusStream {
    return currentUser.stream.map((user) => user?.hasActivePremium ?? false);
  }

  Future<void> updateLastActive() async {
    if (currentUser.value != null) {
      await updateUserProfile({
        'lastActiveAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
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

  void debugUserState() {
    print('=== AuthService Debug ===');
    print('Firebase User: ${firebaseUser.value?.email}');
    print('Current User: ${currentUser.value?.email}');
    print('Is Premium: ${currentUser.value?.hasActivePremium}');
    print('Premium Plan: ${currentUser.value?.subscriptionPlan}');
    print('Last Payment ID: ${currentUser.value?.lastPaymentId}');
    print('Data Timestamp: ${currentUser.value?.lastUpdated}');
    print('========================');
  }
}
