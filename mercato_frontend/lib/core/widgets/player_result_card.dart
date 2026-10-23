import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/state/favorite_status_bus.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/widgets/glow_avatar.dart';
import 'package:mercato_frontend/core/widgets/gold_button.dart';
import 'package:mercato_frontend/features/player/domain/player_labels.dart';
import 'package:mercato_frontend/features/user/data/favorite_repository.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';

class PlayerResultCard extends StatefulWidget {
  final PlayerSearchResult player;
  final VoidCallback? onTapViewProfile;
  final ValueChanged<bool>? onFavoriteToggled;

  const PlayerResultCard({
    super.key,
    required this.player,
    this.onTapViewProfile,
    this.onFavoriteToggled,
  });

  @override
  State<PlayerResultCard> createState() => _PlayerResultCardState();
}

class _PlayerResultCardState extends State<PlayerResultCard> {
  final _favoriteRepository = FavoriteRepository(DioClient());
  late bool _isFavorited;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.player.isFavorited;
    FavoriteStatusBus.instance.addListener(_onFavoriteStatusChanged);
  }

  @override
  void dispose() {
    FavoriteStatusBus.instance.removeListener(_onFavoriteStatusChanged);
    super.dispose();
  }

  void _onFavoriteStatusChanged() {
    final change = FavoriteStatusBus.instance.lastChange;
    if (change != null &&
        change.key == widget.player.user.id &&
        mounted &&
        change.value != _isFavorited) {
      setState(() => _isFavorited = change.value);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;

    final previous = _isFavorited;
    setState(() {
      _isFavorited = !_isFavorited;
      _isTogglingFavorite = true;
    });

    try {
      final result = await _favoriteRepository.toggleFavorite(
        widget.player.user.id,
      );
      if (!mounted) return;

      setState(() => _isFavorited = result);
      widget.onFavoriteToggled?.call(result);
      FavoriteStatusBus.instance.notify(widget.player.user.id, result);

      AppSnackbar.success(
        context,
        result
            ? '${widget.player.fullName} ajouté aux favoris'
            : '${widget.player.fullName} retiré des favoris',
      );
    } catch (e) {
      debugPrint('Erreur toggle favorite: $e');
      if (!mounted) return;
      setState(() => _isFavorited = previous);

      AppSnackbar.error(context, 'Action impossible, réessaie.');
    } finally {
      if (mounted) setState(() => _isTogglingFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final positionText = PlayerLabels.labelFor(
      PlayerLabels.positions,
      widget.player.profile.position,
    );
    final clubText = widget.player.profile.currentClub ?? 'Sans club';
    final cityText = widget.player.profile.city;

    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
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
          onTap: widget.onTapViewProfile,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'player-avatar-${widget.player.user.id}',
                      child: GlowAvatar(
                        radius: 30,
                        imageUrl: widget.player.user.Profile_image,
                        placeholder: Text(
                          widget.player.fullName.isNotEmpty
                              ? widget.player.fullName[0].toUpperCase()
                              : 'J',
                          style: TextStyle(
                            color: AppColors.accentOrange,
                            fontWeight: context.weight(FontWeight.bold),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.player.fullName,
                                  style: TextStyle(
                                    fontWeight: context.weight(FontWeight.w800),
                                    fontSize: 16,
                                    color: colors.textPrimary,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentOrange.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.accentOrange.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  positionText.toUpperCase(),
                                  style: TextStyle(
                                    color: AppColors.accentOrange,
                                    fontWeight: context.weight(FontWeight.bold),
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  clubText,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          Wrap(
                            spacing: 12,
                            children: [
                              if (widget.player.age != null)
                                Text(
                                  '${widget.player.age} ans',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              if (cityText != null && cityText.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 12,
                                      color: colors.textSecondary,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      cityText,
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),

                    _buildFavoriteButton(colors),
                  ],
                ),

                const SizedBox(height: 12),

                GoldButton(
                  height: 40,
                  icon: Icons.arrow_forward_rounded,
                  label: 'Voir le profil',
                  fontSize: 15,
                  onPressed: widget.onTapViewProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(AppSemanticColors colors) {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surfaceVariant,
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: _isTogglingFavorite
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: AppLoader(size: 14),
                )
              : Icon(
                  _isFavorited ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: _isFavorited ? AppColors.error : colors.iconMuted,
                ),
        ),
      ),
    );
  }
}
