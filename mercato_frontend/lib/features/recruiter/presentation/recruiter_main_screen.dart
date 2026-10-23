import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/widgets/app_bottom_nav.dart';
import 'package:mercato_frontend/features/chat/presentation/conversation_screen.dart';
import 'package:mercato_frontend/features/recruiter/presentation/recruiter_home_screen.dart';
import 'package:mercato_frontend/features/recruiter/presentation/recruiter_profile_screen.dart';
import 'package:mercato_frontend/features/recruiter/presentation/recruiter_search_screen.dart';

class RecruiterMainScreen extends StatefulWidget {
  const RecruiterMainScreen({super.key});

  @override
  State<RecruiterMainScreen> createState() => _RecruiterMainScreenState();
}

class _RecruiterMainScreenState extends State<RecruiterMainScreen> {
  final _storage = const FlutterSecureStorage();

  int _currentIndex = 0;
  int? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    try {
      final userJson = await _storage.read(key: 'user_data');
      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        final id = userMap['id'] ?? userMap['userId'];
        if (mounted) {
          setState(() {
            _currentUserId = id;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur load session: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const _navItems = [
    AppBottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
    ),
    AppBottomNavItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'Rechercher',
    ),
    AppBottomNavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Messages',
    ),
    AppBottomNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Compte',
    ),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  /// FAB central → créer un événement
  void _onFabPressed() {
    Navigator.pushNamed(context, AppRoutes.createEvent);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // -------- État de chargement --------
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: AppLoader()),
      );
    }

    // -------- Erreur de session --------
    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erreur de session. Veuillez vous reconnecter.',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // -------- Pages --------
    final List<Widget> pages = [
      const RecruiterHomeScreen(),
      const RecruiterSearchScreen(),
      ConversationsListScreen(currentUserId: _currentUserId!),
      const RecruiterProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        onFabPressed: _onFabPressed,
        fabIcon: Icons.add_rounded,

        fabGradient: const LinearGradient(
          colors: AppColors.goldGradient,
          stops: AppColors.goldGradientStops,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        fabIconColor: AppColors.onGold,
      ),
    );
  }
}
