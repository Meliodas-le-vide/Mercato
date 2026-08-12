import 'package:flutter/material.dart';
import 'package:mercato_app/core/constants/app_color.dart';

class OnboardingData {
  final String title;
  final String highlightText;
  final String description;
  final String imageUrl;

  OnboardingData({
    required this.title,
    required this.highlightText,
    required this.description,
    required this.imageUrl,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _pageIndex = 0;

 
  final List<OnboardingData> _onboardingPages = [
    OnboardingData(
      title: 'Révèle ton talent ',
      highlightText: 'au monde.',
      description:
          'Une vitrine digitale pour mettre en avant tes statistiques, vidéos de highlights et te faire repérer par les meilleurs recruteurs.',
      imageUrl: 'assets/images/3.jpg', 
      
    ),
    OnboardingData(
      title: 'Découvre les futurs ',
      highlightText: 'champions.',
      description:
          'Accède à une base de données mondiale de joueurs, filtre par poste, âge et région pour trouver la perle rare.',
      imageUrl: 'assets/images/2.jpg',
    ),
    OnboardingData(
      title: 'Mise en relation ',
      highlightText: 'directe & sécurisée.',
      description:
          'Échange directement via la messagerie interne et organise des essais sans intermédiaires douteux.',
      imageUrl: 'assets/images/5.jpg',
    ),
  ];


  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
          
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MERCATO',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                  if (_pageIndex < _onboardingPages.length - 1)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          _onboardingPages.length - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text(
                        'Passer',
                        style: TextStyle(color: AppColors.textSecondaryDark),
                      ),
                    ),
                ],
              ),
            ),


            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingPages.length,
                onPageChanged: (index) {
                  setState(() {
                    _pageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _onboardingPages[index];
                  return Column(
                    children: [
                     
                      Expanded(
                        flex: 6,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [  
                            Image.asset(
                               item.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                            
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    AppColors.darkBackground,
                                  ],
                                  stops: [0.6, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                   
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                  children: [
                                    TextSpan(text: item.title),
                                    TextSpan(
                                      text: item.highlightText,
                                      style: const TextStyle(color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                item.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondaryDark,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingPages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _pageIndex == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _pageIndex == index
                              ? AppColors.primary
                              : AppColors.darkInput,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                 
                  ElevatedButton(
                    onPressed: () {
                      if (_pageIndex < _onboardingPages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // Redirection vers l'écran de sélection de rôle 
                        Navigator.pushReplacementNamed(context, '/role-selection');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _pageIndex == _onboardingPages.length - 1
                          ? 'COMMENCER'
                          : 'SUIVANT',
                      style:  TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}