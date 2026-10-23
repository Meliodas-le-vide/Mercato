import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_bottom_nav.dart';
import 'package:mercato_frontend/features/admin/presentation/admin_profile_screen.dart';
import 'package:mercato_frontend/features/admin/presentation/admin_recruiters_screen.dart';
import 'package:mercato_frontend/features/admin/presentation/admin_reports_screen.dart';
import 'package:mercato_frontend/features/admin/presentation/admin_users_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AdminUsersScreen(),
    AdminRecruitersScreen(),
    AdminReportsScreen(),
    AdminProfileScreen(),
  ];

  static const _navItems = [
    AppBottomNavItem(icon: Icons.people_outline, label: 'Utilisateurs'),
    AppBottomNavItem(icon: Icons.verified_user_outlined, label: 'Recruteurs'),
    AppBottomNavItem(icon: Icons.flag_outlined, label: 'Signalements'),
    AppBottomNavItem(icon: Icons.account_circle, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
