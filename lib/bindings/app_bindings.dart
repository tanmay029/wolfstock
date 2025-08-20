// lib/bindings/app_bindings.dart
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:wolfstock/controllers/bottom_nav_controller.dart';
import 'package:wolfstock/controllers/premium_controller.dart';
import 'package:wolfstock/services/auth_service.dart';
import 'package:wolfstock/services/premium_service.dart';
import 'package:wolfstock/services/razorpay_service.dart';

// lib/bindings/app_bindings.dart
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Keep controllers persistent throughout app lifecycle
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<PremiumService>(() => PremiumService(), fenix: true);
    Get.lazyPut<RazorpayService>(() => RazorpayService(), fenix: true);
    Get.lazyPut<PremiumController>(() => PremiumController(), fenix: true);
    Get.lazyPut<BottomNavController>(() => BottomNavController(), fenix: true);
    
    print('🏗️ All controllers initialized as persistent singletons');
  }
}

