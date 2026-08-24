import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import '../../../../../../core/utils/onboarding_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkFirstLaunchAndAuth();
  }

  Future<void> _checkFirstLaunchAndAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    final isFirstTime = await OnboardingService.isFirstTimeUser();

    if (!mounted) return;

    if (isFirstTime) {
      // 1. Nouvel utilisateur -> Onboarding
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    } else {
      // 2. Déjà venu -> Vérification du token JWT
      final token = await _storage.read(key: 'access_token');
      final role = await _storage.read(key: 'user_role');

      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        // Utilisateur déjà connecté -> Redirection selon le rôle
        _redirectToDashboard(role);
      } else {
        // Non connecté -> Choix du rôle (au lieu de /login direct)
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      }
    }
  }

  void _redirectToDashboard(String? role) {
    switch (role) {
      case 'PLAYER':
        Navigator.pushReplacementNamed(context, AppRoutes.playerDashboard);
        break;
      case 'RECRUITER':
      case 'CLUB_AGENT':
        Navigator.pushReplacementNamed(context, AppRoutes.scoutingSearch);
        break;
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.feed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 90, color:AppColors.primaryNeon),
            SizedBox(height: 30),
            CircularProgressIndicator(color: AppColors.primaryNeon),
          ],
        ),
      ),
    );
  }
}