import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/features/admin/data/admin_repository.dart';
import 'package:mercato_frontend/features/admin/domain/admin_models.dart';

class AdminUsersScreen extends StatefulWidget {
  final int? currentAdminId;

  const AdminUsersScreen({super.key, this.currentAdminId});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _repository = AdminRepository(DioClient());
  final _searchController = TextEditingController();
  Timer? _debounce;

  int? _loggedInAdminId;
  bool _identityResolved = false;
  String? _roleFilter;
  List<AdminUserModel> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const Map<String?, String> _roleTabs = {
    null: 'Tous',
    'PLAYER': 'Joueurs',
    'RECRUITER': 'Recruteurs',
    'CLUB_AGENT': 'Agents',
    'USER': 'Fans',
    'ADMIN': 'Admins',
  };

  @override
  void initState() {
    super.initState();
    _loggedInAdminId = widget.currentAdminId;
    _initScreen();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  final _secureStorage = const FlutterSecureStorage();

  Future<void> _initScreen() async {
    // L'app utilise flutter_secure_storage (voir AuthRepository.login) :
    // clé 'user_data' = JSON de UserModel, clé 'access_token' = JWT.
    _loggedInAdminId ??= await _resolveLoggedInAdminId();

    debugPrint(
      '🔍 AdminUsersScreen: _loggedInAdminId résolu = $_loggedInAdminId',
    );

    _identityResolved = true;

    if (_loggedInAdminId == null) {
      debugPrint(
        'AdminUsersScreen: impossible de résoudre l\'ID de l\'admin connecté. '
        'Le badge "Vous" ne s\'affichera pas, et la suppression sera bloquée par prudence.',
      );
    }

    await _load();
  }

  /// Retrouve l'ID de l'admin connecté depuis le stockage sécurisé
  /// (voir AuthRepository.login : clés 'user_data' et 'access_token').
  Future<int?> _resolveLoggedInAdminId() async {
    // 1. Objet JSON complet sous 'user_data' (le plus fiable, écrit au login)
    final userData = await _secureStorage.read(key: 'user_data');
    if (userData != null) {
      try {
        final decoded = jsonDecode(userData);
        final id = decoded['id'];
        if (id is int) return id;
        if (id is String) return int.tryParse(id);
      } catch (_) {
        // JSON invalide, on continue avec les autres sources
      }
    }

    // 2. Repli : décoder le JWT 'access_token'
    final token = await _secureStorage.read(key: 'access_token');
    if (token != null && token.contains('.')) {
      final id = _extractIdFromJwt(token);
      if (id != null) return id;
    }

    return null;
  }

  int? _extractIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String payload = parts[1];
      payload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> claims = jsonDecode(decoded);

      final rawId = claims['id'] ?? claims['sub'] ?? claims['userId'];
      if (rawId is int) return rawId;
      if (rawId is String) return int.tryParse(rawId);
    } catch (_) {
      // Token invalide ou non-JWT, on ignore
    }
    return null;
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _repository.listUsers(
        role: _roleFilter,
        search: _searchController.text,
      );
      if (mounted) {
        setState(() {
          _users = result.items;
        });
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _errorMessage = 'Impossible de charger les utilisateurs.',
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _deleteUser(AdminUserModel user) async {
    // Garde-fou : si on n'a pas pu déterminer qui est l'admin connecté,
    // on refuse par prudence plutôt que de laisser un doute.
    if (!_identityResolved || _loggedInAdminId == null) {
      AppSnackbar.error(
        context,
        'Impossible de vérifier votre identité. Reconnectez-vous puis réessayez.',
      );
      return;
    }

    if (user.id == _loggedInAdminId) {
      AppSnackbar.error(
        context,
        'Vous ne pouvez pas supprimer votre propre compte.',
      );
      return;
    }

    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: semantic.surface,
        title: Text(
          'Supprimer l\'utilisateur ?',
          style: TextStyle(
            color: semantic.textPrimary,
            fontSize: 18,
            fontWeight: context.weight(FontWeight.bold),
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${user.fullName} ? Cette action est irréversible.',
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
              'Supprimer',
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

    if (confirmed == true) {
      try {
        await _repository.deleteUser(user.id);
        if (mounted) {
          AppSnackbar.success(context, 'Utilisateur supprimé avec succès.');
          _load();
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.error(
            context,
            'Impossible de supprimer cet utilisateur.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      backgroundColor: semantic.background,
      appBar: AppBar(
        title: Text(
          'UTILISATEURS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: context.weight(FontWeight.bold),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: semantic.textPrimary, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Rechercher par nom ou email...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),
          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _roleTabs.entries.map((entry) {
                final isSelected = _roleFilter == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (_) => setState(() {
                      _roleFilter = entry.key;
                      _load();
                    }),
                    selectedColor: AppColors.primaryYellow,
                    backgroundColor: semantic.surface,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(semantic)),
        ],
      ),
    );
  }

  Widget _buildBody(AppSemanticColors semantic) {
    if (_isLoading) return const Center(child: AppLoader());
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: AppColors.error, fontSize: 18),
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Text(
          'Aucun utilisateur trouvé.',
          style: TextStyle(color: semantic.textSecondary, fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryYellow,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final user = _users[index];
          final isCurrentAdmin = user.id == _loggedInAdminId;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: semantic.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              style: TextStyle(
                                color: semantic.textPrimary,
                                fontWeight: context.weight(FontWeight.bold),
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundDark,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.role,
                              style: TextStyle(
                                color: AppColors.primaryYellow,
                                fontSize: 12,
                                fontWeight: context.weight(FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: semantic.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isCurrentAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Vous',
                      style: TextStyle(
                        color: AppColors.primaryYellow,
                        fontWeight: context.weight(FontWeight.bold),
                        fontSize: 18,
                      ),
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 22,
                    ),
                    onPressed: () => _deleteUser(user),
                    tooltip: 'Supprimer',
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
