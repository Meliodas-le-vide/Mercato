import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_bottom_nav.dart';
import 'package:mercato_frontend/features/user/presentation/explore_screen.dart';
import 'package:mercato_frontend/features/user/presentation/favoris_screen.dart';
import 'package:mercato_frontend/features/user/presentation/home_screen.dart';
import 'package:mercato_frontend/features/user/presentation/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const _favorisIndex = 2;
  final _favorisKey = GlobalKey<FavorisScreenState>();

  late final List<Widget> _pages = [
    const HomeScreen(),
    const ExploreScreen(),
    FavorisScreen(key: _favorisKey),
    const ProfileScreen(),
  ];

  static const _navItems = [
    AppBottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
    ),
    AppBottomNavItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'Explorer',
    ),
    AppBottomNavItem(
      icon: Icons.favorite_border_rounded,
      activeIcon: Icons.favorite_rounded,
      label: 'Favoris',
    ),
    AppBottomNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    if (index == _favorisIndex) {
      _favorisKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
