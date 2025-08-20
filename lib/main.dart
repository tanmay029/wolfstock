// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wolfstock/bindings/app_bindings.dart';
import 'package:wolfstock/screens/premium/premium_screen.dart';
import 'package:wolfstock/services/premium_service.dart';
import 'package:wolfstock/services/razorpay_service.dart';

// Import your app files
import 'models/stock_model.dart';
import 'models/ai_recommendation_model.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/stock_api_service.dart';
import 'services/ai_service.dart';
import 'controllers/stock_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/bottom_nav_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/main_screen.dart';
import 'screens/stock/stock_detail_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('🚀 Initializing WolfStock App...');
    
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
    
    // Initialize Hive
    await Hive.initFlutter();
    print('✅ Hive initialized successfully');
    
    // Register Hive Adapters
    await _registerHiveAdapters();
    print('✅ Hive adapters registered successfully');
    
    // Initialize Core Services (Order matters for dependencies)
    await _initializeCoreServices();
    print('✅ All core services initialized successfully');
    
    print('🎉 App initialization complete - launching app...');
    
  } catch (e) {
    print('❌ Error initializing app: $e');
    // Still launch app even if some initialization fails
  }
  
  runApp(
    Phoenix(
      child: WolfStockApp(),
    ),
  );
}

/// Register all Hive adapters for data persistence
Future<void> _registerHiveAdapters() async {
  try {
    // Stock-related adapters
    Hive.registerAdapter(StockAdapter());
    Hive.registerAdapter(PricePointAdapter());
    
    // AI-related adapters
    Hive.registerAdapter(AIRecommendationAdapter());
    Hive.registerAdapter(RecommendationCategoryAdapter());
    
    // User-related adapters
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(UserPreferencesAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    
    print('📦 Registered ${[
      'Stock', 'PricePoint', 'AIRecommendation', 'RecommendationCategory',
      'UserModel', 'UserPreferences', 'UserProfile'
    ].length} Hive adapters');
    
  } catch (e) {
    print('❌ Error registering Hive adapters: $e');
    rethrow;
  }
}

/// Initialize core services in proper dependency order
Future<void> _initializeCoreServices() async {
  try {
    print('🔧 Initializing core services...');
    
    // 1. Initialize foundational services first (no dependencies)
    Get.put(StockApiService(), permanent: true);
    Get.put(AIService(), permanent: true);
    print('  ✅ API services initialized');
    
    // 2. Initialize AuthService (depends on Firebase)
    final authService = AuthService();
    Get.put(authService, permanent: true);
    print('  ✅ AuthService initialized');
    
    // 3. Initialize services that depend on AuthService
    Get.put(PremiumService(), permanent: true);
    Get.put(RazorpayService(), permanent: true);
    print('  ✅ Premium & Payment services initialized');
    
    // 4. Initialize UI controllers
    Get.put(ThemeController(), permanent: true);
    Get.put(StockController(), permanent: true);
    Get.put(BottomNavController(), permanent: true);
    print('  ✅ UI controllers initialized');
    
    // 5. CRITICAL: Initialize user data from local storage for persistent login
    // This must be done after all services are initialized
    await authService.initializeUserData();
    print('  ✅ User data initialized from local storage');
    
    // 6. Debug service status
    _debugServiceStatus();
    
  } catch (e) {
    print('❌ Error initializing core services: $e');
    rethrow;
  }
}

/// Debug method to verify all services are properly initialized
void _debugServiceStatus() {
  print('🔍 Service Status Check:');
  
  final services = [
    'AuthService',
    'StockApiService', 
    'AIService',
    'PremiumService',
    'RazorpayService',
    'StockController',
    'ThemeController',
    'BottomNavController'
  ];
  
  for (final service in services) {
    try {
      final isRegistered = Get.isRegistered(tag: service) || 
                          _checkServiceRegistration(service);
      print('  ${isRegistered ? '✅' : '❌'} $service');
    } catch (e) {
      print('  ❌ $service (Error: $e)');
    }
  }
  
  // Check user login status
  try {
    final authService = Get.find<AuthService>();
    final isLoggedIn = authService.isLoggedIn;
    final userEmail = authService.userEmail;
    print('  📱 User Status: ${isLoggedIn ? 'Logged in as $userEmail' : 'Not logged in'}');
  } catch (e) {
    print('  📱 User Status: Unable to check ($e)');
  }
}

/// Helper method to check if services are registered
bool _checkServiceRegistration(String serviceName) {
  try {
    switch (serviceName) {
      case 'AuthService':
        Get.find<AuthService>();
        return true;
      case 'StockApiService':
        Get.find<StockApiService>();
        return true;
      case 'AIService':
        Get.find<AIService>();
        return true;
      case 'PremiumService':
        Get.find<PremiumService>();
        return true;
      case 'RazorpayService':
        Get.find<RazorpayService>();
        return true;
      case 'StockController':
        Get.find<StockController>();
        return true;
      case 'ThemeController':
        Get.find<ThemeController>();
        return true;
      case 'BottomNavController':
        Get.find<BottomNavController>();
        return true;
      default:
        return false;
    }
  } catch (e) {
    return false;
  }
}

class WolfStockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'WolfStock - Smart Stock Analysis',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      
      // CRITICAL: Use AppBindings for additional controller management
      initialBinding: AppBindings(),
      
      // Set initial route
      initialRoute: '/splash',
      
      // Define all app routes
      getPages: [
        GetPage(
          name: '/splash', 
          page: () => SplashScreen(),
          transition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 300),
        ),
        GetPage(
          name: '/login', 
          page: () => LoginScreen(),
          transition: Transition.rightToLeft,
          transitionDuration: const Duration(milliseconds: 300),
        ),
        GetPage(
          name: '/register', 
          page: () => RegisterScreen(),
          transition: Transition.rightToLeft,
          transitionDuration: const Duration(milliseconds: 300),
        ),
        GetPage(
          name: '/forgot-password', 
          page: () => ForgotPasswordScreen(),
          transition: Transition.rightToLeft,
          transitionDuration: const Duration(milliseconds: 300),
        ),
        GetPage(
          name: '/home', 
          page: () => MainScreen(),
          transition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 400),
        ),
        GetPage(
          name: '/stock-detail', 
          page: () => StockDetailScreen(),
          transition: Transition.rightToLeft,
          transitionDuration: const Duration(milliseconds: 300),
        ),
        GetPage(
          name: '/premium', 
          page: () => PremiumScreen(),
          transition: Transition.rightToLeft,
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ],
      
      // Enhanced error handling
      unknownRoute: GetPage(
        name: '/notfound',
        page: () => Scaffold(
          appBar: AppBar(title: const Text('Page Not Found')),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Page not found'),
                SizedBox(height: 8),
                Text('The requested page does not exist.'),
              ],
            ),
          ),
        ),
      ),
      
      // Global settings
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
      
      // Logging and debugging
      enableLog: true,
      logWriterCallback: (String text, {bool isError = false}) {
        if (isError) {
          print('🔴 GetX Error: $text');
        } else {
          print('🟢 GetX Log: $text');
        }
      },
    );
  }
}


// // lib/main.dart
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:get/get.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:wolfstock/screens/premium/premium_screen.dart';
// import 'package:wolfstock/services/premium_service.dart';
// import 'package:wolfstock/services/razorpay_service.dart';

// // Import your app files
// import 'models/stock_model.dart';
// import 'models/ai_recommendation_model.dart';
// import 'models/user_model.dart';
// import 'services/auth_service.dart';
// import 'services/stock_api_service.dart';
// import 'services/ai_service.dart';
// import 'controllers/stock_controller.dart';
// import 'controllers/theme_controller.dart';
// import 'controllers/bottom_nav_controller.dart';
// import 'screens/splash_screen.dart';
// import 'screens/auth/login_screen.dart';
// import 'screens/auth/register_screen.dart';
// import 'screens/auth/forgot_password_screen.dart';
// import 'screens/home/main_screen.dart';
// import 'screens/stock/stock_detail_screen.dart';
// import 'theme/app_theme.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   try {
//     // Initialize Firebase
//     await Firebase.initializeApp();
//     print('Firebase initialized successfully');
    
//     // Initialize Hive
//     await Hive.initFlutter();
    
//     // Register Hive Adapters
//     Hive.registerAdapter(StockAdapter());
//     Hive.registerAdapter(PricePointAdapter());
//     Hive.registerAdapter(AIRecommendationAdapter());
//     Hive.registerAdapter(RecommendationCategoryAdapter());
//     Hive.registerAdapter(UserModelAdapter());
//     Hive.registerAdapter(UserPreferencesAdapter());
//     Hive.registerAdapter(UserProfileAdapter());
    
//     // Initialize Services
//     Get.put(AuthService());
//     Get.put(StockApiService());
//     Get.put(AIService());
//     Get.put(PremiumService()); 
//     Get.put(RazorpayService());
//     Get.put(StockController());
//     Get.put(ThemeController());
//     Get.put(BottomNavController());
    
//     print('All services initialized successfully');
    
//   } catch (e) {
//     print('Error initializing app: $e');
//   }
  
//   runApp(WolfStockApp());
// }

// class WolfStockApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'WolfStock',
//       theme: AppTheme.lightTheme,
//       darkTheme: AppTheme.darkTheme,
//       themeMode: ThemeMode.system,
//       debugShowCheckedModeBanner: false,
//       initialRoute: '/splash',
//       getPages: [
//         GetPage(name: '/splash', page: () => SplashScreen()),
//         GetPage(name: '/login', page: () => LoginScreen()),
//         GetPage(name: '/register', page: () => RegisterScreen()),
//         GetPage(name: '/forgot-password', page: () => ForgotPasswordScreen()),
//         GetPage(name: '/home', page: () => MainScreen()),
//         GetPage(name: '/stock-detail', page: () => StockDetailScreen()),
//         GetPage(name: '/premium', page: () => PremiumScreen()),
//       ],
//     );
//   }
// }
