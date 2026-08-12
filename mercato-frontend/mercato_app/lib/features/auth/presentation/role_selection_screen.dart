import 'package:flutter/material.dart';
import 'package:mercato_app/core/constants/app_color.dart';

class RoleOption {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String imageUrl;

  RoleOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
  });
}

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  
  String _selectedRoleId = 'PLAYER';

  final List<RoleOption> _roles = [
    RoleOption(
      id: 'PLAYER',
      title: 'JOUEUR',
      subtitle: 'Talent & Footballeur',
      description:
          'Crée ton profil, publie tes vidéos de match/entraînement et capte l’attention des recruteurs.',
      imageUrl:
          'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?q=80&w=800', 
    ),
    RoleOption(
      id: 'RECRUITER',
      title: 'RECRUTEUR / CLUB',
      subtitle: 'Scout, Club & Agent',
      description:
          'Accède au vivier de jeunes talents, effectue des recherches ciblées et entre en contact direct.',
      imageUrl:
          'https://images.unsplash.com/photo-1574629810360-7efbbe195018?q=80&w=800', 
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QUI ÊTES-VOUS ?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sélectionnez votre profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cette étape nous permet de vous proposer une expérience personnalisée.',
                style: TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Liste des cartes de rôles
              Expanded(
                child: ListView.separated(
                  itemCount: _roles.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final isSelected = _selectedRoleId == role.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRoleId = role.id;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 170,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                           
                              Positioned.fill(
                                child: Image.network(
                                  role.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerRight,
                                      end: Alignment.centerLeft,
                                      colors: [
                                        Colors.black.withOpacity(0.2),
                                        AppColors.darkBackground.withOpacity(0.95),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            role.title,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w300,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            role.subtitle,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            role.description,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.textSecondaryDark,
                                              fontSize: 12,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textSecondaryDark,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 18,
                                              color: Colors.black,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register', arguments: _selectedRoleId);
                  print('Rôle sélectionné : $_selectedRoleId');
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
                child: const Text(
                  'CONTINUER',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                    letterSpacing: 1,
                    color: AppColors.textPrimaryDark
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}