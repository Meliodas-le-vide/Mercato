import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';

class DetailScreen extends StatefulWidget {
  final PlayerSearchResult player;

  const DetailScreen({
    super.key,
    required this.player,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  static const Color darkBlue = Color(0xFF0F2137);
  static const Color primaryYellow = Color(0xFFFFD600);

  static const Map<String, String> _feetLabels = {
    'DROIT': 'Droitier',
    'GAUCHE': 'Gaucher',
    'AMBIDEXTRE': 'Ambidextre',
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final profile = player.profile;
    final user = player.user;
    final hasImage = user.Profile_image != null && user.Profile_image!.isNotEmpty;
    final hasClub = profile.currentClub != null && profile.currentClub!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: darkBlue,
      body: Stack(
        children: [
          // 1. Image de fond animée (Zoom continu)
          Positioned.fill(
            child: ScaleTransition(
              scale: _animation,
              child: hasImage
                  ? Image.network(
                      user.Profile_image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: darkBlue,
                        child: const Icon(Icons.person, size: 120, color: Colors.white24),
                      ),
                    )
                  : Container(
                      color: darkBlue,
                      child: const Icon(Icons.person, size: 120, color: Colors.white24),
                    ),
            ),
          ),

          // 2. Dégradé sombre pour lisibilité
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.9),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // 3. Bouton Retour en haut à gauche
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),

          // 4. Informations dynamiques du joueur
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Poste + Club
                  FadeInDown(
                    duration: const Duration(milliseconds: 500),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryYellow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (profile.position ?? 'POSTE N/C').toUpperCase(),
                            style: const TextStyle(
                              color: darkBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${profile.currentClub ?? "Sans club"}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nom complet
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      player.fullName,
                      style: TextStyle(
                        fontSize: 36,
                        height: 1.1,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Ville & Âge / Bio
                  FadeInDown(
                    duration: const Duration(milliseconds: 700),
                    delay: const Duration(milliseconds: 150),
                    child: Text(
                      '${player.age != null ? "${player.age} ans" : ""} ${profile.city != null ? "• ${profile.city}" : ""}',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    FadeInDown(
                      duration: const Duration(milliseconds: 750),
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        profile.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white60,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Badges Statistiques (Buts, Matchs, Passe dé, etc.)
                  // Affichés uniquement si le joueur est rattaché à un club.
                  if (hasClub) ...[
                    Row(
                      children: [
                        Expanded(
                          child: FadeInLeft(
                            duration: const Duration(milliseconds: 750),
                            delay: const Duration(milliseconds: 200),
                            child: _buildStatBadge(
                              title: '${profile.goals}',
                              label: 'Buts',
                              icon: Icons.sports_soccer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 750),
                            delay: const Duration(milliseconds: 250),
                            child: _buildStatBadge(
                              title: '${profile.matchesPlayed}',
                              label: 'Matchs',
                              icon: Icons.sports,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FadeInRight(
                            duration: const Duration(milliseconds: 750),
                            delay: const Duration(milliseconds: 300),
                            child: _buildStatBadge(
                              title: '${profile.assists}',
                              label: 'Passes D.',
                              icon: Icons.handshake_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Autres informations du profil
                  FadeInUp(
                    duration: const Duration(milliseconds: 750),
                    delay: const Duration(milliseconds: 300),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (profile.height != null)
                          _buildInfoChip(icon: Icons.height, label: '${profile.height} cm'),
                        if (profile.weight != null)
                          _buildInfoChip(icon: Icons.monitor_weight_outlined, label: '${profile.weight} kg'),
                        if (profile.strongFoot != null)
                          _buildInfoChip(
                            icon: Icons.sports_soccer_outlined,
                            label: _feetLabels[profile.strongFoot] ?? profile.strongFoot!,
                          ),
                        if (profile.city != null && profile.city!.isNotEmpty)
                          _buildInfoChip(icon: Icons.location_on_outlined, label: profile.city!),
                        if (profile.country != null && profile.country!.isNotEmpty)
                          _buildInfoChip(icon: Icons.flag_outlined, label: profile.country!),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required String title,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryYellow, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryYellow, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}