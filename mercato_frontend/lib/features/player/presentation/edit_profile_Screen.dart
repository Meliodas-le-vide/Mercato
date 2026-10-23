import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/widgets/app_text_field.dart';
import 'package:mercato_frontend/core/widgets/gold_button.dart';
import 'package:mercato_frontend/core/widgets/pitch_position_picker.dart';
import 'package:mercato_frontend/core/widgets/player_avatar_picker.dart';
import 'package:mercato_frontend/features/player/data/player_repository.dart';
import 'package:mercato_frontend/features/player/domain/player_labels.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/player_profile_model.dart';
import '../../auth/domain/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _repository = PlayerProfileRepository(DioClient());
  final _storage = const FlutterSecureStorage();

  final _clubController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _bioController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedPosition;
  String? _selectedFoot;
  String? _selectedLevel;
  DateTime? _birthDate;
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
    _clubController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _repository.getMe();
      if (!mounted) return;
      setState(() {
        _selectedPosition = profile.position;
        _selectedFoot = profile.strongFoot;
        _selectedLevel = profile.level;
        _birthDate = profile.birthDate != null
            ? DateTime.tryParse(profile.birthDate!)
            : null;
        _clubController.text = profile.currentClub ?? '';
        _cityController.text = profile.city ?? '';
        _countryController.text = profile.country ?? '';
        _bioController.text = profile.bio ?? '';
        _heightController.text = profile.height?.toString() ?? '';
        _weightController.text = profile.weight?.toString() ?? '';
      });
    } catch (_) {
      // Cas rare : profil supprimé entre-temps -> formulaire vide
    }

    try {
      final userJson = await _storage.read(key: 'user_data');
      if (userJson != null) {
        final user = UserModel.fromJson(jsonDecode(userJson));
        if (mounted) setState(() => _avatarUrl = user.Profile_image);
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
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

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final colors = context.colors;

    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(now.year - 60),
      lastDate: DateTime(now.year - 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.accentOrange,
              brightness: Theme.of(context).brightness,
            ),
            dialogBackgroundColor: colors.surface,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (_selectedPosition == null ||
        _selectedLevel == null ||
        _birthDate == null ||
        _cityController.text.trim().isEmpty) {
      _showSnackBar(
        message: 'Poste, niveau, date de naissance et ville sont obligatoires',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profile = PlayerProfileModel(
        userId: 0,
        position: _selectedPosition,
        strongFoot: _selectedFoot,
        birthDate: _birthDate!.toIso8601String().split('T').first,
        level: _selectedLevel,
        currentClub: _clubController.text.trim().isEmpty
            ? null
            : _clubController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        height: int.tryParse(_heightController.text.trim()),
        weight: int.tryParse(_weightController.text.trim()),
      );

      await _repository.updateMe(profile);

      if (!mounted) return;

      _showSnackBar(message: 'Profil mis à jour !', isError: false);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Modifier le profil',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
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
              // ============================================================
              // PHOTO + INTRO
              // ============================================================
              Center(
                child: PlayerAvatarPicker(
                  initialAvatarUrl: _avatarUrl,
                  onAvatarUpdated: _handleAvatarUpdated,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ces informations seront visibles par les recruteurs.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // ============================================================
              // SECTION : POSTE
              // ============================================================
              Text.rich(
                TextSpan(
                  text: 'Poste principal',
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: context.weight(FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              PitchPositionPicker(
                selected: _selectedPosition,
                onChanged: (v) => setState(() => _selectedPosition = v),
              ),
              const SizedBox(height: 20),

              AppDropdownField(
                label: 'Niveau',
                icon: Icons.emoji_events_outlined,
                required: true,
                value: _selectedLevel,
                options: PlayerLabels.levels,
                onChanged: (v) => setState(() => _selectedLevel = v),
              ),
              const SizedBox(height: 16),
              AppDateField(
                label: 'Date de naissance',
                icon: Icons.cake_outlined,
                required: true,
                value: _birthDate,
                onTap: _pickBirthDate,
              ),
              const SizedBox(height: 16),
              AppDropdownField(
                label: 'Pied fort',
                icon: Icons.directions_run_rounded,
                value: _selectedFoot,
                options: PlayerLabels.feet,
                onChanged: (v) => setState(() => _selectedFoot = v),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _cityController,
                label: 'Ville',
                icon: Icons.location_city_outlined,
                required: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _countryController,
                label: 'Pays',
                icon: Icons.public_rounded,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _clubController,
                label: 'Club actuel',
                hint: 'Optionnel',
                icon: Icons.shield_outlined,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _heightController,
                      label: 'Taille (cm)',
                      hint: 'Ex : 178',
                      icon: Icons.height_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _weightController,
                      label: 'Poids (kg)',
                      hint: 'Ex : 72',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _bioController,
                label: 'Bio',
                hint: 'Parle un peu de toi, de ton parcours…',
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // ============================================================
              // TON GoldButton CONSERVÉ
              // ============================================================
              SizedBox(
                width: double.infinity,
                child: GoldButton(
                  height: 52,
                  fontSize: 15,
                  icon: Icons.check_rounded,
                  label: 'Enregistrer les modifications',
                  loading: _isSaving,
                  onPressed: _isSaving ? null : _handleSave,
                ),
              ),
              const SizedBox(height: 8),

              // ============================================================
              // ANNULER
              // ============================================================
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
