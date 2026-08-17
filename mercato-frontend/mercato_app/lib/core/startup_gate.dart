import 'package:flutter/material.dart';
import 'package:mercato_app/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mercato_app/features/auth/presentation/onboarding_screen.dart';
import 'package:mercato_app/features/auth/presentation/role_selection_screen.dart';
import 'package:mercato_app/features/player/presentation/dashboard/player_home_screen.dart';
import 'package:mercato_app/features/recruiter/presentation/dashboard/recruiter_home_screen.dart';

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool _loadingPrefs = true;
  bool _onboardingVu = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingVu = prefs.getBool('onboarding_vu') ?? false;
      _loadingPrefs = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPrefs) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B141B),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (!_onboardingVu) {
      return const OnboardingScreen();
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isCheckingAuth) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B141B),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        if (auth.isAuthenticated) {
          return auth.user?.isRecruiter == true
              ? const RecruiterHomeScreen()
              : const PlayerHomeScreen();
        }
        // Pas connecté, onboarding déjà vu -> on lui fait choisir son rôle
        return const RoleSelectionScreen();
      },
    );
  }
}