import 'dart:convert';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/widgets/pitch_position_picker.dart';
import 'package:mercato_frontend/core/widgets/player_avatar_picker.dart';
import 'package:mercato_frontend/features/player/data/player_repository.dart';
import 'package:mercato_frontend/features/player/domain/player_labels.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/player_profile_model.dart';
import '../../auth/domain/user_model.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
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
      // Pas de profil existant -> formulaire vide
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

  Future<bool> _isCurrentlyPlainUser() async {
    final userJson = await _storage.read(key: 'user_data');
    if (userJson == null) return false;
    return UserModel.fromJson(jsonDecode(userJson)).role == 'USER';
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

      final wasUser = await _isCurrentlyPlainUser();
      final result = await _repository.updateMe(profile);

      if (result.user != null) {
        await _storage.write(
          key: 'user_data',
          value: jsonEncode(result.user!.toJson()),
        );
        await _storage.write(key: 'user_role', value: result.user!.role);
      }

      if (!mounted) return;

      final justBecamePlayer = wasUser && result.user?.role == 'PLAYER';

      _showSnackBar(
        message: justBecamePlayer
            ? 'Bravo, tu es maintenant un joueur !'
            : 'Profil enregistré !',
        isError: false,
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.playerDashboard,
        (route) => false,
      );
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
        toolbarHeight: 64,
        // Ouvert depuis le profil → bouton retour. Ouvert à la première
        // connexion (rien derrière) → pas de retour, mais « Plus tard ».
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: colors.icon,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        titleSpacing: Navigator.canPop(context) ? 12 : 20,
        actions: [
          if (!Navigator.canPop(context))
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.playerDashboard,
                (route) => false,
              ),
              child: Text(
                'Plus tard',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ),
        ],
        title: Text(
          'Compléter le profil',
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
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Column(
                  children: [
                    PlayerAvatarPicker(
                      initialAvatarUrl: _avatarUrl,
                      onAvatarUpdated: _handleAvatarUpdated,
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
                  ],
                ),
              ),
              const SizedBox(height: 32),

              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel(label: 'Poste principal'),
                    const SizedBox(height: 8),
                    PitchPositionPicker(
                      selected: _selectedPosition,
                      onChanged: (v) => setState(() => _selectedPosition = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel(label: 'Caractéristiques'),
                    const SizedBox(height: 8),
                    _FormGroup(
                      children: [
                        _FormDropdown(
                          label: 'Pied fort',
                          hint: 'Sélectionner',
                          value: _selectedFoot,
                          options: PlayerLabels.feet,
                          onChanged: (v) => setState(() => _selectedFoot = v),
                        ),
                        _FormDropdown(
                          label: 'Niveau',
                          required: true,
                          hint: 'Sélectionner',
                          value: _selectedLevel,
                          options: PlayerLabels.levels,
                          onChanged: (v) => setState(() => _selectedLevel = v),
                        ),
                        _FormDatePicker(
                          label: 'Date de naissance',
                          required: true,
                          value: _birthDate,
                          onTap: _pickBirthDate,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel(label: 'Situation'),
                    const SizedBox(height: 8),
                    _FormGroup(
                      children: [
                        _FormField(
                          controller: _clubController,
                          label: 'Club actuel',
                          helper: 'Optionnel',
                        ),
                        _FormField(
                          controller: _cityController,
                          label: 'Ville',
                          required: true,
                          textCapitalization: TextCapitalization.words,
                        ),
                        _FormField(
                          controller: _countryController,
                          label: 'Pays',
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel(label: 'Physique'),
                    const SizedBox(height: 8),
                    _FormGroup(
                      children: [
                        _FormField(
                          controller: _heightController,
                          label: 'Taille',
                          helper: 'en cm',
                          keyboardType: TextInputType.number,
                        ),
                        _FormField(
                          controller: _weightController,
                          label: 'Poids',
                          helper: 'en kg',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 220),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel(label: 'À propos'),
                    const SizedBox(height: 8),
                    _BioField(controller: _bioController),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 260),
                child: Column(
                  children: [
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
                                  color: colors.background,
                                ),
                              )
                            : Text(
                                'Enregistrer mon profil',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: context.weight(FontWeight.w600),
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

class _FormGroup extends StatelessWidget {
  final List<Widget> children;

  const _FormGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: colors.divider,
              ),
          ],
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? helper;

  const _FormField({
    required this.controller,
    required this.label,
    this.required = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.helper,
  }) : readOnly = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelRow(label: label, required: required, helper: helper),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: TextStyle(
              color: readOnly ? colors.textTertiary : colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: '',
            ),
          ),
        ],
      ),
    );
  }
}

class _FormDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final bool required;
  final String? value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  const _FormDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelRow(label: label, required: required),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              isExpanded: true,
              dropdownColor: colors.surface,
              hint: Text(
                hint,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.iconMuted,
                size: 22,
              ),
              items: options.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        e.value,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormDatePicker extends StatelessWidget {
  final String label;
  final bool required;
  final DateTime? value;
  final VoidCallback onTap;

  const _FormDatePicker({
    required this.label,
    required this.value,
    required this.onTap,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasValue = value != null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LabelRow(label: label, required: required),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue
                        ? '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}'
                        : 'Sélectionner une date',
                    style: TextStyle(
                      color: hasValue
                          ? colors.textPrimary
                          : colors.textTertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  color: colors.iconMuted,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BioField extends StatelessWidget {
  final TextEditingController controller;

  const _BioField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelRow(label: 'Bio', helper: 'Optionnel'),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 5,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              height: 1.4,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'Parle un peu de toi, de ton parcours…',
              hintStyle: TextStyle(
                color: colors.textTertiary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  final String label;
  final bool required;
  final String? helper;

  const _LabelRow({required this.label, this.required = false, this.helper});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: context.weight(FontWeight.w600),
            letterSpacing: 0.3,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: context.weight(FontWeight.w600),
            ),
          ),
        const Spacer(),
        if (helper != null)
          Text(
            helper!,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}
