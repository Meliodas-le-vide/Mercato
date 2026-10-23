import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/theme/theme_controller.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/widgets/glow_avatar.dart';
import 'package:mercato_frontend/core/widgets/gold_button.dart';
import 'package:mercato_frontend/features/auth/domain/user_model.dart';
import 'package:mercato_frontend/features/recruiter/data/recruiter_profile_repository.dart';
import 'package:mercato_frontend/features/recruiter/domain/recruiter_labels.dart';
import 'package:mercato_frontend/features/recruiter/domain/recruiter_profile_model.dart';

class RecruiterProfileScreen extends StatefulWidget {
  const RecruiterProfileScreen({super.key});

  @override
  State<RecruiterProfileScreen> createState() => _RecruiterProfileScreenState();
}

class _RecruiterProfileScreenState extends State<RecruiterProfileScreen> {
  final _storage = const FlutterSecureStorage();
  final _profileRepository = RecruiterProfileRepository(DioClient());

  UserModel? _user;
  RecruiterProfileModel? _profile;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userJson = await _storage.read(key: 'user_data');
      if (userJson != null) {
        _user = UserModel.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      debugPrint('Erreur parsing user_data: $e');
    }

    try {
      _profile = await _profileRepository.getMe();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _profile = null;
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Erreur réseau lors de la récupération du profil.';
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement profil recruteur: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur inattendue lors du chargement.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.pushNamed(
      context,
      AppRoutes.recruiterEditProfile,
    );
    if (updated == true) _loadData();
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

    final isConfigured = _profile?.isProfileComplete ?? false;

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
          'PROFILE',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: context.weight(FontWeight.w700),
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.accentOrange,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============================================================
              // ERREUR
              // ============================================================
              if (_errorMessage != null) ...[
                _ErrorBanner(message: _errorMessage!, onRetry: _loadData),
                const SizedBox(height: 20),
              ],

              // ============================================================
              // EN-TÊTE
              // ============================================================
              _ProfileHeader(
                user: _user,
                profile: _profile,
                isConfigured: isConfigured,
                onEdit: _editProfile,
              ),

              const SizedBox(height: 32),

              // ============================================================
              // STRUCTURE
              // ============================================================
              if (isConfigured) ...[
                _SectionLabel(label: 'Structure'),
                const SizedBox(height: 12),
                _InfoCard(
                  children: [
                    _DetailRow(
                      label: 'Organisation',
                      value: _profile?.organizationName ?? 'Non renseigné',
                    ),
                    _DetailRow(
                      label: 'Type',
                      value: _profile?.organizationType != null
                          ? RecruiterLabels.labelFor(
                              RecruiterLabels.organizationTypes,
                              _profile?.organizationType,
                            )
                          : 'Non renseigné',
                    ),
                    _DetailRow(
                      label: 'Fonction',
                      value: _profile?.jobTitle ?? 'Non renseigné',
                    ),
                    _DetailRow(
                      label: 'Zone de recrutement',
                      value: _profile?.recruitmentZone ?? 'Non renseigné',
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // ============================================================
              // CONTACT
              // ============================================================
              _SectionLabel(label: 'Contact'),
              const SizedBox(height: 12),
              _InfoCard(
                children: [
                  _DetailRow(
                    label: 'Email',
                    value: _user?.email ?? 'Non renseigné',
                  ),
                  _DetailRow(
                    label: 'Téléphone',
                    value: _user?.phone ?? 'Non renseigné',
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ============================================================
              // PRÉFÉRENCES
              // ============================================================
              _SectionLabel(label: 'Préférences'),
              const SizedBox(height: 12),
              _ThemeToggle(),
              const SizedBox(height: 24),

              // ============================================================
              // DÉCONNEXION
              // ============================================================
              _LogoutButton(onTap: _logout),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EN-TÊTE (avatar + nom + badges + bio + CTA)
// ============================================================

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;
  final RecruiterProfileModel? profile;
  final bool isConfigured;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.user,
    required this.profile,
    required this.isConfigured,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final fullName = '${user?.firstname ?? ''} ${user?.lastname ?? ''}'.trim();

    return Column(
      children: [
        // -------- Avatar --------
        GlowAvatar(radius: 48, imageUrl: user?.fullProfileImageUrl),
        const SizedBox(height: 16),

        // -------- Nom (casse normale) --------
        Text(
          fullName.isEmpty ? 'Utilisateur' : fullName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: context.weight(FontWeight.w700),
            letterSpacing: -0.4,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),

        // -------- Rôle (discret) --------
        Text(
          'Recruteur',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // -------- Badges empilés discrètement --------
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            // Type d'organisation
            if (isConfigured && profile?.organizationType != null)
              _StatusBadge(
                label: RecruiterLabels.labelFor(
                  RecruiterLabels.organizationTypes,
                  profile?.organizationType,
                ),
                color: colors.textSecondary,
              ),
            // Statut de vérification
            if (profile != null)
              _VerificationBadge(status: profile!.verificationStatus),
          ],
        ),

        // -------- Bio / org --------
        if (isConfigured && profile?.bio?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          Text(
            profile!.bio!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ] else if (!isConfigured) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentOrange.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colors.iconMuted,
                  size: 22,
                ),
                const SizedBox(height: 8),
                Text(
                  'Profil incomplet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: context.weight(FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complète tes informations pour que les joueurs te fassent confiance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],

        // -------- Message de vérification --------
        if (isConfigured &&
            profile?.verificationStatus !=
                RecruiterVerificationStatus.verified) ...[
          const SizedBox(height: 12),
          Text(
            profile?.verificationStatus == RecruiterVerificationStatus.rejected
                ? 'Ta demande de vérification a été refusée. Contacte le support pour en savoir plus.'
                : 'Un admin doit valider ton organisation avant que tu puisses contacter des joueurs.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],

        const SizedBox(height: 20),

        // -------- CTA (GoldButton conservé) --------
        SizedBox(
          width: double.infinity,
          child: GoldButton(
            height: 46,
            fontSize: 14,
            icon: isConfigured ? Icons.edit_outlined : Icons.flash_on,
            label: isConfigured ? 'Éditer le profil' : 'Configurer le profil',
            onPressed: onEdit,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// BADGE DE STATUT
// ============================================================

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: context.weight(FontWeight.w600),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ============================================================
// BADGE DE VÉRIFICATION (avec ton orange/jaune/success)
// ============================================================

class _VerificationBadge extends StatelessWidget {
  final RecruiterVerificationStatus status;

  const _VerificationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    late final IconData icon;

    switch (status) {
      case RecruiterVerificationStatus.verified:
        color = AppColors.success;
        label = 'Vérifié';
        icon = Icons.verified_rounded;
        break;
      case RecruiterVerificationStatus.rejected:
        color = AppColors.error;
        label = 'Refusé';
        icon = Icons.cancel_rounded;
        break;
      case RecruiterVerificationStatus.pending:
        color = AppColors.warning;
        label = 'En attente';
        icon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: context.weight(FontWeight.w700),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LABEL DE SECTION
// ============================================================

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: context.weight(FontWeight.w600),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ============================================================
// CARTE INFO (avec dividers fins)
// ============================================================

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: context.weight(FontWeight.w600),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: colors.divider,
          ),
      ],
    );
  }
}

// ============================================================
// TOGGLE THÈME
// ============================================================

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.modeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Icône orange conservée
                Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  size: 20,
                  color: AppColors.accentOrange,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Thème sombre',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: isDark,
                  // Ton orange conservé
                  activeThumbColor: AppColors.accentOrange,
                  activeTrackColor: AppColors.accentOrange.withValues(
                    alpha: 0.5,
                  ),
                  inactiveThumbColor: colors.iconMuted,
                  inactiveTrackColor: colors.surfaceVariant,
                  onChanged: (value) => ThemeController.instance.setMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// BOUTON DÉCONNEXION
// ============================================================

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 20,
                color: AppColors.error,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Se déconnecter',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: context.weight(FontWeight.w600),
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

// ============================================================
// BANNIÈRE D'ERREUR
// ============================================================

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

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
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Réessayer',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: context.weight(FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
