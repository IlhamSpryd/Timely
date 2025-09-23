import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/views/auth/login_page.dart';
import 'package:timely/views/main/main_wrapper.dart';
import 'package:timely/views/onboarding_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation for text and loader
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();

    // Check user state and navigate accordingly
    _checkUserState();
  }

  Future<void> _checkUserState() async {
    final prefs = await SharedPreferences.getInstance();

    // Delay untuk splash screen
    await Future.delayed(const Duration(milliseconds: 2500));

    final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (mounted) {
      if (!hasSeenOnboarding) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Onboarding()),
        );
      } else if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainWrapper()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background putih
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation
            SizedBox(
              width: 350,
              height: 350,
              child: Lottie.asset(
                'assets/images/splashscreen.json', // ganti path sesuai file Lottie kamu
                repeat: true,
                animate: true,
              ),
            ),
            const SizedBox(height: 40),

            // Animated App Name
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                "Timely",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Animated Tagline
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                "Professional Attendance",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 60),

            // Loading Indicator
            FadeTransition(
              opacity: _fadeAnimation,
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.black54),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
