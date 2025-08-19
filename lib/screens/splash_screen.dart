import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
    await Future.delayed(
      const Duration(seconds: 3),
    ); // Keep splash visible for 3 seconds

    final AuthService _authService = Get.find<AuthService>();

    // Check if user is already signed in
    final currentUser = _authService.currentUser.value;

    if (currentUser != null) {
      // User is already logged in, go to home
      Get.offAllNamed('/home');
    } else {
      // No active session, go to login
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo Animation
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4AA).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.trending_up,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // App Name
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF007AFF)],
              ).createShader(bounds),
              child: const Text(
                'WolfStock',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Tagline
            const Text(
              'Smart Investing with AI',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w300,
              ),
            ),

            const SizedBox(height: 50),

            // Loading Animation
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
            ),
          ],
        ),
      ),
    );
  }
}
