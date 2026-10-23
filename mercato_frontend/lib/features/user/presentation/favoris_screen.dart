import 'package:flutter/material.dart';
import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/widgets/player_result_card.dart';
import 'package:mercato_frontend/features/user/data/favorite_repository.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';
import 'package:mercato_frontend/features/user/presentation/explore_screen.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => FavorisScreenState();
}

class FavorisScreenState extends State<FavorisScreen> {
  final _favoriteRepository = FavoriteRepository(DioClient());
  final _scrollController = ScrollController();

  List<PlayerSearchResult> _favorites = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (maxScrollExtent > 0 &&
        _scrollController.position.pixels >= maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> refresh() => _loadFavorites();

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _favoriteRepository.getMyFavorites(page: 1);
      if (mounted) {
        setState(() {
          _favorites = result.items;
          _page = result.page;
          _hasMore = result.hasMore && result.items.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement favoris : $e');
      if (mounted) {
        setState(() => _errorMessage = 'Impossible de charger tes favoris.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final result = await _favoriteRepository.getMyFavorites(page: _page + 1);
      if (mounted) {
        setState(() {
          _favorites.addAll(result.items);
          _page = result.page;
          _hasMore = result.hasMore && result.items.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement favoris : $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colors.surface,
        titleSpacing: 20,
        toolbarHeight: 64,
        title: Text(
          'FAVORIS',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: context.weight(FontWeight.w700),
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SafeArea(top: false, child: _buildBody(colors)),
    );
  }

  Widget _buildBody(AppSemanticColors colors) {
    // -------- Loading initial --------
    if (_isLoading) {
      return const Center(child: AppLoader());
    }

    if (_errorMessage != null) {
      return _StateView(
        icon: Icons.error_outline_rounded,
        title: 'Oups…',
        subtitle: _errorMessage!,
        actionLabel: 'Réessayer',
        onAction: _loadFavorites,
      );
    }

    // -------- Empty state --------
    if (_favorites.isEmpty) {
      return _StateView(
        icon: Icons.favorite_border_rounded,
        title: 'Aucun favori pour l\'instant',
        subtitle: 'Explore les profils et ajoute des joueurs en favoris pour les retrouver ici.',
        actionLabel: 'Explorer les joueurs',
        onAction: () {
          Navigator.push(context,MaterialPageRoute(builder: (context) =>ExploreScreen()));
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.accentOrange,
      onRefresh: _loadFavorites,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: _favorites.length + 1 + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {

          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                '${_favorites.length} joueur${_favorites.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          // -------- Footer loader --------
          if (index == _favorites.length + 1) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: AppLoader(size: 22)),
            );
          }

          // -------- Carte joueur --------
          final player = _favorites[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: PlayerResultCard(
              player: player,
              onTapViewProfile: () => Navigator.pushNamed(
                context,
                AppRoutes.detail,
                arguments: player,
              ),
              onFavoriteToggled: (isFavorited) {
                if (!isFavorited) {
                  setState(
                    () => _favorites.removeWhere(
                      (p) => p.user.id == player.user.id,
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}



class _StateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateView({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: colors.iconMuted),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: context.weight(FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: colors.surfaceVariant,
                ),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: context.weight(FontWeight.w600),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
