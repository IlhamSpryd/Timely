import 'package:flutter/material.dart';
import 'package:timely/views/main/home_page.dart';
import 'package:timely/views/main/history_page.dart';
import 'package:timely/views/main/profile_page.dart';
import 'package:timely/views/main/settings_page.dart';
import 'package:timely/widgets/custom_navbar.dart';

class MainWrapper extends StatefulWidget {
  final void Function(ThemeMode)? updateTheme;

  const MainWrapper({super.key, this.updateTheme});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(
        showSnackBar: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.blueAccent,
            ),
          );
        },
      ),
      const HistoryPage(),
      const ProfilePage(),
      SettingsPage(updateTheme: widget.updateTheme),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
