import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iconsax/iconsax.dart';

import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/theme/theme_controller.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/widgets/app_surface.dart';
import 'package:mercato_frontend/features/auth/domain/user_model.dart';
import 'package:mercato_frontend/features/player/data/player_repository.dart';
import 'package:mercato_frontend/features/player/domain/player_profile_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  final _profileRepository = PlayerProfileRepository(DioClient());

  UserModel? _user;
  PlayerProfileModel? profile;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userJson = await _storage.read(key: 'user_data');
      if (userJson != null) {
        _user = UserModel.fromJson(jsonDecode(userJson));
      }

      try {
        profile = await _profileRepository.getMe();
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          profile = null;
        } else {
          rethrow;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Erreur lors du chargement des données.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editProfile() async {
    final updated = await Navigator.pushNamed(context, AppRoutes.edit);
    if (updated == true) _loadUserData();
  }

  void _becomePlayer() {
    Navigator.pushNamed(context, AppRoutes.completeProfile);
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'PLAYER':
        return 'Joueur';
      case 'RECRUITER':
        return 'Recruteur';
      case 'CLUB_AGENT':
        return 'Agent de club';
      default:
        return 'Membre';
    }
  }

  Future<void> _logout() async {
    final colors = context.colors;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Déconnexion',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: context.weight(FontWeight.w700),
          ),
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                fontWeight: context.weight(FontWeight.w600),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Se déconnecter',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: context.weight(FontWeight.w700),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.deleteAll();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(child: AppLoader()),
      );
    }

    final canBecomePlayer = _user?.role == 'USER';
    final fullName = '${_user?.firstname ?? ''} ${_user?.lastname ?? ''}'
        .trim();
    final roleLabel = _roleLabel(_user?.role);

    return HomoraPage(
      child: RefreshIndicator(
        color: AppColors.accentOrange,
        onRefresh: _loadUserData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'PROFILE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: context.weight(FontWeight.w900),
                      letterSpacing: -0.8,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(
                      Iconsax.setting_2,
                      size: 20,
                      color: colors.icon,
                    ),
                  ),
                ),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _errorMessage!),
            ],

            const SizedBox(height: 20),

            AppSurface(
              radius: 24,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentOrange.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: SizedBox(
                        width: 68,
                        height: 68,
                        child: _ProfileAvatar(
                          imageUrl: _user?.fullProfileImageUrl,
                          size: 68,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isEmpty ? 'Utilisateur' : fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: context.weight(FontWeight.w900),
                            letterSpacing: -0.3,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          roleLabel,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _user?.email ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.success,
                              fontWeight: context.weight(FontWeight.w700),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _editProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Modifier',
                        style: TextStyle(
                          fontWeight: context.weight(FontWeight.w800),
                          fontSize: 12,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _Stat(value: profile?.city ?? '—', label: 'Ville'),
              ],
            ),

            const SizedBox(height: 28),

            _SectionTitle(label: 'Compte'),
            const SizedBox(height: 12),
            AppSurface(
              radius: 22,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  _tile(
                    Iconsax.user_edit,
                    'Modifier mes informations',
                    onTap: _editProfile,
                  ),
                  _divider(),
                  if (canBecomePlayer) ...[
                    _tile(
                      Iconsax.user_tag,
                      'Devenir joueur',
                      onTap: _becomePlayer,
                    ),
                    _divider(),
                  ],
                  _tile(
                    Icons.card_giftcard_rounded,
                    'Cadaeaux',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -------- PRÉFÉRENCES --------
            _SectionTitle(label: 'Préférences'),
            const SizedBox(height: 12),
            AppSurface(
              radius: 22,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _ThemeSwitchTile(),
            ),

            const SizedBox(height: 20),

            // -------- LOGOUT --------
            AppSurface(
              radius: 22,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _tile(
                Iconsax.logout,
                'Se déconnecter',
                onTap: _logout,
                danger: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    final colors = context.colors;
    return Divider(height: 1, indent: 54, endIndent: 16, color: colors.divider);
  }

  Widget _tile(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final colors = context.colors;
    final tint = danger ? AppColors.error : AppColors.accentOrange;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tint, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: context.weight(FontWeight.w700),
                  fontSize: 15,
                  color: danger ? AppColors.error : colors.textPrimary,
                ),
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              size: 18,
              color: danger ? AppColors.error : colors.iconMuted,
            ),
          ],
        ),
      ),
    );
  }
}


class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      label,
      style: TextStyle(
        fontWeight: context.weight(FontWeight.w800),
        fontSize: 16,
        color: colors.textPrimary,
      ),
    );
  }
}


class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Expanded(
      child: AppSurface(
        radius: 18,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: context.weight(FontWeight.w900),
                fontSize: 15,
                letterSpacing: -0.4,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: context.weight(FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _ProfileAvatar({required this.imageUrl, this.size = 68});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    if (!hasImage) {
      return Container(
        color: colors.surfaceVariant,
        child: Icon(Iconsax.user, size: size * 0.45, color: colors.iconMuted),
      );
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: colors.surfaceVariant,
        child: Icon(Iconsax.user, size: size * 0.45, color: colors.iconMuted),
      ),
    );
  }
}


class _ThemeSwitchTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.modeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDark ? Iconsax.moon : Iconsax.sun_1,
                  color: AppColors.accentOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Thème sombre',
                  style: TextStyle(
                    fontWeight: context.weight(FontWeight.w700),
                    fontSize: 15,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: isDark,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.accentOrange,
                onChanged: (value) => ThemeController.instance.setMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
