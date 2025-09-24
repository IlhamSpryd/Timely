import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/api/attendance_api.dart';
import 'package:timely/api/endpoint.dart';
import 'package:timely/models/absen_stats.dart';
import 'package:timely/models/absen_today.dart';
import 'package:timely/models/getprofile_model.dart';
import 'package:timely/services/auth_services.dart';

class ModernHomePage extends StatefulWidget {
  final void Function(String) showSnackBar;

  const ModernHomePage({super.key, required this.showSnackBar});

  @override
  State<ModernHomePage> createState() => _ModernHomePageState();
}

class _ModernHomePageState extends State<ModernHomePage>
    with TickerProviderStateMixin {
  // --- STATE VARIABLES AND DATA ---

  // Time and Greeting
  late Timer _timer;
  late DateTime _now;
  String _userName = "User";

  // Attendance Status
  bool _hasCheckedIn = false;
  bool _hasCheckedOut = false;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  String _todayStatus = "not yet absent";
  bool _isLoadingData = false;

  // Location and Maps
  GoogleMapController? mapController;
  LatLng _currentPosition = const LatLng(-6.200000, 106.816666);
  String _currentAddress = "Get location...";
  Marker? _marker;
  bool _isLoadingLocation = false;
  final LatLng _officeLocation = const LatLng(
    -6.210869244172426,
    106.81297234969804,
  );
  final double _officeRadius = 50.0;

  // Animation Controllers
  late final AnimationController _parallaxController;
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _pulseController;
  late final AnimationController _cardController;
  late final AnimationController _swipeController;

  // Swipe Gesture
  double _swipeProgress = 0.0;
  bool _isSwipeActive = false;
  String _currentSwipeAction = '';

  // Daily Quotes
  final List<String> _dailyQuotes = const [
    "Keberhasilan adalah hasil dari kesempurnaan, kerja keras, belajar dari kegagalan, loyalitas, dan ketekunan.",
    "Hari ini adalah kesempatan untuk menjadi lebih baik dari kemarin.",
    "Kerja keras mengalahkan bakat ketika bakat tidak bekerja keras.",
    "Kesuksesan bukan tentang seberapa besar pencapaianmu, tapi seberapa besar hambatan yang berhasil kamu lewati.",
    "Mulailah dari mana kamu berada. Gunakan apa yang kamu punya. Lakukan apa yang kamu bisa.",
  ];

  // Reminder
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _reminderEnabled = true;

  // Stats
  AbsenStatsModel? _absenStats;
  bool _isLoadingStats = false;

  // Services
  final AuthService _authService = AuthService();
  final AbsenService _absenService = AbsenService();

  // Parallax background elements (UPDATED)
  final List<ParallaxElement> _parallaxElements = const [
    ParallaxElement(
      icon: Icons.calendar_today_rounded,
      color: Color(0xFF3B82F6),
      size: 40,
      position: Offset(0.1, 0.2),
      speed: 0.3,
      opacity: 0.08,
    ),
    ParallaxElement(
      icon: Icons.people_rounded,
      color: Color(0xFF1785AF),
      size: 32,
      position: Offset(0.85, 0.15),
      speed: 0.5,
      opacity: 0.06,
    ),
    ParallaxElement(
      icon: Icons.location_on_rounded,
      color: Color(0xFF60A5FA),
      size: 36,
      position: Offset(0.15, 0.8),
      speed: 0.4,
      opacity: 0.07,
    ),
    ParallaxElement(
      icon: Icons.notifications_rounded,
      color: Color(0xFF7DD3FC),
      size: 28,
      position: Offset(0.9, 0.85),
      speed: 0.6,
      opacity: 0.09,
    ),
    ParallaxElement(
      icon: Icons.access_time_rounded,
      color: Color(0xFF1785AF),
      size: 34,
      position: Offset(0.05, 0.5),
      speed: 0.2,
      opacity: 0.05,
    ),
  ];

  // --- GETTERS AND HELPER METHODS ---

  // Get personalized greeting based on time of day
  String _getPersonalizedGreeting() {
    final hour = _now.hour;
    final firstName = _userName.split(' ')[0];

    if (hour >= 5 && hour < 11) {
      return "Selamat Pagi, $firstName";
    } else if (hour >= 11 && hour < 15) {
      return "Selamat Siang, $firstName";
    } else if (hour >= 15 && hour < 19) {
      return "Selamat Sore, $firstName";
    } else if (hour >= 19 && hour < 24) {
      return "Selamat Malam, $firstName";
    } else {
      return "Selamat Beristirahat, $firstName";
    }
  }

  // Get emoji based on time
  String _getGreetingEmoji() {
    final hour = _now.hour;
    if (hour >= 5 && hour < 11) return "🌅";
    if (hour >= 11 && hour < 15) return "☀️";
    if (hour >= 15 && hour < 19) return "🌇";
    return "🌙";
  }

  // Get contextual time description
  String _getTimeDescription() {
    final hour = _now.hour;
    if (hour >= 5 && hour < 10) return "A bright day to start activities!";
    if (hour >= 10 && hour < 14) return "Productive time!";
    if (hour >= 14 && hour < 17)
      return "Keep up the good work in the afternoon!";
    if (hour >= 17 && hour < 21) return "Have a good rest after work!";
    return "Don't forget to get enough rest!";
  }

  // Check if user is in the office area
  bool get _isInOfficeArea {
    final distance = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _officeLocation.latitude,
      _officeLocation.longitude,
    );
    return distance <= _officeRadius;
  }

  // Helper method to get text colors based on theme (UPDATED)
  Color _getTextPrimary(bool isDarkMode) =>
      isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  Color _getTextSecondary(bool isDarkMode) =>
      isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  Color _getSurfaceColor(bool isDarkMode) =>
      isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFDFDFD);
  Color _getBackgroundColor(bool isDarkMode) =>
      isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  String _getInitials(String name) {
    final names = name.split(' ');
    if (names.length > 1) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return "U";
  }

  // --- LIFECYCLE METHODS ---

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();

    // Initialize animation controllers
    _parallaxController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Load initial data
    _loadUserData();
    _loadAbsenData();
    _loadAbsenStats();
    _loadReminderSettings();

    // Start a timer to update the time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          _checkReminder();
        });
      }
    });

    // Get current location after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _parallaxController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _cardController.dispose();
    _swipeController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  // --- CORE FUNCTIONALITY METHODS ---

  // User data and attendance
  Future<void> _loadUserData() async {
    try {
      final token = await _authService.getToken();
      final name = await _authService.getCurrentUserName();

      if (name != null) {
        setState(() {
          _userName = name;
        });
      }

      if (token != null) {
        final response = await http.get(
          Uri.parse(Endpoint.profile),
          headers: {"Authorization": "Bearer $token"},
        );
        if (response.statusCode == 200) {
          final profileData = getProfileModelFromJson(response.body);
          if (profileData.data != null && mounted) {
            setState(() {
              _userName = profileData.data!.name ?? _userName;
              _getInitials(_userName);
            });
          }
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _loadAbsenData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(Endpoint.absenToday),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final todayAbsen = absenTodayModelFromJson(response.body);
        if (todayAbsen.data != null && mounted) {
          setState(() {
            _hasCheckedIn = todayAbsen.data!.checkInTime != null;
            _hasCheckedOut = todayAbsen.data!.checkOutTime != null;
            _todayStatus = todayAbsen.data!.status ?? "Belum Absen";
            if (todayAbsen.data!.checkInTime != null) {
              _checkInTime = _parseTimeString(todayAbsen.data!.checkInTime!);
            }
            if (todayAbsen.data!.checkOutTime != null) {
              _checkOutTime = _parseTimeString(todayAbsen.data!.checkOutTime!);
            }
          });
        }
      }
    } catch (e) {
      print("Error loading absen data: $e");
      widget.showSnackBar("Gagal memuat data absen");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  // Check-in and Check-out
  Future<void> _onCheckIn() async {
    if (!_isInOfficeArea) {
      widget.showSnackBar("Anda tidak berada di area PPKD");
      return;
    }
    setState(() => _isLoadingData = true);
    try {
      await _absenService.checkIn(
        _currentPosition.latitude,
        _currentPosition.longitude,
        _currentAddress,
        "Kantor",
      );
      if (mounted) {
        setState(() {
          _hasCheckedIn = true;
          _checkInTime = DateTime.now();
          _todayStatus = "Hadir";
        });
        HapticFeedback.mediumImpact();
        widget.showSnackBar("Absen masuk berhasil!");
        _showDailyQuote();
        _loadAbsenData();
      }
    } catch (e) {
      print("Error during check-in: $e");
      widget.showSnackBar("Gagal absen masuk");
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _onCheckOut() async {
    if (!_isInOfficeArea) {
      widget.showSnackBar("Anda tidak berada di area PPKD");
      return;
    }
    setState(() => _isLoadingData = true);
    try {
      await _absenService.checkOut(
        _currentPosition.latitude,
        _currentPosition.longitude,
        _currentAddress,
        "Kantor",
      );
      if (mounted) {
        setState(() {
          _hasCheckedOut = true;
          _checkOutTime = DateTime.now();
        });
        HapticFeedback.mediumImpact();
        widget.showSnackBar("Absen pulang berhasil!");
        _showDailyQuote();
        _loadAbsenData();
      }
    } catch (e) {
      print("Error during check-out: $e");
      widget.showSnackBar("Gagal absen pulang");
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // Reminder Management
  void _checkReminder() {
    if (_reminderEnabled &&
        _now.hour == _reminderTime.hour &&
        _now.minute == _reminderTime.minute &&
        _now.second == 0) {
      _showReminderAlert();
    }
  }

  void _showReminderAlert() {
    if (!_hasCheckedIn) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Pengingat Absen"),
          content: const Text("Jangan lupa untuk absen masuk!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reminderEnabled = prefs.getBool('reminder_enabled') ?? true;
      final hour = prefs.getInt('reminder_hour') ?? 8;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', _reminderEnabled);
    await prefs.setInt('reminder_hour', _reminderTime.hour);
    await prefs.setInt('reminder_minute', _reminderTime.minute);
  }

  void _showReminderSettings() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: _getSurfaceColor(isDarkMode),
          title: const Text("Pengaturan Pengingat"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _reminderEnabled,
                    onChanged: (value) =>
                        setState(() => _reminderEnabled = value ?? false),
                  ),
                  const Text("Aktifkan pengingat"),
                ],
              ),
              const SizedBox(height: 10),
              const Text("Waktu pengingat:"),
              ElevatedButton(
                onPressed: _reminderEnabled
                    ? () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: _reminderTime,
                        );
                        if (picked != null) {
                          setState(() => _reminderTime = picked);
                        }
                      }
                    : null,
                child: Text(
                  _reminderTime.format(context),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                _saveReminderSettings();
                Navigator.pop(context);
                widget.showSnackBar("Pengaturan disimpan");
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  // Location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        widget.showSnackBar("location.service_disabled".tr());
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          widget.showSnackBar("location.permission_denied".tr());
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = LatLng(position.latitude, position.longitude);

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
              title: "home.your_location".tr(),
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
        widget.showSnackBar("location.updated_successfully".tr());
      }
    } catch (e) {
      print("Error getting location: $e");
      if (mounted) {
        widget.showSnackBar("location.failed_to_get_location".tr());
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadAbsenStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final token = await _authService.getToken();
      if (token == null) return;
      final response = await http.get(
        Uri.parse(Endpoint.absenStats),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final stats = absenStatsModelFromJson(response.body);
        if (mounted) setState(() => _absenStats = stats);
      }
    } catch (e) {
      print("Error loading absen stats: $e");
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  DateTime _parseTimeString(String timeString) {
    try {
      final now = DateTime.now();
      final timeParts = timeString.split(':');
      if (timeParts.length >= 2) {
        return DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
      }
    } catch (e) {
      print("Error parsing time: $e");
    }
    return DateTime.now();
  }

  void _showDailyQuote() {
    final random = Random();
    final quote = _dailyQuotes[random.nextInt(_dailyQuotes.length)];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Pesan Hari Ini",
          style: TextStyle(color: Color(0xFF3B82F6)),
        ),
        content: Text(quote, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _onSwipeUpdate(DragUpdateDetails details, String action) {
    final containerWidth = MediaQuery.of(context).size.width - 48;
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

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _getBackgroundColor(isDarkMode),
      body: Stack(
        children: [
          _buildParallaxBackground(),
          FadeTransition(
            opacity: _fadeController,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(isDarkMode),
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.02),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _slideController,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildLocationCard(isDarkMode),
                        const SizedBox(height: 24),
                        _buildStatusCards(isDarkMode),
                        const SizedBox(height: 24),
                        _buildStatsCard(isDarkMode),
                        const SizedBox(height: 24),
                        _buildActionSection(isDarkMode),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParallaxBackground() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _parallaxController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ParallaxBackgroundPainter(
            elements: _parallaxElements,
            animationValue: _parallaxController.value,
            isDarkMode: isDarkMode,
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: isDarkMode
          ? const Color(0xFF0F172A)
          : const Color(0xFF3B82F6),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: _buildExpandedHeader(isDarkMode),
        titlePadding: EdgeInsets.zero,
        title: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double collapseProgress =
                ((constraints.maxHeight - kToolbarHeight) /
                        (250.0 - kToolbarHeight))
                    .clamp(0.0, 1.0);
            if (collapseProgress < 0.3) {
              return _buildCollapsedAppBar(isDarkMode);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.alarm_add_rounded, color: Colors.white),
          onPressed: _showReminderSettings,
        ),
      ],
    );
  }

  Widget _buildExpandedHeader(bool isDarkMode) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_getGreetingEmoji(), style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getPersonalizedGreeting(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, d MMMM y', 'id_ID').format(_now),
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _hasCheckedIn
                    ? (_hasCheckedOut ? "Selesai" : "Sedang Bekerja")
                    : "Belum Absen",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedAppBar(bool isDarkMode) {
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
            child: Text(
              _getInitials(_userName),
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Lokasi Saat Ini",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _getTextPrimary(isDarkMode),
                  ),
                ),
              ),
              if (_isLoadingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentAddress,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _getTextSecondary(isDarkMode),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            // Tampilan peta diperbesar
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                onMapCreated: (controller) => mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 15,
                ),
                markers: _marker != null ? {_marker!} : {},
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _isInOfficeArea ? Icons.check_circle : Icons.error,
                color: _isInOfficeArea
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _isInOfficeArea
                      ? "Anda berada di area PPKD"
                      : "Anda di luar area PPKD",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _isInOfficeArea
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              title: "Status",
              value: _todayStatus,
              icon: Icons.calendar_today_rounded,
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatusCard(
              title: "Absen Masuk",
              value: _hasCheckedIn
                  ? DateFormat('HH:mm').format(_checkInTime!)
                  : "--:--",
              icon: Icons.login_rounded,
              color: const Color(0xFF1785AF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatusCard(
              title: "Absen Pulang",
              value: _hasCheckedOut
                  ? DateFormat('HH:mm').format(_checkOutTime!)
                  : "--:--",
              icon: Icons.logout_rounded,
              color: const Color(0xFF7DD3FC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: _getTextSecondary(isDarkMode),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getTextPrimary(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(bool isDarkMode) {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: Color(0xFF60A5FA)),
              const SizedBox(width: 10),
              const Text(
                "Statistik Absen",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                "Total",
                _absenStats?.data?.totalAbsen?.toString() ?? "0",
                const Color(0xFF3B82F6),
              ),
              _buildStatItem(
                "Masuk",
                _absenStats?.data?.totalMasuk?.toString() ?? "0",
                const Color(0xFF1785AF),
              ),
              _buildStatItem(
                "Izin",
                _absenStats?.data?.totalIzin?.toString() ?? "0",
                const Color(0xFF7DD3FC),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildActionSection(bool isDarkMode) {
    if (_hasCheckedIn && _hasCheckedOut) {
      return _buildCompletionCard(isDarkMode);
    } else if (!_isInOfficeArea) {
      return _buildOutOfOfficeAlert(isDarkMode);
    } else if (!_hasCheckedIn) {
      return _buildCleanSwipeButton(
        label: "check_in",
        icon: Icons.login_rounded,
        action: "checkin",
        color: const Color(0xFF1785AF),
      );
    } else {
      return _buildCleanSwipeButton(
        label: "check_out",
        icon: Icons.logout_rounded,
        action: "checkout",
        color: const Color(0xFF7DD3FC),
      );
    }
  }

  // Tombol geser absen yang diperbarui
  Widget _buildCleanSwipeButton({
    required String label,
    required IconData icon,
    required String action,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final containerWidth = MediaQuery.of(context).size.width - 48;
    final swipeHandleSize = 60.0;
    final swipeText = action == 'checkin'
        ? "Geser untuk Absen Masuk"
        : "Geser untuk Absen Pulang";

    return GestureDetector(
      onHorizontalDragUpdate: (details) => _onSwipeUpdate(details, action),
      onHorizontalDragEnd: (_) => _onSwipeEnd(action),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        height: 80,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Latar belakang tombol yang berubah warna saat digeser
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: containerWidth * _swipeProgress,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            // Teks yang memudar
            AnimatedOpacity(
              opacity: 1.0 - _swipeProgress,
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: Text(
                  swipeText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getTextPrimary(isDarkMode),
                  ),
                ),
              ),
            ),
            // Handle atau bulatan geser
            Transform.translate(
              offset: Offset(
                (containerWidth - swipeHandleSize) * _swipeProgress,
                0,
              ),
              child: Container(
                width: swipeHandleSize,
                height: swipeHandleSize,
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(child: Icon(icon, color: Colors.white, size: 28)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionCard(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981),
            size: 48,
          ),
          const SizedBox(height: 10),
          Text(
            "Absensi Selesai",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getTextPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Terima kasih telah bekerja hari ini!",
            textAlign: TextAlign.center,
            style: TextStyle(color: _getTextSecondary(isDarkMode)),
          ),
        ],
      ),
    );
  }

  Widget _buildOutOfOfficeAlert(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_off_rounded,
            color: Color(0xFFF59E0B),
            size: 48,
          ),
          const SizedBox(height: 10),
          const Text(
            "Di Luar Area PPKD",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Anda harus berada di area PPKD untuk melakukan absen",
            textAlign: TextAlign.center,
            style: TextStyle(color: _getTextSecondary(isDarkMode)),
          ),
        ],
      ),
    );
  }

  // Dark mode map style
  static const String _darkMapStyle = '''
    [
      {"elementType": "geometry", "stylers": [{"color": "#1a1a2e"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a1a2e"}]},
      {"featureType": "administrative.country", "elementType": "labels.text.fill", "stylers": [{"color": "#9e9e9e"}]},
      {"featureType": "administrative.land_parcel", "stylers": [{"visibility": "off"}]},
      {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#bdbdbd"}]},
      {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#0f3460"}]},
      {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#16213e"}]},
      {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#0f3460"}]},
      {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#0f3460"}]},
      {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0f3460"}]},
      {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#3d3d3d"}]}
    ]
  ''';
}

// Parallax Element Data Class
class ParallaxElement {
  final IconData icon;
  final Color color;
  final double size;
  final Offset position;
  final double speed;
  final double opacity;

  const ParallaxElement({
    required this.icon,
    required this.color,
    required this.size,
    required this.position,
    required this.speed,
    required this.opacity,
  });
}

// Painter for parallax background
class _ParallaxBackgroundPainter extends CustomPainter {
  final List<ParallaxElement> elements;
  final double animationValue;
  final bool isDarkMode;

  _ParallaxBackgroundPainter({
    required this.elements,
    required this.animationValue,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final background = isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    canvas.drawColor(background, BlendMode.srcOver);

    for (final element in elements) {
      final offsetX =
          size.width * element.position.dx +
          animationValue * 100 * element.speed;
      final offsetY = size.height * element.position.dy;

      paint.color = element.color.withOpacity(element.opacity);
      canvas.drawCircle(Offset(offsetX, offsetY), element.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
