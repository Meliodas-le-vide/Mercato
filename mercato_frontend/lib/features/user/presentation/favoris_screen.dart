import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/widgets/player_result_card.dart';
import 'package:mercato_frontend/features/user/data/favorite_repository.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';


class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  final _favoriteRepository = FavoriteRepository(DioClient());

  static const Color darkBlue = Color(0xFF0F2137);
  static const Color primaryYellow = Color(0xFFFFD600);

  List<PlayerSearchResult> _favorites = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final favorites = await _favoriteRepository.getMyFavorites();
      if (mounted) setState(() => _favorites = favorites);
    } catch (e) {
      debugPrint('Erreur chargement favoris : $e');
      if (mounted) setState(() => _errorMessage = 'Impossible de charger tes favoris.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Retire immédiatement la carte de la liste si l'utilisateur la retire des favoris,
  // sans avoir à recharger tout l'écran.
  void _handleFavoriteChanged(int playerId, bool isFavorited) {
    if (!isFavorited) {
      setState(() => _favorites.removeWhere((p) => p.profile.userId == playerId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        title: const Text(
          'MES FAVORIS',
          style: TextStyle(color: primaryYellow, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: darkBlue));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadFavorites, child: const Text('Réessayer', style: TextStyle(color: darkBlue))),
          ],
        ),
      );
    }

    if (_favorites.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, color: Colors.black26, size: 40),
              SizedBox(height: 12),
              Text(
                'Tu n\'as encore ajouté aucun joueur en favori.\nExplore les profils pour en ajouter.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: darkBlue,
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final player = _favorites[index];
          return PlayerResultCard(
            player: player,
            onFavoriteChanged: (isFavorited) => _handleFavoriteChanged(player.profile.userId, isFavorited),
          );
        },
      ),
    );
  }
}