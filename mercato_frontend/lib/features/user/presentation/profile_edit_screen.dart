import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/widgets/app_text_field.dart';
import 'package:mercato_frontend/core/widgets/player_avatar_picker.dart';
import 'package:mercato_frontend/features/player/data/player_repository.dart';
import 'package:mercato_frontend/features/player/domain/player_profile_model.dart';

import '../../auth/domain/user_model.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _repository = PlayerProfileRepository(DioClient());
  final _storage = const FlutterSecureStorage();

  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  UserModel? _currentUser;
  String? _avatarUrl;

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _isLoading = true);

    try {
      final userJson = await _storage.read(key: 'user_data');
      if (userJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        _firstnameController.text = _currentUser?.firstname ?? '';
        _lastnameController.text = _currentUser?.lastname ?? '';
        _emailController.text = _currentUser?.email ?? '';
        _phoneController.text = _currentUser?.phone ?? '';
        _avatarUrl = _currentUser?.Profile_image;
      }

      try {
        final profile = await _repository.getMe();
        _cityController.text = profile.city ?? '';
        _countryController.text = profile.country ?? '';
      } on DioException catch (e) {
        // Pas encore de profil joueur (ex : simple "fan") : rien à préremplir.
        if (e.response?.statusCode != 404) rethrow;
      }
    } catch (_) {
      // Silencieux : l'utilisateur pourra quand même éditer
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAvatarUpdated(String newUrl) async {
    setState(() => _avatarUrl = newUrl);

    final userJson = await _storage.read(key: 'user_data');
    if (userJson == null) return;

    final currentUser = UserModel.fromJson(jsonDecode(userJson));
    final updatedUser = UserModel(
      id: currentUser.id,
      lastname: currentUser.lastname,
      firstname: currentUser.firstname,
      email: currentUser.email,
      phone: currentUser.phone,
      role: currentUser.role,
      Profile_image: newUrl,
    );

    await _storage.write(
      key: 'user_data',
      value: jsonEncode(updatedUser.toJson()),
    );
  }

  Future<void> _handleSave() async {
    if (_firstnameController.text.trim().isEmpty ||
        _lastnameController.text.trim().isEmpty) {
      _showSnackBar(
        message: 'Le prénom et le nom sont obligatoires',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profile = PlayerProfileModel(
        userId: _currentUser?.id ?? 0,
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
      );
      await _repository.updateMe(profile);

      if (_currentUser != null) {
        final updatedUser = UserModel(
          id: _currentUser!.id,
          firstname: _firstnameController.text.trim(),
          lastname: _lastnameController.text.trim(),
          email: _currentUser!.email,
          phone: _phoneController.text.trim(),
          role: _currentUser!.role,
          Profile_image: _avatarUrl,
        );
        await _storage.write(
          key: 'user_data',
          value: jsonEncode(updatedUser.toJson()),
        );
      }

      if (!mounted) return;

      _showSnackBar(message: 'Profil mis à jour avec succès !', isError: false);

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        message: 'Erreur lors de l\'enregistrement du profil',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Affiche un snackbar en haut de l'écran.
  void _showSnackBar({required String message, required bool isError}) {
    if (isError) {
      AppSnackbar.error(context, message);
    } else {
      AppSnackbar.success(context, message);
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

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colors.surface,
        titleSpacing: 12,
        toolbarHeight: 64,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.icon, size: 18),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'MODIFIER LE PROFILE',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: context.weight(FontWeight.w700),
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: PlayerAvatarPicker(
                  initialAvatarUrl: _avatarUrl,
                  onAvatarUpdated: _handleAvatarUpdated,
                ),
              ),
              const SizedBox(height: 32),

              AppTextField(
                controller: _firstnameController,
                label: 'Prénom',
                icon: Icons.person_outline_rounded,
                required: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _lastnameController,
                label: 'Nom',
                icon: Icons.badge_outlined,
                required: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: 'Téléphone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _cityController,
                label: 'Ville',
                icon: Icons.location_city_outlined,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _countryController,
                label: 'Pays',
                icon: Icons.public_rounded,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.textPrimary,
                    foregroundColor: colors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: AppLoader(
                            size: 20,
                            color: AppColors.accentOrange,
                          ),
                        )
                      : Text(
                          'Enregistrer',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: context.weight(FontWeight.w600),
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
