import 'package:flutter/material.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';

class PlayerResultCard extends StatelessWidget {
  final PlayerSearchResult player;
  final VoidCallback? onTapViewProfile;

  const PlayerResultCard({
    super.key,
    required this.player,
    this.onTapViewProfile,
  });

  static const Color darkBlue = Color(0xFF0F2137);
  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color surfaceDark = Color(0xFF162A45);

  @override
  Widget build(BuildContext context) {
    final hasImage = player.user.Profile_image != null && player.user.Profile_image!.isNotEmpty;
    final positionText = player.profile.position ?? 'N/C';
    final clubText = player.profile.currentClub ?? 'Sans club';
    final cityText = player.profile.city;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: darkBlue.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: darkBlue.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTapViewProfile,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar avec bordure jaune
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryYellow, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: darkBlue,
                        backgroundImage: hasImage ? NetworkImage(player.user.Profile_image!) : null,
                        child: !hasImage
                            ? Text(
                                player.fullName.isNotEmpty ? player.fullName[0].toUpperCase() : 'J',
                                style: const TextStyle(
                                  color: primaryYellow,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Informations joueur
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  player.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: darkBlue,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Badge Position
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: darkBlue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  positionText.toUpperCase(),
                                  style: const TextStyle(
                                    color: primaryYellow,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          
                          // Ligne Club & Ville
                          Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  clubText,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          // Informations secondaires (Âge, Ville)
                          Wrap(
                            spacing: 12,
                            children: [
                              if (player.age != null)
                                Text(
                                  '${player.age} ans',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              if (cityText != null && cityText.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade600),
                                    const SizedBox(width: 2),
                                    Text(
                                      cityText,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Bouton d'action bas de carte
                Container(
                  width: double.infinity,
                  height: 38,
                  decoration: BoxDecoration(
                    color: darkBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.account_circle_outlined, size: 16, color: primaryYellow),
                      SizedBox(width: 8),
                      Text(
                        'VOIR LE PROFIL',
                        style: TextStyle(
                          color: primaryYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: primaryYellow),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}