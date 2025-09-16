import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DateTime? _checkInTime;
  DateTime? _checkOutTime;

  // Animation Controllers for swipe gesture
  late final AnimationController _swipeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();

  late final AnimationController _slideController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  // Swipe gesture tracking
  double _swipeProgress = 0.0;
  bool _isSwipeActive = false;
  String _currentSwipeAction = '';

  // Mock location data
  final String _currentLocation = "Pusat Pelatihan Kerja Daerah Jakarta Pusat";
  final String _locationAddress =
      "Jl. Bendungan Hilir No. 1, RT.10/RW.2, Kb. Melati, Kec. Tanah Abang, Kota Jakarta Pusat, Daerah Khusus Ibukota Jakarta 10210";
  final bool _isInOfficeArea = true;

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
    _swipeController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString('lastCheckDate');
    if (lastCheck != null) {
      _lastCheckDate = DateTime.parse(lastCheck);
      _hasCheckedIn = prefs.getBool('hasCheckedIn') ?? false;
      _hasCheckedOut = prefs.getBool('hasCheckedOut') ?? false;

      final checkInString = prefs.getString('checkInTime');
      if (checkInString != null) {
        _checkInTime = DateTime.parse(checkInString);
      }

      final checkOutString = prefs.getString('checkOutTime');
      if (checkOutString != null) {
        _checkOutTime = DateTime.parse(checkOutString);
      }
    }
    setState(() {});
  }

  Future<void> _saveStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastCheckDate != null) {
      await prefs.setString('lastCheckDate', _lastCheckDate!.toIso8601String());
    }
    await prefs.setBool('hasCheckedIn', _hasCheckedIn);
    await prefs.setBool('hasCheckedOut', _hasCheckedOut);

    if (_checkInTime != null) {
      await prefs.setString('checkInTime', _checkInTime!.toIso8601String());
    }

    if (_checkOutTime != null) {
      await prefs.setString('checkOutTime', _checkOutTime!.toIso8601String());
    }
  }

  void _resetDailyStatus() {
    final today = DateTime(_now.year, _now.month, _now.day);
    if (_lastCheckDate == null || _lastCheckDate!.isBefore(today)) {
      _hasCheckedIn = false;
      _hasCheckedOut = false;
      _checkInTime = null;
      _checkOutTime = null;
      _lastCheckDate = today;
      _saveStatus();
    }
  }

  void _onCheckIn() {
    setState(() {
      _hasCheckedIn = true;
      _checkInTime = _now;
      _lastCheckDate = DateTime(_now.year, _now.month, _now.day);
    });
    _saveStatus();
    HapticFeedback.mediumImpact();
    widget.showSnackBar(
      "✅ Check-in berhasil pada ${DateFormatter.formatTime(_now)}",
    );
  }

  void _onCheckOut() {
    setState(() {
      _hasCheckedOut = true;
      _checkOutTime = _now;
      _lastCheckDate = DateTime(_now.year, _now.month, _now.day);
    });
    _saveStatus();
    HapticFeedback.mediumImpact();
    widget.showSnackBar(
      "✅ Check-out berhasil pada ${DateFormatter.formatTime(_now)}",
    );
  }

  void _onSwipeUpdate(DragUpdateDetails details, String action) {
    setState(() {
      _swipeProgress = (details.localPosition.dx / 280).clamp(0.0, 1.0);
      _isSwipeActive = true;
      _currentSwipeAction = action;
    });

    if (_swipeProgress > 0.8) {
      HapticFeedback.selectionClick();
    }
  }

  void _onSwipeEnd(String action) {
    if (_swipeProgress > 0.8) {
      _swipeController.forward().then((_) {
        if (action == 'checkin') {
          _onCheckIn();
        } else if (action == 'checkout') {
          _onCheckOut();
        }
        _swipeController.reset();
      });
    } else {
      _swipeController.reverse().then((_) {
        _swipeController.reset();
      });
    }

    setState(() {
      _swipeProgress = 0.0;
      _isSwipeActive = false;
      _currentSwipeAction = '';
    });
  }

  Widget _buildHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]
              : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      " Good ${_getGreeting()}".tr(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                      ),
                    ).tr(),
                    const SizedBox(height: 4),
                    Text(
                      "Ilham Sepriyadi",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Current Time
            Center(
              child: Text(
                DateFormatter.formatTime(_now),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                DateFormatter.formatFullDate(_now),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Mock Map Area
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isInOfficeArea
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Mock map pattern
                CustomPaint(
                  size: const Size(double.infinity, 160),
                  painter: MapPatternPainter(isDarkMode: isDarkMode),
                ),

                // Location indicator
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 40 + (_pulseController.value * 10),
                        height: 40 + (_pulseController.value * 10),
                        decoration: BoxDecoration(
                          color: _isInOfficeArea
                              ? const Color(0xFF10B981).withOpacity(0.3)
                              : const Color(0xFFEF4444).withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _isInOfficeArea
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Status badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isInOfficeArea
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isInOfficeArea ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isInOfficeArea ? "Di Area" : "Luar Area",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ).tr(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Location info
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentLocation,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _locationAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildStatusCards() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _hasCheckedIn
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : (isDarkMode
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hasCheckedIn
                      ? const Color(0xFF10B981).withOpacity(0.3)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _hasCheckedIn ? Icons.check_circle : Icons.login_rounded,
                    color: _hasCheckedIn
                        ? const Color(0xFF10B981)
                        : theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Check In",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _hasCheckedIn
                          ? const Color(0xFF10B981)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ).tr(),
                  const SizedBox(height: 4),
                  Text(
                    _checkInTime != null
                        ? DateFormatter.formatTime(_checkInTime!)
                        : "--:--",
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _hasCheckedOut
                    ? const Color(0xFFEF4444).withOpacity(0.1)
                    : (isDarkMode
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hasCheckedOut
                      ? const Color(0xFFEF4444).withOpacity(0.3)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _hasCheckedOut ? Icons.check_circle : Icons.logout_rounded,
                    color: _hasCheckedOut
                        ? const Color(0xFFEF4444)
                        : theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Check Out",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _hasCheckedOut
                          ? const Color(0xFFEF4444)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _checkOutTime != null
                        ? DateFormatter.formatTime(_checkOutTime!)
                        : "--:--",
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ).tr(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeButton({
    required String label,
    required IconData icon,
    required bool isEnabled,
    required String action,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isCurrentSwipe = _currentSwipeAction == action;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 70,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: isEnabled ? color.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Stack(
        children: [
          // Swipe progress background
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 70,
            width: isCurrentSwipe ? _swipeProgress * 300 : 0,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(35),
            ),
          ),

          // Swipe button
          AnimatedPositioned(
            duration: Duration(milliseconds: isCurrentSwipe ? 0 : 300),
            left: isCurrentSwipe ? _swipeProgress * 220 : 4,
            top: 4,
            child: GestureDetector(
              onPanUpdate: isEnabled
                  ? (details) => _onSwipeUpdate(details, action)
                  : null,
              onPanEnd: isEnabled ? (_) => _onSwipeEnd(action) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: isEnabled ? color : theme.colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(31),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
          ),

          // Label
          Center(
            child: Text(
              isCurrentSwipe && _swipeProgress > 0.7
                  ? "Lepas untuk $label"
                  : "Geser untuk $label",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isEnabled
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ).tr(),
          ),

          // Arrow indicators
          if (isEnabled) ...[
            Positioned(
              right: 80,
              top: 0,
              bottom: 0,
              child: Row(
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200 + (index * 100)),
                    margin: const EdgeInsets.only(right: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = _now.hour;
    if (hour < 12) return "Morning".tr();
    if (hour < 15) return "Afternoon".tr();
    if (hour < 18) return "Evening".tr();
    return "Night".tr();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeController,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: Curves.easeOutCubic,
                ),
              ),
          child: Column(
            children: [
              // Header with time
              _buildHeader(),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 5),

                      // Location and Map
                      _buildLocationCard(),

                      const SizedBox(height: 20),

                      // Status Cards
                      _buildStatusCards(),

                      const SizedBox(height: 40),

                      // Swipe Buttons
                      if (!_hasCheckedIn && _isInOfficeArea) ...[
                        _buildSwipeButton(
                          label: "Check In",
                          icon: Icons.login_rounded,
                          isEnabled: !_hasCheckedIn,
                          action: "checkin",
                          color: const Color(0xFF10B981),
                        ),
                      ],

                      if (_hasCheckedIn &&
                          !_hasCheckedOut &&
                          _isInOfficeArea) ...[
                        _buildSwipeButton(
                          label: "Check Out",
                          icon: Icons.logout_rounded,
                          isEnabled: !_hasCheckedOut,
                          action: "checkout",
                          color: const Color(0xFFEF4444),
                        ),
                      ],

                      if (!_isInOfficeArea) ...[
                        Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_off,
                                color: const Color(0xFFEF4444),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Anda berada di luar area kantor. Silakan mendekat ke lokasi yang telah ditentukan.",
                                  style: TextStyle(
                                    color: const Color(0xFFEF4444),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ).tr(),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for map pattern
class MapPatternPainter extends CustomPainter {
  final bool isDarkMode;

  MapPatternPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.1)
          : Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    // Draw grid pattern to simulate map
    for (int i = 0; i < 10; i++) {
      canvas.drawLine(
        Offset(i * (size.width / 10), 0),
        Offset(i * (size.width / 10), size.height),
        paint,
      );
    }

    for (int i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(0, i * (size.height / 6)),
        Offset(size.width, i * (size.height / 6)),
        paint,
      );
    }

    // Draw some roads
    paint.strokeWidth = 2;
    paint.color = isDarkMode
        ? Colors.white.withOpacity(0.2)
        : Colors.grey.withOpacity(0.4);

    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.8, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
