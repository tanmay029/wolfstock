// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../controllers/premium_controller.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final AuthService _authService = Get.find<AuthService>();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  RxString loadingMessage = 'Initializing app...'.obs;
  RxBool isSyncing = true.obs;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    _initializeAppWithRetries();
  }

  /// CRITICAL: Robust initialization with retries for fresh data
  Future<void> _initializeAppWithRetries() async {
    print('🚀 SplashScreen: Starting robust initialization...');
    
    try {
      isSyncing.value = true;
      
      // Step 1: Force refresh from Firestore (bypass cache)
      loadingMessage.value = 'Connecting to server...';
      await _authService.refreshCurrentUser();
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Step 2: Retry mechanism for premium status verification
      bool premiumVerified = false;
      int retryCount = 0;
      const maxRetries = 6;
      
      while (!premiumVerified && retryCount < maxRetries) {
        loadingMessage.value = retryCount == 0 
            ? 'Syncing premium features...'
            : 'Verifying premium status... (${retryCount + 1}/$maxRetries)';
        
        print('🔄 Attempt ${retryCount + 1}: Verifying premium status');
        
        // Force refresh again
        await _authService.refreshCurrentUser();
        
        final user = _authService.currentUser.value;
        if (user != null) {
          print('👤 User found: ${user.email}');
          print('💎 Premium status: ${user.hasActivePremium}');
          print('📅 Data timestamp: ${user.lastUpdated}');
          
          // Check if data is genuinely fresh (within last 2 minutes)
          final dataAge = user.lastUpdated != null 
              ? DateTime.now().difference(user.lastUpdated!).inMinutes
              : 999;
          
          if (dataAge <= 2) {
            print('✅ Data is fresh (${dataAge}m old)');
            premiumVerified = true;
            break;
          } else {
            print('⚠️ Data may be stale (${dataAge}m old), retrying...');
          }
        }
        
        retryCount++;
        if (retryCount < maxRetries) {
          // Exponential backoff: 1s, 2s, 4s, 6s, 8s, 10s
          final waitTime = retryCount <= 2 ? retryCount * 2 : retryCount + 4;
          await Future.delayed(Duration(seconds: waitTime));
        }
      }
      
      // Step 3: Update premium controller
      if (Get.isRegistered<PremiumController>()) {
        loadingMessage.value = 'Updating premium features...';
        final premiumController = Get.find<PremiumController>();
        premiumController.forceUpdate();
        await Future.delayed(const Duration(milliseconds: 600));
      }
      
      // Step 4: Final verification and navigation
      final user = _authService.currentUser.value;
      if (user != null) {
        if (user.hasActivePremium) {
          loadingMessage.value = 'Welcome back, Premium user! 🎉';
          await Future.delayed(const Duration(milliseconds: 1200));
        } else {
          loadingMessage.value = 'Welcome back!';
          await Future.delayed(const Duration(milliseconds: 800));
        }
        
        print('🏠 Navigating to home with premium status: ${user.hasActivePremium}');
        Get.offAllNamed('/home');
      } else {
        loadingMessage.value = 'Redirecting to login...';
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed('/login');
      }
      
    } catch (e) {
      print('❌ Error in initialization: $e');
      
      loadingMessage.value = 'Connection issue, retrying...';
      await Future.delayed(const Duration(seconds: 1));
      
      // Final fallback attempt
      try {
        await _authService.refreshCurrentUser();
        final user = _authService.currentUser.value;
        
        if (user != null) {
          loadingMessage.value = 'Connected! Loading...';
          await Future.delayed(const Duration(milliseconds: 800));
          Get.offAllNamed('/home');
        } else {
          Get.offAllNamed('/login');
        }
      } catch (finalError) {
        print('❌ Final attempt failed: $finalError');
        loadingMessage.value = 'Please check your connection';
        await Future.delayed(const Duration(seconds: 2));
        Get.offAllNamed('/login');
      }
    } finally {
      isSyncing.value = false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo with glow effect
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 2000),
                tween: Tween(begin: 0.8, end: 1.0),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4AA).withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              const Text(
                'WolfStock',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              
              const Text(
                'Smart Stock Analysis',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 50),
              
              // Loading indicator
              Obx(() => isSyncing.value 
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                    strokeWidth: 3.0,
                  )
                : const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00D4AA),
                    size: 40,
                  ),
              ),
              const SizedBox(height: 20),
              
              // Dynamic loading messages
              Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  loadingMessage.value,
                  key: ValueKey(loadingMessage.value),
                  style: TextStyle(
                    fontSize: 14,
                    color: loadingMessage.value.contains('Premium user') 
                        ? const Color(0xFF00D4AA) 
                        : Colors.grey,
                    fontWeight: loadingMessage.value.contains('Welcome') 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              )),
              
              const SizedBox(height: 80),
              
              // Version info
              const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
