import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iconsax/iconsax.dart';

import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/features/player/data/player_repository.dart';

import '../../../../../../core/utils/onboarding_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();

  late final AnimationController _particleController;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    // ---- Animation des particules ----
    _particleController = AnimationController(vsync: this, duration: 3.seconds);

    _particles = List.generate(
      20,
      (i) => _Particle(
        x: (i % 5) * 0.25,
        y: (i ~/ 5) * 0.33,
        size: 2.0 + (i % 3) * 2,
        delay: (i * 200).ms,
        opacity: 0.2 + (i % 4) * 0.2,
      ),
    );

    _particleController.repeat(reverse: true);

    // ---- Logique de redirection (ta logique conservée) ----
    _checkFirstLaunchAndAuth();
  }

  Future<void> _checkFirstLaunchAndAuth() async {
    // On attend 2.8s pour laisser l'animation se jouer entièrement
    await Future.delayed(const Duration(milliseconds: 2800));

    final isFirstTime = await OnboardingService.isFirstTimeUser();

    if (!mounted) return;

    if (isFirstTime) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }

    final token = await _storage.read(key: 'access_token');
    final role = await _storage.read(key: 'user_role');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      await _redirectToDashboard(role);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
    }
  }

  Future<void> _redirectToDashboard(String? role) async {
    // Joueur qui n'a pas encore complété son profil → page de complétion.
    if (role == 'PLAYER') {
      final complete = await PlayerProfileRepository(DioClient())
          .isProfileComplete();
      if (!mounted) return;
      if (!complete) {
        Navigator.pushReplacementNamed(context, AppRoutes.completeProfile);
        return;
      }
    }

    final route = switch (role) {
      'PLAYER' => AppRoutes.playerDashboard,
      'RECRUITER' || 'CLUB_AGENT' => AppRoutes.scoutingSearch,
      'ADMIN' => AppRoutes.adminDashboard,
      _ => AppRoutes.feed,
    };

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E5658), Color(0xFF0D3334), Color(0xFF2A6B6D)],
          ),
        ),
        child: Stack(
          children: [
            // ---- Particules animées ----
            ..._particles.map(
              (p) => AnimatedBuilder(
                animation: _particleController,
                builder: (_, __) => Positioned(
                  left: MediaQuery.of(context).size.width * p.x,
                  top:
                      MediaQuery.of(context).size.height * p.y +
                      _particleController.value * 40,
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha:
                            p.opacity * (1 - _particleController.value * 0.5),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ).animate(delay: p.delay).fadeIn().scale(),
                ),
              ),
            ),

            // ---- Contenu central ----
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---- Logo dans un carré arrondi translucide ----
                  Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Iconsax.global,
                          size: 48,
                          color: Colors.white,
                        ),
                      )
                      .animate()
                      .scale(duration: 800.ms, curve: Curves.easeOutBack)
                      .then()
                      .shimmer(
                        duration: 2000.ms,
                        colors: [Colors.white54, Colors.white, Colors.white54],
                      ),
                  const SizedBox(height: 24),

                  // ---- Titre ----
                  Text(
                        'MON TALENT',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: context.weight(FontWeight.w700),
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 700.ms)
                      .slideY(begin: 20, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 8),

                  // ---- Tagline ----
                  Text(
                        'Découvre. Montre. Perce.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 2,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideY(begin: 10, end: 0),
                  const SizedBox(height: 48),

                  // ---- Loader ----
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: AppLoader(size: 24),
                  ).animate().fadeIn(delay: 800.ms).scale(delay: 800.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final Duration delay;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.delay,
    required this.opacity,
  });
}
