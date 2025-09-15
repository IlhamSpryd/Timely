import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timely/services/auth_services.dart';
import 'package:timely/utils/theme_helper.dart';
import 'package:timely/views/auth/login_page.dart';
import 'package:timely/widgets/profile_tile.dart';
import 'package:timely/widgets/settings_tile.dart';
import 'package:timely/widgets/switch_tile.dart';
import 'package:timely/widgets/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  final void Function(ThemeMode)? updateTheme;

  const SettingsPage({super.key, this.updateTheme});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final savedTheme = await ThemeHelper.loadTheme();
    setState(() {
      _isDarkMode = savedTheme == ThemeMode.dark;
    });
  }

  Future<void> _toggleTheme(bool isDark) async {
    final newThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await ThemeHelper.saveTheme(newThemeMode);
    setState(() {
      _isDarkMode = isDark;
    });

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setTheme(newThemeMode);

    if (widget.updateTheme != null) {
      widget.updateTheme!(newThemeMode);
    }
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('logout'.tr()),
          content: Text('logout_confirm'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
              child: Text(
                'logout'.tr(),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("settings".tr()),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Profile Section
          ProfileTile(
            name: "profile_name".tr(),
            subtitle: "profile_subtitle".tr(),
            avatarPath: "assets/images/avatar.png",
            onEdit: () {
              // TODO: Edit Profile
            },
          ),
          const Divider(),

          // Appearance Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "appearance".tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
          SwitchTile(
            title: "dark_mode".tr(),
            icon: Icons.dark_mode_outlined,
            value: _isDarkMode,
            onChanged: (v) => _toggleTheme(v),
          ),
          const Divider(),

          // Notifications Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "notifications".tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
          SwitchTile(
            title: "notifications".tr(),
            icon: Icons.notifications_outlined,
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          const Divider(),

          // Preferences Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "preferences".tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
          SettingTile(
            title: "language".tr(),
            subtitle: context.locale.languageCode == 'id'
                ? 'Bahasa'
                : 'English',
            icon: Icons.language_outlined,
            onTap: () {
              _showLanguagePicker();
            },
          ),
          SettingTile(
            title: "privacy_policy".tr(),
            subtitle: "Baca kebijakan privasi kami",
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
          SettingTile(
            title: "terms_of_service".tr(),
            subtitle: "Baca syarat dan ketentuan",
            icon: Icons.description_outlined,
            onTap: () {
              // TODO: Show terms of service
            },
          ),
          const Divider(),

          // About Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "about".tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
          SettingTile(
            title: "about".tr(),
            subtitle: "version".tr(),
            icon: Icons.info_outline,
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Timely",
                applicationVersion: "1.0.0",
                applicationLegalese: "© 2025 Ilham Inc.\nAll rights reserved.",
                applicationIcon: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.access_time_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              );
            },
          ),
          const Divider(),

          // Account Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "account".tr(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.logout_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'logout'.tr(),
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: _showLogoutDialog,
            trailing: Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),

          const SizedBox(height: 32),

          // App Version Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "app_version_footer".tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('language'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                onTap: () {
                  context.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Bahasa Indonesia'),
                onTap: () {
                  context.setLocale(const Locale('id'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
