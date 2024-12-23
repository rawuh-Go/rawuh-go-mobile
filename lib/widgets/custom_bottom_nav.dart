import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF2A5867),
        unselectedItemColor: Colors.grey.shade400,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        items: [
          _buildNavItem(
              'Home', 'assets/img/main_page/home.png', 0, notificationProvider),
          _buildNavItem('Schedule', 'assets/img/main_page/history.png', 1,
              notificationProvider),
          const BottomNavigationBarItem(icon: SizedBox(height: 24), label: ''),
          _buildNavItem('Notifikasi', 'assets/img/main_page/notif.png', 3,
              notificationProvider),
          _buildNavItem('Profil', 'assets/img/main_page/user.png', 4,
              notificationProvider),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    String label,
    String iconPath,
    int index,
    NotificationProvider notificationProvider,
  ) {
    if (index == 3) {
      // Notification tab index
      return BottomNavigationBarItem(
        icon: badges.Badge(
          showBadge: notificationProvider.hasUnreadNotifications,
          badgeStyle: const badges.BadgeStyle(
            badgeColor: Colors.red,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: Image.asset(
              iconPath,
              width: 24,
              height: 24,
              color: selectedIndex == index
                  ? const Color(0xFF2A5867)
                  : Colors.grey.shade400,
            ),
          ),
        ),
        label: label,
      );
    }
    return BottomNavigationBarItem(
      icon: Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: Image.asset(
          iconPath,
          width: 24,
          height: 24,
          color: selectedIndex == index
              ? const Color(0xFF2A5867)
              : Colors.grey.shade400,
        ),
      ),
      label: label,
    );
  }
}
