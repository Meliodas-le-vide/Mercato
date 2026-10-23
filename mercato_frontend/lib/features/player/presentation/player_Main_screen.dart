import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_bottom_nav.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/features/chat/presentation/conversation_screen.dart';
import 'package:mercato_frontend/features/events/presentation/event_list_screen.dart';
import 'package:mercato_frontend/features/player/presentation/feed_screen.dart';
import 'package:mercato_frontend/features/player/presentation/player_profile_screen.dart';

class PlayerMainScreen extends StatefulWidget {
  const PlayerMainScreen({super.key});

  @override
  State<PlayerMainScreen> createState() => _PlayerMainScreenState();
}

class _PlayerMainScreenState extends State<PlayerMainScreen> {
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
      debugPrint('Erreur loadUserSession: $e');
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
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'Événement',
    ),
    AppBottomNavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Message',
    ),
    AppBottomNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  /// FAB central → ouvrir l'écran de publication de vidéo
  void _onFabPressed() {
    Navigator.pushNamed(context, AppRoutes.upload);
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
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: colors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Session expirée',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: context.weight(FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Veuillez vous reconnecter pour continuer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: colors.surfaceVariant,
                  ),
                  child: Text(
                    'Se reconnecter',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: context.weight(FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // -------- Pages --------
    final List<Widget> pages = [
      const FeedScreen(),
      const EventsListScreen(),
      ConversationsListScreen(currentUserId: _currentUserId!),
      const PlayerProfileScreen(),
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
          colors: [AppColors.primaryYellow, AppColors.accentOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        fabIconColor: AppColors.onGold,
      ),
    );
  }
}
