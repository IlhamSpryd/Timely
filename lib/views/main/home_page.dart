import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  // Maps
  GoogleMapController? mapController;
  LatLng _currentPosition = LatLng(-6.200000, 106.816666);
  double lat = -6.200000;
  double long = 106.816666;
  String _currentAddress = "Getting location...";
  Marker? _marker;
  bool _isLoadingLocation = false;

  // Enhanced Animation Controllers
  late final AnimationController _swipeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  late final AnimationController _slideController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  late final AnimationController _cardController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  late final AnimationController _breatheController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  )..repeat(reverse: true);

  late final AnimationController _headerAnimController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  // Swipe gesture tracking
  double _swipeProgress = 0.0;
  bool _isSwipeActive = false;
  String _currentSwipeAction = '';

  // Office location (configurable)
  final LatLng _officeLocation = LatLng(-6.200000, 106.816666);
  final double _officeRadius = 100.0; // meters
  final String _officeName = "Pusat Pelatihan Kerja Daerah Jakarta Pusat";
  final String _officeAddress =
      "Jl. Bendungan Hilir No. 1, RT.10/RW.2, Kb. Melati, Kec. Tanah Abang, Kota Jakarta Pusat";

  bool get _isInOfficeArea {
    final distance = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _officeLocation.latitude,
      _officeLocation.longitude,
    );
    return distance <= _officeRadius;
  }

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _loadStatus();
    _startAnimations();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          _resetDailyStatus();
        });
      }
    });

    // Auto get location on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  void _startAnimations() {
    // Staggered animation startup
    _fadeController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _cardController.forward();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _headerAnimController.forward();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _swipeController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _cardController.dispose();
    _breatheController.dispose();
    _headerAnimController.dispose();
    mapController?.dispose();
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
    if (mounted) setState(() {});
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
      "Check-in successful at ${DateFormatter.formatTime(_now)}".tr(),
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
      "Check-out successful at ${DateFormatter.formatTime(_now)}".tr(),
    );
  }

  void _onSwipeUpdate(DragUpdateDetails details, String action) {
    final containerWidth =
        MediaQuery.of(context).size.width - 48 - 64; // margin + button width
    setState(() {
      _swipeProgress = (details.localPosition.dx / containerWidth).clamp(
        0.0,
        1.0,
      );
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

  Widget _buildProfessionalHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([_breatheController, _headerAnimController]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      const Color(0xFF0B1426),
                      const Color(0xFF1E293B),
                      const Color(0xFF334155).withOpacity(0.8),
                    ]
                  : [
                      const Color(0xFF4F46E5),
                      const Color(0xFF7C3AED),
                      const Color(0xFF06B6D4),
                    ],
              stops: [0.0, 0.6 + (_breatheController.value * 0.2), 1.0],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, -0.5),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _headerAnimController,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                child: Column(
                  children: [
                    // Top Navigation Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Good ${_getGreeting()}".tr(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Ilham Sepriyadi",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ],
                        ),

                        // Notification & Profile Section
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 0.5,
                                ),
                              ),
                              child: Icon(
                                Icons.notifications_none,
                                color: Colors.white.withOpacity(0.9),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 0.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.white.withOpacity(0.9),
                                child: Text(
                                  "IS",
                                  style: TextStyle(
                                    color: const Color(0xFF4F46E5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Modern Time Display
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _headerAnimController,
                          curve: const Interval(
                            0.3,
                            1.0,
                            curve: Curves.elasticOut,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (_pulseController.value * 0.02),
                                  child: Text(
                                    DateFormatter.formatTime(_now),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.w200,
                                      letterSpacing: -2.5,
                                      height: 1.0,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              DateFormatter.formatFullDate(_now),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Work Status Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor().withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _getWorkStatus(),
                                style: TextStyle(
                                  color: _getStatusColor(),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor() {
    if (!_isInOfficeArea) return const Color(0xFFEF4444);
    if (_hasCheckedIn && !_hasCheckedOut) return const Color(0xFF10B981);
    if (_hasCheckedIn && _hasCheckedOut) return const Color(0xFF6366F1);
    return const Color(0xFFF59E0B);
  }

  String _getWorkStatus() {
    if (!_isInOfficeArea) return "Out of PPKD Area".tr();
    if (_hasCheckedIn && !_hasCheckedOut) return "Currently Working".tr();
    if (_hasCheckedIn && _hasCheckedOut) return "Work Complete".tr();
    return "Ready to Check In".tr();
  }

  Widget _buildLocationCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _cardController,
              curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
            ),
          ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _cardController,
          curve: const Interval(0.2, 1.0),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Map Section
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition,
                          zoom: 16,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        mapType: MapType.normal,
                        zoomControlsEnabled: false,
                        markers: _buildMapMarkers(),
                        circles: {
                          Circle(
                            circleId: const CircleId('office_area'),
                            center: _officeLocation,
                            radius: _officeRadius,
                            fillColor: const Color(0xFF4F46E5).withOpacity(0.1),
                            strokeColor: const Color(
                              0xFF4F46E5,
                            ).withOpacity(0.5),
                            strokeWidth: 2,
                          ),
                        },
                        onMapCreated: (controller) {
                          mapController = controller;
                          if (isDarkMode) {
                            controller.setMapStyle(_darkMapStyle);
                          }
                        },
                      ),

                      // Distance indicator overlay
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isInOfficeArea
                                    ? Icons.check_circle
                                    : Icons.location_on,
                                size: 16,
                                color: _isInOfficeArea
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${_getDistanceToOffice().toStringAsFixed(0)}m",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isInOfficeArea
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Location Details
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Current location info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.my_location,
                            color: const Color(0xFF4F46E5),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Your Location".tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _currentAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Office location info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.business,
                            color: const Color(0xFF10B981),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Office Location".tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _officeName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Update location button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoadingLocation
                            ? null
                            : _getCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoadingLocation
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Update Location".tr(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Set<Marker> _buildMapMarkers() {
    final markers = <Marker>{};

    // Current position marker
    if (_marker != null) {
      markers.add(_marker!);
    }

    // Office marker
    markers.add(
      Marker(
        markerId: const MarkerId('office'),
        position: _officeLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Office Location'.tr(),
          snippet: _officeName,
        ),
      ),
    );

    return markers;
  }

  double _getDistanceToOffice() {
    return Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _officeLocation.latitude,
      _officeLocation.longitude,
    );
  }

  Widget _buildStatusCards() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(-0.5, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _cardController,
                      curve: const Interval(
                        0.3,
                        1.0,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  ),
              child: _buildStatusCard(
                title: "Check In".tr(),
                time: _checkInTime,
                icon: Icons.login_rounded,
                color: const Color(0xFF10B981),
                isCompleted: _hasCheckedIn,
                isDarkMode: isDarkMode,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0.5, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _cardController,
                      curve: const Interval(
                        0.4,
                        1.0,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  ),
              child: _buildStatusCard(
                title: "Check Out".tr(),
                time: _checkOutTime,
                icon: Icons.logout_rounded,
                color: const Color(0xFFEF4444),
                isCompleted: _hasCheckedOut,
                isDarkMode: isDarkMode,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required DateTime? time,
    required IconData icon,
    required Color color,
    required bool isCompleted,
    required bool isDarkMode,
  }) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCompleted
            ? color.withOpacity(0.08)
            : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCompleted
              ? color.withOpacity(0.25)
              : (isDarkMode
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? color.withOpacity(0.12)
                : Colors.black.withOpacity(isDarkMode ? 0.25 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCompleted ? color : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : icon,
              color: isCompleted ? Colors.white : color,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isCompleted ? color : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            time != null ? DateFormatter.formatTime(time) : "--:--",
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalSwipeButton({
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
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      height: 72,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: isEnabled
              ? color.withOpacity(0.15)
              : (isDarkMode
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.withOpacity(0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Progress background with gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 72,
            width: isCurrentSwipe
                ? _swipeProgress * (MediaQuery.of(context).size.width - 48)
                : 0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.2),
                  color.withOpacity(0.15),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
              borderRadius: BorderRadius.circular(36),
            ),
          ),

          // Swipe button with enhanced design
          AnimatedPositioned(
            duration: Duration(milliseconds: isCurrentSwipe ? 0 : 500),
            curve: Curves.easeOutCubic,
            left: isCurrentSwipe
                ? _swipeProgress *
                          (MediaQuery.of(context).size.width - 48 - 68) +
                      4
                : 4,
            top: 4,
            child: GestureDetector(
              onPanUpdate: isEnabled && _isInOfficeArea
                  ? (details) => _onSwipeUpdate(details, action)
                  : null,
              onPanEnd: isEnabled && _isInOfficeArea
                  ? (_) => _onSwipeEnd(action)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: isEnabled && _isInOfficeArea
                      ? LinearGradient(
                          colors: [color, color.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            theme.colorScheme.onSurfaceVariant.withOpacity(0.2),
                            theme.colorScheme.onSurfaceVariant.withOpacity(0.1),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: isEnabled && _isInOfficeArea
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  icon,
                  color: isEnabled && _isInOfficeArea
                      ? Colors.white
                      : Colors.grey,
                  size: 28,
                ),
              ),
            ),
          ),

          // Label with better positioning
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: Text(
                  isCurrentSwipe && _swipeProgress > 0.7
                      ? "Release to $label".tr()
                      : "Swipe to $label".tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: isEnabled && _isInOfficeArea
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Enhanced animated indicators
          if (isEnabled && _isInOfficeArea) ...[
            Positioned(
              right: 90,
              top: 0,
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final delay = index * 0.15;
                      final progress = (_pulseController.value + delay) % 1.0;

                      return Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 3 + (progress * 3),
                        height: 3 + (progress * 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.4 + (progress * 0.4)),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutOfOfficeAlert() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444).withOpacity(0.08),
            const Color(0xFFDC2626).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.location_off_rounded,
              color: const Color(0xFFEF4444),
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Out of Office Area".tr(),
                  style: TextStyle(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "You need to be within ${_officeRadius.toInt()}m of the office to check in/out."
                      .tr(),
                  style: TextStyle(
                    color: const Color(0xFFEF4444).withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Distance: ${_getDistanceToOffice().toStringAsFixed(0)}m"
                      .tr(),
                  style: TextStyle(
                    color: const Color(0xFFEF4444),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkSummaryCard() {
    if (!_hasCheckedIn || _checkInTime == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _cardController,
              curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
            ),
          ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: const Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "Today's Work Session".tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildWorkTimeItem(
                    "Start Time".tr(),
                    DateFormatter.formatTime(_checkInTime!),
                    Icons.login_rounded,
                    const Color(0xFF10B981),
                  ),
                ),

                Container(
                  width: 1,
                  height: 50,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.15),
                ),

                Expanded(
                  child: _buildWorkTimeItem(
                    _hasCheckedOut ? "End Time".tr() : "Current".tr(),
                    _hasCheckedOut && _checkOutTime != null
                        ? DateFormatter.formatTime(_checkOutTime!)
                        : DateFormatter.formatTime(_now),
                    _hasCheckedOut
                        ? Icons.logout_rounded
                        : Icons.access_time_rounded,
                    _hasCheckedOut
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF4F46E5),
                  ),
                ),

                Container(
                  width: 1,
                  height: 50,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.15),
                ),

                Expanded(
                  child: _buildWorkTimeItem(
                    "Duration".tr(),
                    _calculateWorkDuration(),
                    Icons.timer_rounded,
                    const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkTimeItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompletionCard() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.08),
            const Color(0xFF059669).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Excellent Work Today!".tr(),
            style: TextStyle(
              color: const Color(0xFF10B981),
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "You've successfully completed your attendance for today.".tr(),
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_checkInTime != null && _checkOutTime != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Total: ${_calculateWorkDuration()}".tr(),
                style: TextStyle(
                  color: const Color(0xFF10B981),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = _now.hour;
    if (hour < 12) return "Morning";
    if (hour < 15) return "Afternoon";
    if (hour < 18) return "Evening";
    return "Night";
  }

  String _calculateWorkDuration() {
    if (_checkInTime == null) return "0h 0m";

    final endTime = _hasCheckedOut && _checkOutTime != null
        ? _checkOutTime!
        : _now;
    final duration = endTime.difference(_checkInTime!);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return "${hours}h ${minutes}m";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF0B1426)
          : const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeController,
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: Curves.easeOutCubic,
                ),
              ),
          child: Column(
            children: [
              // Professional Header
              _buildProfessionalHeader(),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // Location Card
                      _buildLocationCard(),

                      const SizedBox(height: 32),

                      // Status Cards
                      _buildStatusCards(),

                      const SizedBox(height: 40),

                      // Action Section
                      if (_hasCheckedIn && _hasCheckedOut) ...[
                        _buildCompletionCard(),
                      ] else if (!_isInOfficeArea) ...[
                        _buildOutOfOfficeAlert(),
                      ] else if (!_hasCheckedIn) ...[
                        _buildProfessionalSwipeButton(
                          label: "Check In",
                          icon: Icons.login_rounded,
                          isEnabled: !_hasCheckedIn,
                          action: "checkin",
                          color: const Color(0xFF10B981),
                        ),
                      ] else if (!_hasCheckedOut) ...[
                        _buildProfessionalSwipeButton(
                          label: "Check Out",
                          icon: Icons.logout_rounded,
                          isEnabled: !_hasCheckedOut,
                          action: "checkout",
                          color: const Color(0xFFEF4444),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Work Summary Card
                      _buildWorkSummaryCard(),

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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        setState(() {
          _isLoadingLocation = false;
        });
        widget.showSnackBar("Location service is disabled".tr());
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          setState(() {
            _isLoadingLocation = false;
          });
          widget.showSnackBar("Location permission denied".tr());
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = LatLng(position.latitude, position.longitude);
      lat = position.latitude;
      long = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition.latitude,
        _currentPosition.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];

        setState(() {
          _marker = Marker(
            markerId: const MarkerId("current_location"),
            position: _currentPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: 'Your Location'.tr(),
              snippet: "${place.street}, ${place.locality}",
            ),
          );

          _currentAddress = [
            place.name,
            place.street,
            place.locality,
            place.administrativeArea,
          ].where((e) => e != null && e.isNotEmpty).join(', ');

          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _currentPosition, zoom: 15),
            ),
          );
        });

        widget.showSnackBar("Location updated successfully".tr());
      }
    } catch (e) {
      print("Error getting location: $e");
      if (mounted) {
        widget.showSnackBar("Failed to get current location".tr());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  // Dark mode map style
  static const String _darkMapStyle = '''
    [
      {
        "elementType": "geometry",
        "stylers": [{"color": "#1a1a2e"}]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#8ec3b9"}]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [{"color": "#1a1a2e"}]
      },
      {
        "featureType": "administrative.country",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#9e9e9e"}]
      },
      {
        "featureType": "administrative.land_parcel",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#bdbdbd"}]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#757575"}]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [{"color": "#0f3460"}]
      },
      {
        "featureType": "road",
        "elementType": "geometry.fill",
        "stylers": [{"color": "#16213e"}]
      },
      {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [{"color": "#0f3460"}]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [{"color": "#0f3460"}]
      },
      {
        "featureType": "transit",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#757575"}]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [{"color": "#0f3460"}]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [{"color": "#3d3d3d"}]
      }
    ]
  ''';
}
