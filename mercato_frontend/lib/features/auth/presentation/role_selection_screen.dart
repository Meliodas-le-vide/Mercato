import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // En-tête
              const Text(
                'MERCATO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryNeon,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Que souhaitez-vous faire sur la plateforme ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choisissez votre profil pour personnaliser votre expérience.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 28),

              // Carte 1 : FAN / DÉCOUVRIR
              _RoleCard(
                title: 'JE SUIS UN FAN / DÉCOUVRIR',
                subtitle: null,
                badgeText: null,
                icon: Icons.arrow_forward,
                onTap: () {
                  Navigator.pushNamed(context, '/register', arguments: 'USER');
                },
              ),
              const SizedBox(height: 16),

              // Carte 2 : JOUEUR
              _RoleCard(
                title: 'JE SUIS UN JOUEUR',
                subtitle: 'Crée ton CV vidéo et fais-toi repérer',
                badgeText: 'CRÉER MON CV VIDÉO',
                icon: Icons.sports_soccer,
                onTap: () {
                  Navigator.pushNamed(context, '/register', arguments: 'PLAYER');
                },
              ),
              const SizedBox(height: 16),

              // Carte 3 : RECRUTEUR / AGENT
              _RoleCard(
                title: 'JE SUIS RECRUTEUR\nCLUB / AGENT',
                subtitle: 'Accède au vivier de talents exclusif',
                badgeText: 'ACCÈS PREMIUM',
                icon: Icons.search,
                onTap: () {
                  Navigator.pushNamed(context, '/register', arguments: 'RECRUITER');
                },
              ),
              const SizedBox(height: 24),

              // Lien de connexion rapide
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'J\'ai déjà un compte. ',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/login', arguments: 'USER');
                    },
                    child: const Text(
                      'Se connecter.',
                      style: TextStyle(
                        color: AppColors.primaryNeon,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badgeText;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    this.subtitle,
    this.badgeText,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF13192B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badgeText != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNeon,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (subtitle != null) ...[
                  Text(
                    subtitle!,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(icon, color: Colors.white54, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}