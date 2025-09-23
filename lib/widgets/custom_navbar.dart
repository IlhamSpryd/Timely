import 'package:flutter/material.dart';

class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.onPrimaryContainer,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage("assets/images/homeon.png")),
            activeIcon: ImageIcon(AssetImage("assets/images/homeoff.png")),
            label: " ",
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage("assets/images/historyoff.png")),
            activeIcon: ImageIcon(AssetImage("assets/images/historyon.png")),
            label: " ",
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage("assets/images/chartoff.png")),
            activeIcon: ImageIcon(AssetImage("assets/images/charton.png")),
            label: " ",
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage("assets/images/useroff.png")),
            activeIcon: ImageIcon(AssetImage("assets/images/useron.png")),
            label: " ",
          ),
        ],
      ),
    );
  }
}
