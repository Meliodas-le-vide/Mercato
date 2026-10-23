import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/onboarding_service.dart';

class OnboardingItem {
  final String title;
  final String description;
  final String imagePath;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingItem> _pages = [
    OnboardingItem(
      title: 'Révèle ton talent',
      description: 'Crée ton profil sportif, partage tes meilleures actions et sois repéré par les recruteurs du monde entier.',
      imagePath: 'assets/images/onboarding1.jpg',
    ),
    OnboardingItem(
      title: 'Découvre des pépites',
      description: 'Accède à des milliers de CV vidéo et trouve les futurs talents qui intégreront ton club.',
      imagePath: 'assets/images/onboarding2.jpg',
    ),
    OnboardingItem(
      title: 'Rejoins le réseau',
      description: 'Connecte-toi directement avec les agents, recruteurs et clubs professionnels.',
      imagePath: 'assets/images/onboarding3.jpg',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService.setOnboardingCompleted();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/role-selection');
  }

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ⚠️ Fond noir volontaire : écran toujours sombre (design premium),
      // indépendant du thème clair/sombre choisi par l'utilisateur.
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // -------- Images plein écran --------
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _pages[index].imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback sombre en attendant les vraies images
                      return Container(color: AppColors.backgroundDark);
                    },
                  ),
                  // Overlay sombre en dégradé pour la lisibilité du texte
                  // (reste sombre quel que soit le thème : c'est posé sur image)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                          AppColors.backgroundDark,
                        ],
                        stops: const [0.0, 0.5, 0.85],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // -------- Contenu textuel + contrôles --------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Textes animés au changement de page
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      key: ValueKey<int>(_currentIndex),
                      children: [
                        Text(
                          _pages[_currentIndex].title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: context.weight(FontWeight.bold),
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _pages[_currentIndex].description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Indicateurs de page
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _currentIndex == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? AppColors.primaryYellow
                              : Colors.white.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Bouton principal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: AppColors.onGold,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentIndex == _pages.length - 1
                                ? 'Commencer'
                                : 'Suivant',
                            style: TextStyle(
                              fontWeight: context.weight(FontWeight.bold),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bouton "Passer"
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Passer l\'introduction',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.54),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
