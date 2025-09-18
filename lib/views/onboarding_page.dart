import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/views/auth/login_page.dart';

class LiquidOnboarding extends StatefulWidget {
  const LiquidOnboarding({super.key});

  @override
  State<LiquidOnboarding> createState() => _LiquidOnboardingState();
}

class _LiquidOnboardingState extends State<LiquidOnboarding>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _liquidController;
  late AnimationController _parallaxController;
  late AnimationController _fadeController;

  int _currentPage = 0;
  bool _isAnimating = false;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Selamat Datang di Timely",
      subtitle:
          "Revolusi absensi profesional yang cepat, mudah, dan terpercaya untuk era digital",
      icon: Icons.access_time_rounded,
      gradient: const [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF2563EB)],
      accentColor: Color(0xFF10B981),
      backgroundElements: [
        FloatingElement(
          icon: Icons.schedule,
          size: 60,
          opacity: 0.1,
          initialX: 0.8,
          initialY: 0.2,
          rotationSpeed: 0.5,
        ),
        FloatingElement(
          icon: Icons.business,
          size: 40,
          opacity: 0.08,
          initialX: 0.15,
          initialY: 0.7,
          rotationSpeed: -0.3,
        ),
        FloatingElement(
          icon: Icons.person_pin_circle,
          size: 35,
          opacity: 0.12,
          initialX: 0.9,
          initialY: 0.8,
          rotationSpeed: 0.4,
        ),
      ],
    ),
    OnboardingData(
      title: "Notifikasi Pintar",
      subtitle:
          "Sistem pengingat cerdas dengan AI yang memastikan Anda tidak pernah terlambat absen",
      icon: Icons.notifications_active_rounded,
      gradient: const [Color(0xFF11998E), Color(0xFF38EF7D), Color(0xFF10B981)],
      accentColor: Color(0xFFF59E0B),
      backgroundElements: [
        FloatingElement(
          icon: Icons.alarm,
          size: 55,
          opacity: 0.1,
          initialX: 0.1,
          initialY: 0.15,
          rotationSpeed: 0.6,
        ),
        FloatingElement(
          icon: Icons.smart_toy,
          size: 45,
          opacity: 0.09,
          initialX: 0.85,
          initialY: 0.3,
          rotationSpeed: -0.4,
        ),
        FloatingElement(
          icon: Icons.psychology,
          size: 38,
          opacity: 0.11,
          initialX: 0.2,
          initialY: 0.75,
          rotationSpeed: 0.35,
        ),
      ],
    ),
    OnboardingData(
      title: "Multi Bahasa & Personalisasi",
      subtitle:
          "Nikmati pengalaman yang dipersonalisasi dengan dukungan multi-bahasa dan tema dinamis",
      icon: Icons.language_rounded,
      gradient: const [
        Color(0xFFFF6B6B),
        Color(0xFF4ECDC4),
        Color(0xFF45B7D1),
        Color(0xFF8B5CF6),
      ],
      accentColor: Color(0xFFEF4444),
      backgroundElements: [
        FloatingElement(
          icon: Icons.translate,
          size: 50,
          opacity: 0.1,
          initialX: 0.8,
          initialY: 0.25,
          rotationSpeed: 0.45,
        ),
        FloatingElement(
          icon: Icons.palette,
          size: 42,
          opacity: 0.08,
          initialX: 0.15,
          initialY: 0.6,
          rotationSpeed: -0.5,
        ),
        FloatingElement(
          icon: Icons.favorite,
          size: 36,
          opacity: 0.12,
          initialX: 0.9,
          initialY: 0.7,
          rotationSpeed: 0.3,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _liquidController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _parallaxController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _liquidController.dispose();
    _parallaxController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_isAnimating) return;

    if (_currentPage < _pages.length - 1) {
      setState(() => _isAnimating = true);

      HapticFeedback.lightImpact();
      await _liquidController.forward();

      await _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubicEmphasized,
      );

      _liquidController.reset();
      setState(() => _isAnimating = false);
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    HapticFeedback.mediumImpact();
    await _fadeController.reverse();

    // ✅ simpan state onboarding selesai
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          // 🔹 langsung ke LoginPage, bukan MainWrapper
          pageBuilder: (context, animation, _) => const LoginPage(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
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
      body: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeController.value,
            child: Stack(
              children: [
                // Animated Background
                _buildAnimatedBackground(),

                // Main Content
                SafeArea(
                  child: Column(
                    children: [
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

                // Liquid Swipe Effect Overlay
                if (_isAnimating) _buildLiquidOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    final currentPageData = _pages[_currentPage];

    return AnimatedBuilder(
      animation: _parallaxController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: currentPageData.gradient,
              stops: _generateStops(currentPageData.gradient.length),
              transform: GradientRotation(
                (_parallaxController.value * 2 * 3.14159) * 0.1,
              ),
            ),
          ),
          child: Stack(
            children: currentPageData.backgroundElements.map((element) {
              return _buildFloatingElement(element);
            }).toList(),
          ),
        );
      },
    );
  }

  List<double> _generateStops(int length) {
    return List.generate(length, (index) => index / (length - 1));
  }

  Widget _buildFloatingElement(FloatingElement element) {
    return AnimatedBuilder(
      animation: _parallaxController,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        final animationValue = _parallaxController.value;

        final x =
            (element.initialX + (animationValue * 0.1) % 1.0) *
            screenSize.width;
        final y =
            (element.initialY + (animationValue * 0.05) % 1.0) *
            screenSize.height;
        final rotation = animationValue * element.rotationSpeed * 2 * 3.14159;

        return Positioned(
          left: x,
          top: y,
          child: Transform.rotate(
            angle: rotation,
            child: Icon(
              element.icon,
              size: element.size,
              color: Colors.white.withOpacity(element.opacity),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageContent(int index) {
    final pageData = _pages[index];

    return AnimatedBuilder(
      animation: _pageController.hasClients
          ? _pageController
          : AnimationController(vsync: this),
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.4)).clamp(0.0, 1.0);
        }

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 100),
            child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main Icon with Pulse Animation
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: pageData.accentColor.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(pageData.icon, size: 60, color: Colors.white),
                  ),
                );
              },
            ),

            const SizedBox(height: 60),

            // Title with Typewriter Effect
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -1,
                height: 1.2,
              ),
              child: Text(pageData.title, textAlign: TextAlign.center),
            ),

            const SizedBox(height: 24),

            // Subtitle with Fade In
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.5,
                height: 1.5,
              ),
              child: Text(pageData.subtitle, textAlign: TextAlign.center),
            ),

            const SizedBox(height: 40),

            // Feature Highlights
            _buildFeatureHighlights(index),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights(int index) {
    final features = [
      ['⚡', 'Cepat & Efisien', '🔒', 'Aman & Terpercaya'],
      ['🧠', 'AI-Powered', '📱', 'Cross-Platform'],
      ['🌍', 'Multi-Language', '🎨', 'Customizable'],
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(2, (i) {
        return Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  features[index][i * 2],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              features[index][i * 2 + 1],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Progress Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubicEmphasized,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 32 : 12,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: _currentPage == index
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Skip Button
              TextButton(
                onPressed: _finishOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Lewati",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),

              // Next/Get Started Button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.white.withOpacity(0.9)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: _pages[_currentPage].gradient.first,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentPage == _pages.length - 1
                            ? Icons.rocket_launch
                            : Icons.arrow_forward,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidOverlay() {
    return AnimatedBuilder(
      animation: _liquidController,
      builder: (context, child) {
        return CustomPaint(
          painter: LiquidPainter(
            _liquidController.value,
            _pages[_currentPage].gradient,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

// Data Classes
class OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final Color accentColor;
  final List<FloatingElement> backgroundElements;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.backgroundElements,
  });
}

class FloatingElement {
  final IconData icon;
  final double size;
  final double opacity;
  final double initialX;
  final double initialY;
  final double rotationSpeed;

  FloatingElement({
    required this.icon,
    required this.size,
    required this.opacity,
    required this.initialX,
    required this.initialY,
    required this.rotationSpeed,
  });
}

// Custom Painter for Liquid Effect
class LiquidPainter extends CustomPainter {
  final double animationValue;
  final List<Color> colors;

  LiquidPainter(this.animationValue, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();

    // Create liquid wave effect
    final waveHeight = size.height * animationValue;
    final controlPoint1 = Offset(size.width * 0.3, waveHeight * 0.8);
    final controlPoint2 = Offset(size.width * 0.7, waveHeight * 1.2);

    path.moveTo(0, size.height);
    path.lineTo(0, waveHeight);
    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      size.width,
      waveHeight,
    );
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
