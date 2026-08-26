import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/features/user/data/favorite_repository.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';

class PlayerResultCard extends StatefulWidget {
  final PlayerSearchResult player;

  /// Appelé quand l'état favori change, utile pour retirer la carte
  /// de la liste "Favoris" en temps réel sans recharger tout l'écran.
  final void Function(bool isFavorited)? onFavoriteChanged;

  const PlayerResultCard({
    super.key,
    required this.player,
    this.onFavoriteChanged,
  });

  @override
  State<PlayerResultCard> createState() => _PlayerResultCardState();
}

class _PlayerResultCardState extends State<PlayerResultCard> {
  final _favoriteRepository = FavoriteRepository(DioClient());

  static const Color darkBlue = Color(0xFF0F2137);
  static const Color primaryYellow = Color(0xFFFFD600);

  late bool _isFavorited;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.player.isFavorited;
  }

  Future<void> _toggleFavorite() async {
    if (_isToggling) return; // évite le spam pendant la requête

    final previous = _isFavorited;
    setState(() {
      _isFavorited = !_isFavorited;
      _isToggling = true;
    });

    try {
      final result = await _favoriteRepository.toggleFavorite(widget.player.profile.userId);
      if (mounted) {
        setState(() => _isFavorited = result);
        widget.onFavoriteChanged?.call(result);
      }
    } catch (e) {
      debugPrint('Erreur toggleFavorite : $e');
      if (mounted) {
        setState(() => _isFavorited = previous); // rollback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de mettre à jour les favoris.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final profile = player.profile;
    final user = player.user;
    final age = player.age;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white10,
            backgroundImage: user.Profile_image != null ? NetworkImage(user.Profile_image!) : null,
            child: user.Profile_image == null
                ? const Icon(Icons.person, color: Colors.white54, size: 28)
                : null,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.fullName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (profile.position != null) _buildPill(profile.position!.toUpperCase()),
                    if (age != null) _buildPill('$age ans'),
                    if (profile.level != null) _buildPill(profile.level!),
                  ],
                ),
                const SizedBox(height: 4),
                if (profile.city != null || profile.currentClub != null)
                  Text(
                    [profile.currentClub, profile.city].where((s) => s != null && s.isNotEmpty).join(' • '),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          IconButton(
            icon: _isToggling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryYellow),
                  )
                : Icon(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorited ? primaryYellow : Colors.white54,
                  ),
            onPressed: _isToggling ? null : _toggleFavorite,
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}