// import 'package:flutter/material.dart';
// import '../../../core/constants/app_colors.dart';

// class RoleSelectionScreen extends StatelessWidget {
//   const RoleSelectionScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0E1A),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const SizedBox(height: 10),
//               // En-tête
//               const Text(
//                 'MERCATO',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.w900,
//                   color: AppColors.primaryNeon,
//                   letterSpacing: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Que souhaitez-vous faire sur la plateforme ?',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               const Text(
//                 'Choisissez votre profil pour personnaliser votre expérience.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.white54, fontSize: 12),
//               ),
//               const SizedBox(height: 28),

//               // Carte 1 : FAN / DÉCOUVRIR
//               _RoleCard(
//                 title: 'JE SUIS UN FAN / DÉCOUVRIR',
//                 subtitle: null,
//                 badgeText: null,
//                 icon: Icons.arrow_forward,
//                 onTap: () {
//                   Navigator.pushNamed(context, '/register', arguments: 'USER');
//                 },
//               ),
//               const SizedBox(height: 16),

//               // Carte 2 : JOUEUR
//               _RoleCard(
//                 title: 'JE SUIS UN JOUEUR',
//                 subtitle: 'Crée ton CV vidéo et fais-toi repérer',
//                 badgeText: 'CRÉER MON CV VIDÉO',
//                 icon: Icons.sports_soccer,
//                 onTap: () {
//                   Navigator.pushNamed(context, '/register', arguments: 'PLAYER');
//                 },
//               ),
//               const SizedBox(height: 16),

//               // Carte 3 : RECRUTEUR / AGENT
//               _RoleCard(
//                 title: 'JE SUIS RECRUTEUR\nCLUB / AGENT',
//                 subtitle: 'Accède au vivier de talents exclusif',
//                 badgeText: 'ACCÈS PREMIUM',
//                 icon: Icons.search,
//                 onTap: () {
//                   Navigator.pushNamed(context, '/register', arguments: 'RECRUITER');
//                 },
//               ),
//               const SizedBox(height: 24),

//               // Lien de connexion rapide
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text(
//                     'J\'ai déjà un compte. ',
//                     style: TextStyle(color: Colors.white54, fontSize: 13),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.pushNamed(context, '/login', arguments: 'USER');
//                     },
//                     child: const Text(
//                       'Se connecter.',
//                       style: TextStyle(
//                         color: AppColors.primaryNeon,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _RoleCard extends StatelessWidget {
//   final String title;
//   final String? subtitle;
//   final String? badgeText;
//   final IconData icon;
//   final VoidCallback onTap;

//   const _RoleCard({
//     required this.title,
//     this.subtitle,
//     this.badgeText,
//     required this.icon,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: const Color(0xFF13192B),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.white.withOpacity(0.08)),
//         ),
//         child: Stack(
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (badgeText != null) ...[
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: AppColors.primaryNeon,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       badgeText!,
//                       style: const TextStyle(
//                         color: Colors.black,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 9,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                 ],
//                 if (subtitle != null) ...[
//                   Text(
//                     subtitle!,
//                     style: const TextStyle(color: Colors.white54, fontSize: 11),
//                   ),
//                   const SizedBox(height: 4),
//                 ],
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w900,
//                     fontSize: 16,
//                     height: 1.2,
//                   ),
//                 ),
//               ],
//             ),
//             Positioned(
//               right: 0,
//               bottom: 0,
//               child: Icon(icon, color: Colors.white54, size: 22),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color darkBlue = Color(0xFF0F2137);

  String _selectedRole = 'PLAYER';

  void _onContinue() {
    Navigator.pushNamed(context, '/register', arguments: _selectedRole);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              const Text(
                'MERCATO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: primaryYellow,
                  
                ),
              ),
              const SizedBox(height: 8),
                 const Text(
                'Choisissez votre profil pour personnaliser votre expérience.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 10),

             
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                   
                    _RoleImageCard(
                      title: 'Showcase your\ntalent',
                      buttonLabel: 'Player',
                      imageUrl: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=800',
                      isSelected: _selectedRole == 'PLAYER',
                      onTap: () => setState(() => _selectedRole = 'PLAYER'),
                    ),
                    const SizedBox(height: 16),

                    _RoleImageCard(
                      title: 'Find the next\nsuperstar',
                      buttonLabel: 'Scout',
                      imageUrl: 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800',
                      isSelected: _selectedRole == 'RECRUITER',
                      onTap: () => setState(() => _selectedRole = 'RECRUITER'),
                    ),
                    const SizedBox(height: 16),

                    _RoleImageCard(
                      title: 'Capture life-\nchanging moments',
                      buttonLabel: 'Fan / Videographer',
                      imageUrl: 'https://images.unsplash.com/photo-1517466787929-bc90951d0974?w=800',
                      isSelected: _selectedRole == 'USER',
                      onTap: () => setState(() => _selectedRole = 'USER'),
                    ),
                  ],
                ),
              ),


              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                      side: const BorderSide(color: primaryYellow, width: 2),
                    ),
                    shadowColor: primaryYellow.withOpacity(0.4),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

           
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "J'ai déjà un compte. ",
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/login', arguments: 'USER');
                    },
                    child: const Text(
                      'Se connecter.',
                      style: TextStyle(
                        color: primaryYellow,
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

class _RoleImageCard extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color darkBlue = Color(0xFF0F2137);

  const _RoleImageCard({
    required this.title,
    required this.buttonLabel,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 155,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
          border: isSelected ? Border.all(color: primaryYellow, width: 2.5) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryYellow.withOpacity(0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                darkBlue.withOpacity(0.4),
                darkBlue.withOpacity(0.85),
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),

            
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? primaryYellow : darkBlue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryYellow, width: 1.5),
                ),
                child: Text(
                  buttonLabel,
                  style: TextStyle(
                    color: isSelected ? darkBlue : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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