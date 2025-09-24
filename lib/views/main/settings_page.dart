import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:timely/api/profile_api.dart';
import 'package:timely/services/auth_services.dart';
import 'package:timely/utils/theme_helper.dart';
import 'package:timely/views/auth/login_page.dart';
import 'package:timely/widgets/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  final void Function(ThemeMode)? updateTheme;

  const SettingsPage({super.key, this.updateTheme});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  bool _notifications = true;
  bool _isDarkMode = false;
  UserProfile? _userProfile;
  bool _isLoading = true;

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _scaleController;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadTheme();
    _loadUserProfile();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final savedTheme = await ThemeHelper.loadTheme();
    if (mounted) {
      setState(() {
        _isDarkMode = savedTheme == ThemeMode.dark;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final token = await _authService.getToken();
      if (token != null && mounted) {
        final profile = await ProfileApi().getProfile(token);
        if (mounted) {
          setState(() {
            _userProfile = UserProfile.fromGetProfileModel(profile);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      _logger.e('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleTheme(bool isDark) async {
    final newThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await ThemeHelper.saveTheme(newThemeMode);
    if (mounted) {
      setState(() {
        _isDarkMode = isDark;
      });
    }

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setTheme(newThemeMode);

    if (widget.updateTheme != null) {
      widget.updateTheme!(newThemeMode);
    }

    HapticFeedback.lightImpact();
  }

  void _logout() async {
    final authService = AuthService();
    await authService.logout();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  void _showLogoutDialog() {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout_rounded, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'logout'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Text(
            'logout_confirm'.tr(),
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'cancel'.tr(),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'logout'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _animatePress(VoidCallback onTap) {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
      onTap();
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();
    final token = await _authService.getToken();

    if (token == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        final file = File(image.path);

        // Panggil service yang benar
        await _profileService.updateProfilePhoto(file.path);

        // Hanya reload jika widget masih aktif
        if (mounted) {
          _loadUserProfile();
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('profile_photo_updated'.tr())));
        }
      }
    } catch (e) {
      _logger.e('Failed to update profile photo: $e'); // Tambahkan logging
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('failed_update_photo'.tr())));
      }
    }
  }

  void _showEditProfileDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: _userProfile?.name);
    final emailController = TextEditingController(text: _userProfile?.email);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('edit_profile'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'name'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'email'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final token = await _authService.getToken();
                  if (token != null) {
                    await ProfileApi().updateProfile(
                      token,
                      nameController.text,
                      emailController.text,
                    );

                    // Reload profile data hanya jika widget masih aktif
                    if (mounted) {
                      _loadUserProfile();
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('profile_updated'.tr())),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('failed_update_profile'.tr())),
                    );
                  }
                }
              },
              child: Text('save'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('change_password'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'current_password'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'new_password'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'confirm_password'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('passwords_not_match'.tr())),
                    );
                  }
                  return;
                }

                try {
                  final token = await _authService.getToken();
                  if (token != null) {
                    // Implement password change API call here
                    // await ProfileApi().changePassword(
                    //   token,
                    //   currentPasswordController.text,
                    //   newPasswordController.text,
                    // );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('password_updated'.tr())),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('failed_update_password'.tr())),
                    );
                  }
                }
              },
              child: Text('save'.tr()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]
              : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with border
          GestureDetector(
            onTap: _changeProfilePhoto,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage: _userProfile?.profilePhotoUrl != null
                    ? NetworkImage(_userProfile!.profilePhotoUrl!)
                    : null,
                child: _userProfile?.profilePhotoUrl == null
                    ? Icon(
                        Icons.person_rounded,
                        color: const Color(0xFF3B82F6),
                        size: 32,
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoading
                      ? "loading".tr()
                      : _userProfile?.name ?? "profile_name".tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLoading
                      ? ""
                      : _userProfile?.email ?? "profile_subtitle".tr(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                if (_userProfile?.batchKe != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Batch ${_userProfile?.batchKe}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
                if (_userProfile?.trainingTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _userProfile!.trainingTitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Edit button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _animatePress(_showEditProfileDialog),
              icon: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _animatePress(onTap),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDestructive
                            ? Colors.red.withOpacity(0.1)
                            : (iconColor ??
                                      Theme.of(context).colorScheme.primary)
                                  .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: isDestructive
                            ? Colors.red
                            : (iconColor ??
                                  Theme.of(context).colorScheme.primary),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color:
                                  textColor ??
                                  (isDarkMode
                                      ? Colors.white
                                      : Colors.grey.shade900),
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    trailing ??
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
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

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Switch.adaptive(
              value: value,
              onChanged: (newValue) {
                onChanged(newValue);
                HapticFeedback.lightImpact();
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Profile".tr(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Profile Header
                _buildProfileHeader(),

                const SizedBox(height: 20),

                // Account Section
                _buildSection(
                  title: "account".tr().toUpperCase(),
                  children: [
                    _buildSettingTile(
                      title: "Edit profile".tr(),
                      subtitle: "update profile info".tr(),
                      icon: Icons.person_rounded,
                      onTap: _showEditProfileDialog,
                    ),
                    _buildSettingTile(
                      title: "change_password".tr(),
                      subtitle: "update password info".tr(),
                      icon: Icons.lock_rounded,
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),

                // Appearance Section
                _buildSection(
                  title: "appearance".tr().toUpperCase(),
                  children: [
                    _buildSwitchTile(
                      title: "dark_mode".tr(),
                      icon: Icons.dark_mode_rounded,
                      value: _isDarkMode,
                      onChanged: _toggleTheme,
                    ),
                  ],
                ),

                // Notifications Section
                _buildSection(
                  title: "notifications".tr().toUpperCase(),
                  children: [
                    _buildSwitchTile(
                      title: "notifications".tr(),
                      icon: Icons.notifications_rounded,
                      value: _notifications,
                      onChanged: (v) {
                        if (mounted) {
                          setState(() => _notifications = v);
                        }
                      },
                    ),
                  ],
                ),

                // Preferences Section
                _buildSection(
                  title: "preferences".tr().toUpperCase(),
                  children: [
                    _buildSettingTile(
                      title: "language".tr(),
                      subtitle: context.locale.languageCode == 'id'
                          ? 'Bahasa Indonesia'
                          : 'English',
                      icon: Icons.language_rounded,
                      onTap: _showLanguagePicker,
                    ),
                    _buildSettingTile(
                      title: "privacy_policy".tr(),
                      subtitle: "Baca kebijakan privasi kami",
                      icon: Icons.privacy_tip_rounded,
                      onTap: () {
                        // TODO: Show privacy policy
                      },
                    ),
                    _buildSettingTile(
                      title: "terms_of_service".tr(),
                      subtitle: "Baca syarat dan ketentuan",
                      icon: Icons.description_rounded,
                      onTap: () {
                        // TODO: Show terms of service
                      },
                    ),
                  ],
                ),

                // About Section
                _buildSection(
                  title: "about".tr().toUpperCase(),
                  children: [
                    _buildSettingTile(
                      title: "about".tr(),
                      subtitle: "${"version".tr()} 1.0.0",
                      icon: Icons.info_rounded,
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: "Timely",
                          applicationVersion: "1.0.0",
                          applicationLegalese:
                              "© 2025 Tungkings Inc.\nAll rights reserved.",
                          applicationIcon: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.access_time_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Account Section - Destructive Actions
                _buildSection(
                  title: "actions".tr().toUpperCase(),
                  children: [
                    _buildSettingTile(
                      title: 'logout'.tr(),
                      icon: Icons.logout_rounded,
                      onTap: _showLogoutDialog,
                      isDestructive: true,
                      textColor: Colors.red,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.red.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Footer
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        "app_version_footer".tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Made with Tungkings Inc",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
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
      ),
    );
  }

  void _showLanguagePicker() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'language'.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Language options
                    _buildLanguageOption(
                      title: 'English',
                      isSelected: context.locale.languageCode == 'en',
                      onTap: () {
                        context.setLocale(const Locale('en'));
                        Navigator.pop(context);
                        HapticFeedback.selectionClick();
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildLanguageOption(
                      title: 'Bahasa Indonesia',
                      isSelected: context.locale.languageCode == 'id',
                      onTap: () {
                        context.setLocale(const Locale('id'));
                        Navigator.pop(context);
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : (isDarkMode ? Colors.white : Colors.grey.shade900),
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Model untuk data profil user
class UserProfile {
  final int? id;
  final String? name;
  final String? email;
  final String? batchKe;
  final String? trainingTitle;
  final String? jenisKelamin;
  final String? profilePhotoUrl;

  UserProfile({
    this.id,
    this.name,
    this.email,
    this.batchKe,
    this.trainingTitle,
    this.jenisKelamin,
    this.profilePhotoUrl,
  });

  factory UserProfile.fromGetProfileModel(GetProfileModel model) {
    return UserProfile(
      id: model.data?.id,
      name: model.data?.name,
      email: model.data?.email,
      batchKe: model.data?.batchKe,
      trainingTitle: model.data?.trainingTitle,
      jenisKelamin: model.data?.jenisKelamin,
      profilePhotoUrl: model.data?.profilePhotoUrl,
    );
  }
}

// API Service untuk mengelola profil
class ProfileApi {
  final String baseUrl = "https://appabsensi.mobileprojp.com/api";

  Future<GetProfileModel> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return GetProfileModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load profile: ${response.body}');
    }
  }

  Future<void> updateProfile(String token, String name, String email) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  Future<void> updateProfilePhoto(String token, File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/photo'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('profile_photo', imageFile.path),
    );

    var response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to update profile photo');
    }
  }
}

// Model untuk response get profile
class GetProfileModel {
  final String? message;
  final ProfileData? data;

  GetProfileModel({this.message, this.data});

  factory GetProfileModel.fromJson(Map<String, dynamic> json) {
    return GetProfileModel(
      message: json['message'],
      data: json['data'] != null ? ProfileData.fromJson(json['data']) : null,
    );
  }
}

class ProfileData {
  final int? id;
  final String? name;
  final String? email;
  final String? batchKe;
  final String? trainingTitle;
  final String? jenisKelamin;
  final String? profilePhotoUrl;

  ProfileData({
    this.id,
    this.name,
    this.email,
    this.batchKe,
    this.trainingTitle,
    this.jenisKelamin,
    this.profilePhotoUrl,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      batchKe: json['batch_ke'],
      trainingTitle: json['training_title'],
      jenisKelamin: json['jenis_kelamin'],
      profilePhotoUrl: json['profile_photo_url'],
    );
  }
}
