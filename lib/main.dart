// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    // Initialize Firebase
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
    
    // Initialize Hive
    await Hive.initFlutter();
    
    // Register Hive Adapters
    Hive.registerAdapter(StockAdapter());
    Hive.registerAdapter(PricePointAdapter());
    Hive.registerAdapter(AIRecommendationAdapter());
    Hive.registerAdapter(RecommendationCategoryAdapter());
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(UserPreferencesAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    
    // Initialize Services
    Get.put(AuthService());
    Get.put(StockApiService());
    Get.put(AIService());
    Get.put(PremiumService()); 
    Get.put(RazorpayService());
    Get.put(StockController());
    Get.put(ThemeController());
    Get.put(BottomNavController());
    
    print('All services initialized successfully');
    
  } catch (e) {
    print('Error initializing app: $e');
  }
  
  runApp(WolfStockApp());
}

class WolfStockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'WolfStock',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => SplashScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/register', page: () => RegisterScreen()),
        GetPage(name: '/forgot-password', page: () => ForgotPasswordScreen()),
        GetPage(name: '/home', page: () => MainScreen()),
        GetPage(name: '/stock-detail', page: () => StockDetailScreen()),
        GetPage(name: '/premium', page: () => PremiumScreen()),
      ],
    );
  }
}
