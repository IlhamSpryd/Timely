import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/views/auth/login_page.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _parallaxController;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  int _currentPage = 0;
  bool _isTransitioning = false;

  // App theme colors
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _lightSurface = Color(0xFFFDFDFD);
  static const Color _lightBackground = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF475569);

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: "Selamat Datang di Timely",
      subtitle:
          "Revolusi absensi profesional yang cepat, mudah, dan terpercaya untuk era digital modern",
      iconData: Icons.access_time_rounded,
      backgroundColor: _lightBackground,
      primaryColor: _primaryBlue,
      illustrations: [
        IllustrationElement(
          icon: Icons.schedule_rounded,
          color: _primaryBlue,
          size: 48,
          position: Offset(0.15, 0.25),
          opacity: 0.1,
        ),
        IllustrationElement(
          icon: Icons.business_rounded,
          color: _primaryBlue,
          size: 36,
          position: Offset(0.8, 0.3),
          opacity: 0.08,
        ),
        IllustrationElement(
          icon: Icons.people_rounded,
          color: _primaryBlue,
          size: 42,
          position: Offset(0.2, 0.7),
          opacity: 0.06,
        ),
        IllustrationElement(
          icon: Icons.timer_rounded,
          color: _primaryBlue,
          size: 32,
          position: Offset(0.85, 0.75),
          opacity: 0.09,
        ),
      ],
      features: ['Efisiensi Tinggi', 'Keamanan Terjamin'],
    ),
    OnboardingPageData(
      title: "Notifikasi Pintar",
      subtitle:
          "Sistem pengingat cerdas dengan AI yang memastikan Anda tidak pernah terlambat absen lagi",
      iconData: Icons.notifications_active_rounded,
      backgroundColor: _lightBackground,
      primaryColor: _accentGreen,
      illustrations: [
        IllustrationElement(
          icon: Icons.smart_toy_rounded,
          color: _accentGreen,
          size: 46,
          position: Offset(0.12, 0.22),
          opacity: 0.1,
        ),
        IllustrationElement(
          icon: Icons.alarm_rounded,
          color: _accentGreen,
          size: 38,
          position: Offset(0.82, 0.28),
          opacity: 0.08,
        ),
        IllustrationElement(
          icon: Icons.psychology_rounded,
          color: _accentGreen,
          size: 34,
          position: Offset(0.18, 0.72),
          opacity: 0.07,
        ),
        IllustrationElement(
          icon: Icons.lightbulb_rounded,
          color: _accentGreen,
          size: 40,
          position: Offset(0.88, 0.78),
          opacity: 0.09,
        ),
      ],
      features: ['AI-Powered', 'Real-time'],
    ),
    OnboardingPageData(
      title: "Personalisasi Lengkap",
      subtitle:
          "Nikmati pengalaman yang dipersonalisasi dengan dukungan multi-bahasa dan tema yang dapat disesuaikan",
      iconData: Icons.tune_rounded,
      backgroundColor: _lightBackground,
      primaryColor: _accentOrange,
      illustrations: [
        IllustrationElement(
          icon: Icons.language_rounded,
          color: _accentOrange,
          size: 44,
          position: Offset(0.14, 0.26),
          opacity: 0.1,
        ),
        IllustrationElement(
          icon: Icons.palette_rounded,
          color: _accentOrange,
          size: 40,
          position: Offset(0.84, 0.32),
          opacity: 0.08,
        ),
        IllustrationElement(
          icon: Icons.settings_rounded,
          color: _accentOrange,
          size: 36,
          position: Offset(0.16, 0.74),
          opacity: 0.07,
        ),
        IllustrationElement(
          icon: Icons.auto_awesome_rounded,
          color: _accentOrange,
          size: 38,
          position: Offset(0.86, 0.76),
          opacity: 0.09,
        ),
      ],
      features: ['Multi-bahasa', 'Tema Dinamis'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _parallaxController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _parallaxController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_isTransitioning) return;

    if (_currentPage < _pages.length - 1) {
      setState(() => _isTransitioning = true);
      HapticFeedback.lightImpact();

      await _pageController.nextPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubicEmphasized,
      );

      setState(() => _isTransitioning = false);
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() async {
    if (_isTransitioning || _currentPage == 0) return;

    setState(() => _isTransitioning = true);
    HapticFeedback.lightImpact();

    await _pageController.previousPage(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubicEmphasized,
    );

    setState(() => _isTransitioning = false);
  }

  void _finishOnboarding() async {
    HapticFeedback.mediumImpact();
    await _fadeController.reverse();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => const LoginPage(),
          transitionDuration: const Duration(milliseconds: 900),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ),
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutQuart,
                      ),
                    ),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBackground,
      body: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeController,
            child: Stack(
              children: [
                // Parallax Background
                _buildParallaxBackground(),

                // Main Content
                SafeArea(
                  child: Column(
                    children: [
                      // Skip Button
                      _buildSkipButton(),

                      // Page Content
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _pages.length,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                            HapticFeedback.selectionClick();
                          },
                          itemBuilder: (context, index) {
                            return _buildPageContent(index);
                          },
                        ),
                      ),

                      // Bottom Navigation
                      _buildBottomNavigation(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkipButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Align(
        alignment: Alignment.topRight,
        child: TextButton(
          onPressed: _finishOnboarding,
          style: TextButton.styleFrom(
            foregroundColor: _textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            "Lewati",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParallaxBackground() {
    final currentPage = _pages[_currentPage];

    return AnimatedBuilder(
      animation: _parallaxController,
      builder: (context, child) {
        return Container(
          color: currentPage.backgroundColor,
          child: Stack(
            children: currentPage.illustrations.map((illustration) {
              return _buildParallaxElement(illustration);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildParallaxElement(IllustrationElement element) {
    return AnimatedBuilder(
      animation: _parallaxController,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        final parallaxValue = _parallaxController.value;

        // Subtle parallax movement
        final x =
            element.position.dx * screenSize.width +
            (parallaxValue * 20) * (element.position.dx - 0.5);
        final y =
            element.position.dy * screenSize.height +
            (parallaxValue * 15) * (element.position.dy - 0.5);

        return Positioned(
          left: x,
          top: y,
          child: Transform.rotate(
            angle: parallaxValue * 0.5,
            child: Icon(
              element.icon,
              size: element.size,
              color: element.color.withOpacity(element.opacity),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageContent(int index) {
    final pageData = _pages[index];

    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: Curves.easeOutQuart,
                ),
              ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Main Icon with Clean Design
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 1200),
              tween: Tween<double>(begin: 0.8, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _lightSurface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: pageData.primaryColor.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      pageData.iconData,
                      size: 48,
                      color: pageData.primaryColor,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 48),

            // Title
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                pageData.title,
                key: ValueKey('title_$index'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Subtitle
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                pageData.subtitle,
                key: ValueKey('subtitle_$index'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _textSecondary,
                  letterSpacing: 0.1,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Feature Highlights
            _buildFeatureHighlights(pageData),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights(OnboardingPageData pageData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: pageData.features.map((feature) {
        final featureIndex = pageData.features.indexOf(feature);
        return TweenAnimationBuilder(
          duration: Duration(milliseconds: 600 + (featureIndex * 100)),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _lightSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: pageData.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: pageData.primaryColor.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  feature,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: pageData.primaryColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubicEmphasized,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? _pages[_currentPage].primaryColor
                      : _pages[_currentPage].primaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 32),

          // Navigation Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Button
              if (_currentPage > 0)
                OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSecondary,
                    side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "Kembali",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(width: 100),

              // Next/Start Button
              ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pages[_currentPage].primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: _pages[_currentPage].primaryColor.withOpacity(
                    0.3,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentPage == _pages.length - 1
                          ? "Mulai Sekarang"
                          : "Lanjutkan",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Data Classes
class OnboardingPageData {
  final String title;
  final String subtitle;
  final IconData iconData;
  final Color backgroundColor;
  final Color primaryColor;
  final List<IllustrationElement> illustrations;
  final List<String> features;

  OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.backgroundColor,
    required this.primaryColor,
    required this.illustrations,
    required this.features,
  });
}

class IllustrationElement {
  final IconData icon;
  final Color color;
  final double size;
  final Offset position;
  final double opacity;

  IllustrationElement({
    required this.icon,
    required this.color,
    required this.size,
    required this.position,
    required this.opacity,
  });
}
