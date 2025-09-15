import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/utils/date_formatter.dart';

class HomePage extends StatefulWidget {
  final void Function(String) showSnackBar;

  const HomePage({super.key, void Function(String)? showSnackBar})
    : showSnackBar = showSnackBar ?? _defaultSnackBar;

  static void _defaultSnackBar(String msg) {}

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late Timer _timer;
  late DateTime _now;

  bool _hasCheckedIn = false;
  bool _hasCheckedOut = false;
  DateTime? _lastCheckDate;

  // Animation Controllers
  late final AnimationController _checkInController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  late final AnimationController _checkOutController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  late final AnimationController _shimmerController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final AnimationController _slideController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  // Animations
  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _fadeController,
    curve: Curves.easeOutQuart,
  );

  late final Animation<Offset> _slideAnimation =
      Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
      );

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _loadStatus();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
        _resetDailyStatus();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _checkInController.dispose();
    _checkOutController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString('lastCheckDate');
    if (lastCheck != null) {
      _lastCheckDate = DateTime.parse(lastCheck);
      _hasCheckedIn = prefs.getBool('hasCheckedIn') ?? false;
      _hasCheckedOut = prefs.getBool('hasCheckedOut') ?? false;
    }
    if (_hasCheckedIn) _checkInController.value = 1.0;
    if (_hasCheckedOut) _checkOutController.value = 1.0;
    setState(() {});
  }

  Future<void> _saveStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastCheckDate != null) {
      await prefs.setString('lastCheckDate', _lastCheckDate!.toIso8601String());
    }
    await prefs.setBool('hasCheckedIn', _hasCheckedIn);
    await prefs.setBool('hasCheckedOut', _hasCheckedOut);
  }

  void _resetDailyStatus() {
    final today = DateTime(_now.year, _now.month, _now.day);
    if (_lastCheckDate == null || _lastCheckDate!.isBefore(today)) {
      _hasCheckedIn = false;
      _hasCheckedOut = false;
      _lastCheckDate = today;
      _checkInController.value = 0.0;
      _checkOutController.value = 0.0;
      _saveStatus();
    }
  }

  void _onCheckIn() {
    setState(() {
      _hasCheckedIn = true;
      _lastCheckDate = DateTime(_now.year, _now.month, _now.day);
    });
    _checkInController.forward();
    _saveStatus();
    widget.showSnackBar("Check-in berhasil ✅");
  }

  void _onCheckOut() {
    setState(() {
      _hasCheckedOut = true;
      _lastCheckDate = DateTime(_now.year, _now.month, _now.day);
    });
    _checkOutController.forward();
    _saveStatus();
    widget.showSnackBar("Check-out berhasil ✅");
  }

  Widget _buildTimeCard() {
    final currentTime = DateFormatter.formatTime(_now);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      const Color(0xFF1E293B).withOpacity(0.8),
                      const Color(0xFF334155).withOpacity(0.6),
                    ]
                  : [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.5),
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.5),
                        ],
                        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                        transform: GradientRotation(
                          _shimmerController.value * 2 * pi,
                        ),
                      ).createShader(bounds);
                    },
                    child: Text(
                      currentTime,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: -2,
                        height: 1.1,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                width: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicators() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            title: "Check-in",
            icon: Icons.login_rounded,
            isCompleted: _hasCheckedIn,
            animation: _checkInController,
            primaryColor: const Color(0xFF10B981), // Emerald
            secondaryColor: const Color(0xFF34D399),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatusCard(
            title: "Check-out",
            icon: Icons.logout_rounded,
            isCompleted: _hasCheckedOut,
            animation: _checkOutController,
            primaryColor: const Color(0xFFF59E0B), // Amber
            secondaryColor: const Color(0xFFFBBF24),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required IconData icon,
    required bool isCompleted,
    required AnimationController animation,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isCompleted
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [
                            const Color(0xFF374151).withOpacity(0.7),
                            const Color(0xFF4B5563).withOpacity(0.5),
                          ]
                        : [Colors.grey.shade100, Colors.grey.shade50],
                  ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (isCompleted) ...[
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ] else ...[
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ],
          ),
          child: Column(
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.2).animate(
                  CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.white.withOpacity(0.2)
                        : (isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade200),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle_rounded : icon,
                    size: 32,
                    color: isCompleted
                        ? Colors.white
                        : (isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? Colors.white
                      : (isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback? onPressed,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 64,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, secondaryColor],
              )
            : LinearGradient(
                colors: isDarkMode
                    ? [Colors.grey.shade700, Colors.grey.shade800]
                    : [Colors.grey.shade300, Colors.grey.shade400],
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (isEnabled) ...[
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isEnabled ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isEnabled ? Colors.white : Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormatter.formatFullDate(_now);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Header
                  Text(
                    "Selamat datang",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    today,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: isDarkMode ? Colors.white : Colors.grey.shade900,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Time Card
                  _buildTimeCard(),

                  const SizedBox(height: 40),

                  // Status Indicators
                  _buildStatusIndicators(),

                  const SizedBox(height: 40),

                  // Action Buttons
                  _buildActionButton(
                    label: "Absen Masuk",
                    icon: Icons.login_rounded,
                    isEnabled: !_hasCheckedIn,
                    onPressed: _hasCheckedIn ? null : _onCheckIn,
                    primaryColor: const Color(0xFF3B82F6), // Blue
                    secondaryColor: const Color(0xFF1D4ED8),
                  ),

                  const SizedBox(height: 16),

                  _buildActionButton(
                    label: "Absen Pulang",
                    icon: Icons.logout_rounded,
                    isEnabled: !_hasCheckedOut && _hasCheckedIn,
                    onPressed: (_hasCheckedOut || !_hasCheckedIn)
                        ? null
                        : _onCheckOut,
                    primaryColor: const Color(0xFFEF4444),
                    secondaryColor: const Color(0xFFDC2626),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
