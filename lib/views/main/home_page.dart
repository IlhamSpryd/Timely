import 'dart:async';
import 'dart:convert';
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
import 'package:timely/api/endpoint.dart';
import 'package:timely/models/absen_stats.dart';
import 'package:timely/models/absen_today.dart';
import 'package:timely/models/checkin_model.dart';
import 'package:timely/models/checkout_model.dart';
import 'package:timely/models/getprofile_model.dart';
import 'package:timely/models/izin_model.dart';
import 'package:timely/services/auth_services.dart';

class ModernHomePage extends StatefulWidget {
  final void Function(String) showSnackBar;

  const ModernHomePage({super.key, required this.showSnackBar});

  @override
  State<ModernHomePage> createState() => _ModernHomePageState();
}

class _ModernHomePageState extends State<ModernHomePage>
    with TickerProviderStateMixin {
  // Method untuk mendapatkan salam personalized berdasarkan waktu
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

  // Method untuk mendapatkan emoji berdasarkan waktu
  String _getGreetingEmoji() {
    final hour = _now.hour;

    if (hour >= 5 && hour < 11) {
      return "🌅";
    } else if (hour >= 11 && hour < 15) {
      return "☀️";
    } else if (hour >= 15 && hour < 19) {
      return "🌇";
    } else {
      return "🌙";
    }
  }

  // Method untuk mendapatkan deskripsi waktu yang contextual
  String _getTimeDescription() {
    final hour = _now.hour;

    if (hour >= 5 && hour < 10) {
      return "A bright day to start activities!";
    } else if (hour >= 10 && hour < 14) {
      return "Productive time!";
    } else if (hour >= 14 && hour < 17) {
      return "Keep up the good work in the afternoon!";
    } else if (hour >= 17 && hour < 21) {
      return "Have a good rest after work!";
    } else {
      return "Don't forget to get enough rest!";
    }
  }

  late Timer _timer;
  late DateTime _now;

  bool _hasCheckedIn = false;
  bool _hasCheckedOut = false;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  String _todayStatus = "not yet absent";

  // User data
  String _userName = "User";
  String _userEmail = "";
  String _userInitials = "U";
  String? _profilePhotoUrl;
  bool _isLoadingData = false;

  // API Services
  final AuthService _authService = AuthService();

  // Maps
  GoogleMapController? mapController;
  LatLng _currentPosition = LatLng(-6.200000, 106.816666);
  double lat = -6.200000;
  double long = 106.816666;
  String _currentAddress = "Get location...";
  Marker? _marker;
  bool _isLoadingLocation = false;

  // Scroll Controller for SliverAppBar
  late ScrollController _scrollController;

  // App theme colors
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _accentRed = Color(0xFFEF4444);
  static const Color _accentPurple = Color(0xFF8B5CF6);
  static const Color _lightSurface = Color(0xFFFDFDFD);
  static const Color _lightBackground = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF475569);

  // Dark mode colors
  static const Color _darkBackground = Color(0xFF0F172A);
  static const Color _darkSurface = Color(0xFF1E293B);
  static const Color _darkTextPrimary = Color(0xFFF1F5F9);
  static const Color _darkTextSecondary = Color(0xFF94A3B8);

  // Animation Controllers
  late final AnimationController _parallaxController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

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
    duration: const Duration(milliseconds: 1000),
  );

  late final AnimationController _swipeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  // Swipe gesture tracking
  double _swipeProgress = 0.0;
  bool _isSwipeActive = false;
  String _currentSwipeAction = '';

  // Office location
  final LatLng _officeLocation = LatLng(-6.210869244172426, 106.81297234969804);
  final double _officeRadius = 50.0;
  final String _officeName = "Pusat Pelatihan Kerja Daerah Jakarta Pusat";
  final String _officeAddress =
      "Jl. Bendungan Hilir No. 1, RT.10/RW.2, Kb. Melati, Kec. Tanah Abang, Kota Jakarta Pusat";

  // FITUR : Random Question
  final List<Map<String, String>> _randomQuestions = [
    {'question': 'Berapa hasil dari 7 + 5?', 'answer': '12'},
    {'question': 'Apa ibu kota Indonesia?', 'answer': 'Jakarta'},
    {'question': 'Warna bendera Indonesia?', 'answer': 'Merah Putih'},
    {'question': '2 + 2 × 2 = ?', 'answer': '6'},
    {'question': 'Bulan kemerdekaan Indonesia?', 'answer': 'Agustus'},
  ];
  String _currentQuestion = '';
  String _currentAnswer = '';
  final TextEditingController _answerController = TextEditingController();

  // FITUR : Daily Quotes
  final List<String> _dailyQuotes = [
    "Keberhasilan adalah hasil dari kesempurnaan, kerja keras, belajar dari kegagalan, loyalitas, dan ketekunan.",
    "Hari ini adalah kesempatan untuk menjadi lebih baik dari kemarin.",
    "Kerja keras mengalahkan bakat ketika bakat tidak bekerja keras.",
    "Kesuksesan bukan tentang seberapa besar pencapaianmu, tapi seberapa besar hambatan yang berhasil kamu lewati.",
    "Mulailah dari mana kamu berada. Gunakan apa yang kamu punya. Lakukan apa yang kamu bisa.",
  ];

  // FITUR : Alarm Reminder
  TimeOfDay _reminderTime = TimeOfDay(hour: 8, minute: 0);
  bool _reminderEnabled = true;

  // FITUR : Absen Stats
  AbsenStatsModel? _absenStats;
  bool _isLoadingStats = false;

  bool get _isInOfficeArea {
    final distance = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _officeLocation.latitude,
      _officeLocation.longitude,
    );
    return distance <= _officeRadius;
  }

  // Parallax background elements
  final List<ParallaxElement> _parallaxElements = [
    ParallaxElement(
      icon: Icons.access_time_rounded,
      color: _primaryBlue,
      size: 40,
      position: Offset(0.1, 0.2),
      speed: 0.3,
      opacity: 0.08,
    ),
    ParallaxElement(
      icon: Icons.business_rounded,
      color: _accentGreen,
      size: 32,
      position: Offset(0.85, 0.15),
      speed: 0.5,
      opacity: 0.06,
    ),
    ParallaxElement(
      icon: Icons.location_on_rounded,
      color: _accentOrange,
      size: 36,
      position: Offset(0.15, 0.8),
      speed: 0.4,
      opacity: 0.07,
    ),
    ParallaxElement(
      icon: Icons.notifications_rounded,
      color: _accentPurple,
      size: 28,
      position: Offset(0.9, 0.85),
      speed: 0.6,
      opacity: 0.09,
    ),
    ParallaxElement(
      icon: Icons.check_circle_rounded,
      color: _accentGreen,
      size: 34,
      position: Offset(0.05, 0.5),
      speed: 0.2,
      opacity: 0.05,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _scrollController = ScrollController();
    _startAnimations();
    _loadUserData();
    _loadAbsenData();
    _loadAbsenStats();
    _loadReminderSettings();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          _checkReminder();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  void _startAnimations() {
    _fadeController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _cardController.forward();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    _parallaxController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _cardController.dispose();
    _swipeController.dispose();
    mapController?.dispose();
    _answerController.dispose();
    super.dispose();
  }

  // FITUR : Check Reminder
  void _checkReminder() {
    if (_reminderEnabled &&
        _now.hour == _reminderTime.hour &&
        _now.minute == _reminderTime.minute &&
        _now.second == 0) {
      _showReminderAlert();
    }
  }

  // FITUR : Show Reminder Alert
  void _showReminderAlert() {
    if (!_hasCheckedIn) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Pengingat Absen"),
          content: Text("Jangan lupa untuk absen masuk!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  // FITUR : Load Reminder Settings
  Future<void> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reminderEnabled = prefs.getBool('reminder_enabled') ?? true;
      final hour = prefs.getInt('reminder_hour') ?? 8;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  // FITUR : Save Reminder Settings
  Future<void> _saveReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', _reminderEnabled);
    await prefs.setInt('reminder_hour', _reminderTime.hour);
    await prefs.setInt('reminder_minute', _reminderTime.minute);
  }

  // FITUR : Show Reminder Settings Dialog
  void _showReminderSettings() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: _getSurfaceColor(isDarkMode),
          title: Text("Pengaturan Pengingat"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _reminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _reminderEnabled = value ?? false;
                      });
                    },
                  ),
                  Text("Aktifkan pengingat"),
                ],
              ),
              SizedBox(height: 10),
              Text("Waktu pengingat:"),
              ElevatedButton(
                onPressed: _reminderEnabled
                    ? () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: _reminderTime,
                        );
                        if (picked != null) {
                          setState(() {
                            _reminderTime = picked;
                          });
                        }
                      }
                    : null,
                child: Text(
                  _reminderTime.format(context),
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                _saveReminderSettings();
                Navigator.pop(context);
                widget.showSnackBar("Pengaturan disimpan");
              },
              child: Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  // FITUR : Load Absen Stats
  Future<void> _loadAbsenStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse(Endpoint.absenStats),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final stats = absenStatsModelFromJson(response.body);
        if (mounted) {
          setState(() {
            _absenStats = stats;
          });
        }
      }
    } catch (e) {
      print("Error loading absen stats: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  // FITUR : Random Question
  void _showRandomQuestion(String action) {
    final random = Random();
    final question = _randomQuestions[random.nextInt(_randomQuestions.length)];

    setState(() {
      _currentQuestion = question['question']!;
      _currentAnswer = question['answer']!;
      _currentSwipeAction = action;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildQuestionDialog();
      },
    );
  }

  // FITUR : Submit Answer
  void _submitAnswer() {
    if (_answerController.text.trim().toLowerCase() ==
        _currentAnswer.toLowerCase()) {
      Navigator.of(context).pop();

      if (_currentSwipeAction == 'checkin') {
        _onCheckIn();
      } else {
        _onCheckOut();
      }
    } else {
      widget.showSnackBar("Jawaban salah, coba lagi!");
      Navigator.of(context).pop();
      _showRandomQuestion(_currentSwipeAction);
    }
  }

  // FITUR : Daily Quote
  void _showDailyQuote() {
    final random = Random();
    final quote = _dailyQuotes[random.nextInt(_dailyQuotes.length)];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Pesan Hari Ini", style: TextStyle(color: _primaryBlue)),
        content: Text(quote, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Tutup"),
          ),
        ],
      ),
    );
  }

  // FITUR : Time Remaining
  String _getTimeRemaining() {
    if (_hasCheckedIn && !_hasCheckedOut) {
      final pulangTime = DateTime(_now.year, _now.month, _now.day, 17, 0);
      final difference = pulangTime.difference(_now);

      if (difference.inMinutes > 0) {
        return "${difference.inMinutes} menit lagi pulang";
      } else {
        return "Sudah waktunya pulang!";
      }
    } else if (!_hasCheckedIn) {
      final masukTime = DateTime(_now.year, _now.month, _now.day, 8, 0);
      final difference = masukTime.difference(_now);

      if (difference.inMinutes > 0) {
        return "${difference.inMinutes} menit lagi masuk";
      } else {
        return "Sudah waktunya masuk!";
      }
    }
    return "Absensi selesai";
  }

  // Helper method to get text colors based on theme
  Color _getTextPrimary(bool isDarkMode) {
    return isDarkMode ? _darkTextPrimary : _textPrimary;
  }

  Color _getTextSecondary(bool isDarkMode) {
    return isDarkMode ? _darkTextSecondary : _textSecondary;
  }

  Color _getSurfaceColor(bool isDarkMode) {
    return isDarkMode ? _darkSurface : _lightSurface;
  }

  Color _getBackgroundColor(bool isDarkMode) {
    return isDarkMode ? _darkBackground : _lightBackground;
  }

  Future<void> _loadUserData() async {
    try {
      final token = await _authService.getToken();
      final email = await _authService.getCurrentUserEmail();
      final name = await _authService.getCurrentUserName();

      setState(() {
        _userName = name ?? "User";
        _userEmail = email ?? "";
        _userInitials = _getInitials(_userName);
      });

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
              _userEmail = profileData.data!.email ?? _userEmail;
              _userInitials = _getInitials(_userName);
              _profilePhotoUrl = profileData.data!.profilePhotoUrl;
            });
          }
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  String _getInitials(String name) {
    final names = name.split(' ');
    if (names.length > 1) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return "U";
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

  void _onCheckIn() async {
    if (!_isInOfficeArea) {
      widget.showSnackBar("Anda tidak berada di area PPKD");
      return;
    }

    setState(() {
      _isLoadingData = true;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        widget.showSnackBar("Autentikasi diperlukan");
        return;
      }

      final response = await http.post(
        Uri.parse(Endpoint.checkIn),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "check_in_lat": _currentPosition.latitude,
          "check_in_lng": _currentPosition.longitude,
          "check_in_address": _currentAddress,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = checkinModelFromJson(response.body);
        if (result.data != null && mounted) {
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
      } else {
        widget.showSnackBar("Gagal absen masuk");
      }
    } catch (e) {
      print("Error during check-in: $e");
      widget.showSnackBar("Gagal absen masuk");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  void _onCheckOut() async {
    if (!_isInOfficeArea) {
      widget.showSnackBar("Anda tidak berada di area PPKD");
      return;
    }

    setState(() {
      _isLoadingData = true;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        widget.showSnackBar("Autentikasi diperlukan");
        return;
      }

      final response = await http.post(
        Uri.parse(Endpoint.checkOut),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "check_out_lat": _currentPosition.latitude,
          "check_out_lng": _currentPosition.longitude,
          "check_out_address": _currentAddress,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = checkoutModelFromJson(response.body);
        if (result.data != null && mounted) {
          setState(() {
            _hasCheckedOut = true;
            _checkOutTime = DateTime.now();
          });

          HapticFeedback.mediumImpact();
          widget.showSnackBar("Absen pulang berhasil!");
          _showDailyQuote();
          _loadAbsenData();
        }
      } else {
        widget.showSnackBar("Gagal absen pulang");
      }
    } catch (e) {
      print("Error during check-out: $e");
      widget.showSnackBar("Gagal absen pulang");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  // FITUR : Izin
  void _showIzinDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _getSurfaceColor(isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.assignment_late_rounded,
                  color: _accentOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Ajukan Izin",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _getTextPrimary(isDarkMode),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Silakan masukkan alasan izin:",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _getTextSecondary(isDarkMode),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Masukkan alasan izin",
                  hintStyle: GoogleFonts.inter(
                    color: _getTextSecondary(isDarkMode),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryBlue),
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.05),
                ),
                style: GoogleFonts.inter(color: _getTextPrimary(isDarkMode)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Batal",
                style: GoogleFonts.inter(
                  color: _getTextSecondary(isDarkMode),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  widget.showSnackBar("Alasan izin harus diisi");
                  return;
                }
                Navigator.of(context).pop();
                _performIzin(reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                "Submit",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // FITUR : Perform Izin
  Future<void> _performIzin(String alasan) async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        widget.showSnackBar("Autentikasi diperlukan");
        return;
      }

      final response = await http.post(
        Uri.parse(Endpoint.izin),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"alasan_izin": alasan}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = izinModelFromJson(response.body);
        widget.showSnackBar("Izin berhasil diajukan");
        _loadAbsenData();
      } else {
        widget.showSnackBar("Gagal mengajukan izin");
      }
    } catch (e) {
      print("Error during izin: $e");
      widget.showSnackBar("Gagal mengajukan izin");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  void _onSwipeUpdate(DragUpdateDetails details, String action) {
    final containerWidth = MediaQuery.of(context).size.width - 48 - 64;
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
        _showRandomQuestion(action);
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

  // UPDATE: Tambahkan method untuk Question Dialog
  Widget _buildQuestionDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: _getSurfaceColor(isDarkMode),
      title: Text("Verifikasi Anti-Bot"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentQuestion,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          TextField(
            controller: _answerController,
            decoration: InputDecoration(
              labelText: "Jawaban",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Batal"),
        ),
        ElevatedButton(onPressed: _submitAnswer, child: Text("Submit")),
      ],
    );
  }

  // UPDATE: Tambahkan stats card
  Widget _buildStatsCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingStats) {
      return Center(child: CircularProgressIndicator());
    }

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _cardController,
              curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
            ),
          ),
      child: Container(
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
                Icon(Icons.bar_chart_rounded, color: _accentPurple),
                SizedBox(width: 10),
                Text(
                  "Statistik Absen",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  "Total",
                  _absenStats?.data?.totalAbsen?.toString() ?? "0",
                  _primaryBlue,
                ),
                _buildStatItem(
                  "Masuk",
                  _absenStats?.data?.totalMasuk?.toString() ?? "0",
                  _accentGreen,
                ),
                _buildStatItem(
                  "Izin",
                  _absenStats?.data?.totalIzin?.toString() ?? "0",
                  _accentOrange,
                ),
              ],
            ),
          ],
        ),
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
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  // UPDATE: Tambahkan time remaining indicator
  Widget _buildTimeRemainingIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, color: _primaryBlue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              _getTimeRemaining(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method untuk parallax background
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

  // Method untuk expanded header
  // Method untuk expanded header (VERSI UPDATED)
  Widget _buildExpandedHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [_darkBackground, _darkSurface]
              : [_primaryBlue, Color(0xFF1D4ED8)],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern atau efek tambahan (optional)
          Positioned(
            top: 50,
            right: 20,
            child: Opacity(
              opacity: 0.1,
              child: Text(_getGreetingEmoji(), style: TextStyle(fontSize: 100)),
            ),
          ),

          // User info section
          Positioned(
            top: 80,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting dengan emoji
                Row(
                  children: [
                    Text(_getGreetingEmoji(), style: TextStyle(fontSize: 24)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getPersonalizedGreeting(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Time description
                Text(
                  _getTimeDescription(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: 16),

                // Date information
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('EEEE, d MMMM y', 'id_ID').format(_now),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Big time display
          Positioned(
            bottom: 60,
            left: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('HH:mm').format(_now),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${DateFormat('ss').format(_now)} detik',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Status indicator (optional)
          Positioned(
            bottom: 30,
            right: 24,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _hasCheckedIn
                    ? (_hasCheckedOut ? Colors.green : Colors.orange)
                    : Colors.blue,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _hasCheckedIn
                    ? (_hasCheckedOut ? "Selesai" : "Sedang Bekerja")
                    : "Belum Absen",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method untuk collapsed app bar
  // Method untuk collapsed app bar (VERSI UPDATED)
  Widget _buildCollapsedAppBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: kToolbarHeight,
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [_darkBackground, _darkSurface]
              : [_primaryBlue, Color(0xFF1D4ED8)],
        ),
      ),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
            child: Text(
              _userInitials,
              style: TextStyle(
                color: _primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          SizedBox(width: 12),

          // Greeting and user info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting line
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${_getGreetingEmoji()} ',
                        style: TextStyle(fontSize: 12),
                      ),
                      TextSpan(
                        text: _getPersonalizedGreeting().split(
                          ',',
                        )[0], // Hanya "Selamat Pagi"
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 2),

                // User name
                Text(
                  _userName.length > 15
                      ? '${_userName.substring(0, 15)}...'
                      : _userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Current time
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(_now),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('ss').format(_now),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Method untuk location card
  Widget _buildLocationCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _cardController,
              curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
            ),
          ),
      child: Container(
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
                    color: _primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: _primaryBlue,
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
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: _getCurrentLocation,
                    icon: Icon(Icons.refresh_rounded, size: 20),
                    color: _getTextSecondary(isDarkMode),
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
              height: 120,
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
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                    if (isDarkMode) {
                      controller.setMapStyle(_darkMapStyle);
                    }
                  },
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
                  color: _isInOfficeArea ? _accentGreen : _accentOrange,
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
                      color: _isInOfficeArea ? _accentGreen : _accentOrange,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Method untuk status cards
  Widget _buildStatusCards() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            title: "Status Hari Ini",
            value: _todayStatus,
            icon: Icons.calendar_today_rounded,
            color: _primaryBlue,
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
            color: _accentGreen,
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
            color: _accentRed,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _cardController,
              curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
            ),
          ),
      child: Container(
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
      ),
    );
  }

  // Method untuk completion card
  Widget _buildCompletionCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          Icon(Icons.check_circle_rounded, color: _accentGreen, size: 48),
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
            style: TextStyle(color: _getTextSecondary(isDarkMode)),
          ),
        ],
      ),
    );
  }

  // Method untuk out of office alert
  Widget _buildOutOfOfficeAlert() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _accentOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentOrange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_rounded, color: _accentOrange, size: 48),
          const SizedBox(height: 10),
          Text(
            "Di Luar Area PPKD",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _accentOrange,
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

  // Method untuk swipe button
  Widget _buildCleanSwipeButton({
    required String label,
    required IconData icon,
    required bool isEnabled,
    required String action,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onHorizontalDragUpdate: (details) => _onSwipeUpdate(details, action),
      onHorizontalDragEnd: (_) => _onSwipeEnd(action),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        height: 80,
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
        child: Stack(
          children: [
            // Progress indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width:
                  (MediaQuery.of(context).size.width - 48 - 64) *
                  _swipeProgress,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label == "check_in"
                          ? "Geser untuk Absen Masuk"
                          : "Geser untuk Absen Pulang",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getTextPrimary(isDarkMode),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method untuk work summary card
  Widget _buildWorkSummaryCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          Text(
            "Ringkasan Kerja",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          // Tambahkan konten ringkasan kerja di sini
        ],
      ),
    );
  }

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
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 300.0,
                  floating: false,
                  pinned: true,
                  stretch: true,
                  backgroundColor: isDarkMode ? _darkBackground : _primaryBlue,
                  elevation: 0,
                  leading: const SizedBox.shrink(),
                  leadingWidth: 0,
                  flexibleSpace: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final double collapseProgress =
                              ((constraints.maxHeight - kToolbarHeight) /
                                      (320.0 - kToolbarHeight))
                                  .clamp(0.0, 1.0);

                          return FlexibleSpaceBar(
                            stretchModes: const [
                              StretchMode.zoomBackground,
                              StretchMode.blurBackground,
                            ],
                            background: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: collapseProgress > 0.3
                                  ? _buildExpandedHeader()
                                  : _buildCollapsedAppBar(),
                            ),
                            titlePadding: EdgeInsets.zero,
                            title: AnimatedOpacity(
                              opacity: collapseProgress < 0.3 ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: SizedBox(
                                width: double.infinity,
                                child: _buildCollapsedAppBar(),
                              ),
                            ),
                          );
                        },
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.alarm_add_rounded),
                      onPressed: _showReminderSettings,
                      color: Colors.white,
                    ),
                  ],
                ),

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

                        // FITUR : Time Remaining Indicator
                        _buildTimeRemainingIndicator(),

                        const SizedBox(height: 16),

                        // Location Card
                        _buildLocationCard(),

                        const SizedBox(height: 24),

                        // Status Cards
                        _buildStatusCards(),

                        const SizedBox(height: 24),

                        // FITUR : Stats Card
                        _buildStatsCard(),

                        const SizedBox(height: 24),

                        // Action Section
                        if (_hasCheckedIn && _hasCheckedOut) ...[
                          _buildCompletionCard(),
                        ] else if (!_isInOfficeArea) ...[
                          _buildOutOfOfficeAlert(),
                        ] else if (!_hasCheckedIn) ...[
                          _buildCleanSwipeButton(
                            label: "check_in",
                            icon: Icons.login_rounded,
                            isEnabled: !_hasCheckedIn,
                            action: "checkin",
                            color: _accentGreen,
                          ),
                        ] else if (!_hasCheckedOut) ...[
                          _buildCleanSwipeButton(
                            label: "check_out",
                            icon: Icons.logout_rounded,
                            isEnabled: !_hasCheckedOut,
                            action: "checkout",
                            color: _accentRed,
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Work Summary Card
                        _buildWorkSummaryCard(),

                        const SizedBox(height: 32),
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
        widget.showSnackBar("location.service_disabled".tr());
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
          widget.showSnackBar("location.permission_denied".tr());
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

// Parallax Element Data Class
class ParallaxElement {
  final IconData icon;
  final Color color;
  final double size;
  final Offset position;
  final double speed;
  final double opacity;

  ParallaxElement({
    required this.icon,
    required this.color,
    required this.size,
    required this.position,
    required this.speed,
    required this.opacity,
  });
}

// Painter untuk parallax background
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

    for (final element in elements) {
      final offsetX =
          size.width * element.position.dx +
          animationValue * 100 * element.speed;
      final offsetY = size.height * element.position.dy;

      paint.color = element.color.withOpacity(element.opacity);

      // Draw icon (simplified as circle for example)
      canvas.drawCircle(Offset(offsetX, offsetY), element.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
