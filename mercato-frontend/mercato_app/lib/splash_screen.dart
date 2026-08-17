import 'package:flutter/material.dart';
import 'package:mercato_app/features/auth/data/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextRoute();
  }

  Future<void> _decideNextRoute() async {
    await Future.delayed(const Duration(seconds: 2)); 

    final prefs = await SharedPreferences.getInstance();
    final onboardingVu = prefs.getBool('onboarding_vu') ?? false;
    final authService = AuthService();
    final connecte = await authService.isLoggedIn();

    if (!onboardingVu) {
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    if (connecte) {
      final role = await authService.getUserRole();
      if (role == 'recruteur') {
        Navigator.pushReplacementNamed(context, '/home-recruteur');
      } else {
        Navigator.pushReplacementNamed(context, '/home-joueur');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/choix-role');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}