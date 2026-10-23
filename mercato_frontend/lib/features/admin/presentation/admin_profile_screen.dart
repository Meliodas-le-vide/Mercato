import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/theme/theme_controller.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/widgets/glow_avatar.dart';
import 'package:mercato_frontend/features/auth/domain/user_model.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _storage = const FlutterSecureStorage();
  final DioClient _dioClient = DioClient();

  UserModel? _user;
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
      // 1. Chargement rapide depuis le cache local
      final userJson = await _storage.read(key: 'user_data');
      if (userJson != null) {
        _user = UserModel.fromJson(jsonDecode(userJson));
      }

      // 2. Récupération des données réseau fraîches pour l'Admin (ex: /auth/me ou /users/me)
      final response = await _dioClient.dio.get('/auth/me');
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['data'] ?? response.data;
        _user = UserModel.fromJson(userData);
        await _storage.write(key: 'user_data', value: jsonEncode(userData));
      }
    } catch (e) {
      if (mounted && _user == null) {
        setState(
          () => _errorMessage =
              'Erreur lors du chargement du profil administrateur.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _editProfile() async {
    final updated = await Navigator.pushNamed(context, AppRoutes.edit);
    if (updated == true) _loadUserData();
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'ADMIN':
        return 'Administrateur';
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
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: semantic.surface,
        title: Text(
          'Déconnexion',
          style: TextStyle(
            color: semantic.textPrimary,
            fontSize: 18,
            fontWeight: context.weight(FontWeight.bold),
          ),
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter du compte Administrateur ?',
          style: TextStyle(color: semantic.textSecondary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: semantic.textSecondary, fontSize: 18),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Se déconnecter',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: context.weight(FontWeight.bold),
                fontSize: 18,
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
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: semantic.background,
        body: const Center(child: AppLoader(size: 90)),
      );
    }

    return Scaffold(
      backgroundColor: semantic.background,
      appBar: AppBar(
        title: Text(
          'PROFILE ADMINISTRATEUR',
          style: TextStyle(
            letterSpacing: 1.1,
            fontSize: 18,
            fontWeight: context.weight(FontWeight.bold),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryYellow,
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: semantic.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GlowAvatar(
                          radius: 50,
                          imageUrl: _user?.fullProfileImageUrl,
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: GestureDetector(
                            onTap: _editProfile,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: semantic.surface,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: AppColors.backgroundDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${_user?.firstname ?? ''} ${_user?.lastname ?? ''}'
                          .toUpperCase(),
                      style: TextStyle(
                        color: semantic.textPrimary,
                        fontSize: 19,
                        fontWeight: context.weight(FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Badge Rôle Admin
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _roleLabel(_user?.role).toUpperCase(),
                        style: TextStyle(
                          color: AppColors.primaryYellow,
                          fontSize: 18,
                          fontWeight: context.weight(FontWeight.bold),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if ((_user?.email ?? '').isNotEmpty)
                      _buildContactRow(
                        semantic,
                        icon: Icons.email_outlined,
                        text: _user!.email,
                      ),
                    if ((_user?.phone ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildContactRow(
                        semantic,
                        icon: Icons.phone_outlined,
                        text: _user!.phone!,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- Options de Compte ---
              _buildSectionLabel(semantic, 'COMPTE ADMIN'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: semantic.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      semantic,
                      icon: Icons.person_outline,
                      label: 'Modifier mes informations',
                      onTap: _editProfile,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- Préférences ---
              _buildSectionLabel(semantic, 'PRÉFÉRENCES'),
              const SizedBox(height: 8),
              _buildThemeToggle(semantic),

              const SizedBox(height: 28),

              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(
                  Icons.logout,
                  size: 18,
                  color: AppColors.error,
                ),
                label: Text(
                  'SE DÉCONNECTER',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 18,
                    fontWeight: context.weight(FontWeight.bold),
                    letterSpacing: 0.3,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(
    AppSemanticColors semantic, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: semantic.textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: semantic.textSecondary, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(AppSemanticColors semantic, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: semantic.textSecondary,
          fontSize: 16,
          fontWeight: context.weight(FontWeight.bold),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    AppSemanticColors semantic, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? semantic.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: semantic.textPrimary,
                  fontSize: 18,
                  fontWeight: context.weight(FontWeight.w600),
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: semantic.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(AppSemanticColors semantic) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.modeNotifier,
      builder: (context, mode, _) {
        final isDark = mode == ThemeMode.dark;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: semantic.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: AppColors.primaryYellow,
            ),
            title: Text(
              'Thème sombre',
              style: TextStyle(
                color: semantic.textPrimary,
                fontSize: 18,
                fontWeight: context.weight(FontWeight.w600),
              ),
            ),
            activeThumbColor: AppColors.primaryYellow,
            value: isDark,
            onChanged: (value) => ThemeController.instance.setMode(
              value ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
        );
      },
    );
  }
}
