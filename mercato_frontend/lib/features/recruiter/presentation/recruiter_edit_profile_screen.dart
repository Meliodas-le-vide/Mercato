import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/widgets/app_text_field.dart';
import 'package:mercato_frontend/core/widgets/gold_button.dart';
import 'package:mercato_frontend/core/widgets/player_avatar_picker.dart';
import 'package:mercato_frontend/features/auth/domain/user_model.dart';
import 'package:mercato_frontend/features/recruiter/data/recruiter_profile_repository.dart';
import 'package:mercato_frontend/features/recruiter/domain/recruiter_labels.dart';
import 'package:mercato_frontend/features/recruiter/domain/recruiter_profile_model.dart';

class RecruiterEditProfileScreen extends StatefulWidget {
  const RecruiterEditProfileScreen({super.key});

  @override
  State<RecruiterEditProfileScreen> createState() =>
      _RecruiterEditProfileScreenState();
}

class _RecruiterEditProfileScreenState
    extends State<RecruiterEditProfileScreen> {
  final _repository = RecruiterProfileRepository(DioClient());
  final _storage = const FlutterSecureStorage();

  final _organizationNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _recruitmentZoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _licenseController = TextEditingController();

  String? _selectedOrganizationType;
  String? _avatarUrl;
  String? _identityDocumentUrl;
  RecruiterVerificationStatus _status = RecruiterVerificationStatus.pending;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingDocument = false;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _organizationNameController.dispose();
    _jobTitleController.dispose();
    _recruitmentZoneController.dispose();
    _bioController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final profile = await _repository.getMe();
      if (!mounted) return;
      setState(() {
        _organizationNameController.text = profile.organizationName ?? '';
        _jobTitleController.text = profile.jobTitle ?? '';
        _recruitmentZoneController.text = profile.recruitmentZone ?? '';
        _bioController.text = profile.bio ?? '';
        _selectedOrganizationType = profile.organizationType;
        _licenseController.text = profile.licenseNumber ?? '';
        _identityDocumentUrl = profile.identityDocumentUrl;
        _status = profile.verificationStatus;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _organizationNameController.text = '';
        _jobTitleController.text = '';
        _recruitmentZoneController.text = '';
        _bioController.text = '';
        _licenseController.text = '';
        _selectedOrganizationType = null;
        _identityDocumentUrl = null;
        _status = RecruiterVerificationStatus.pending;
      });
    }

    try {
      final userJson = await _storage.read(key: 'user_data');
      if (userJson != null && mounted) {
        final user = UserModel.fromJson(jsonDecode(userJson));
        setState(() => _avatarUrl = user.Profile_image);
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

  Future<void> _pickAndUploadDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result.isEmpty) return;
    final filePath = result.first.path;
    if (filePath == null) return;

    setState(() => _isUploadingDocument = true);

    try {
      final uploadedUrl = await _repository.uploadKycDocument(filePath);

      if (!mounted) return;
      setState(() {
        _identityDocumentUrl = uploadedUrl;
      });

      _showSnackBar(
        message: 'Document téléversé avec succès !',
        isError: false,
      );
    } catch (e) {
      debugPrint('Erreur upload KYC: $e');
      if (mounted) {
        _showSnackBar(
          message: 'Échec du téléversement du document.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingDocument = false);
    }
  }

  Future<void> _handleSave() async {
    if (_organizationNameController.text.trim().isEmpty ||
        _selectedOrganizationType == null ||
        _jobTitleController.text.trim().isEmpty) {
      _showSnackBar(
        message: 'Le nom, le type de structure et le poste sont obligatoires.',
        isError: true,
      );
      return;
    }

    if (_avatarUrl == null) {
      _showSnackBar(
        message: 'Veuillez ajouter une photo de profil.',
        isError: true,
      );
      return;
    }

    if (_identityDocumentUrl == null ||
        _licenseController.text.trim().isEmpty) {
      _showSnackBar(
        message: 'Le numéro de licence et la pièce d\'identité sont requis pour la vérification KYC.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profile = RecruiterProfileModel(
        userId: 0,
        organizationName: _organizationNameController.text.trim(),
        organizationType: _selectedOrganizationType,
        jobTitle: _jobTitleController.text.trim().isEmpty
            ? null
            : _jobTitleController.text.trim(),
        recruitmentZone: _recruitmentZoneController.text.trim().isEmpty
            ? null
            : _recruitmentZoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        licenseNumber: _licenseController.text.trim().isEmpty
            ? null
            : _licenseController.text.trim(),
        identityDocumentUrl: _identityDocumentUrl,
      );

      await _repository.updateMe(profile);

      if (!mounted) return;

      _showSnackBar(
        message: 'Profil et documents mis à jour !',
        isError: false,
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Erreur save profile recruteur: $e');
      if (!mounted) return;
      _showSnackBar(
        message: 'Erreur lors de l\'enregistrement du profil.',
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
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.icon,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'PROFILE RECRUTEUR ',
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

              _KycStatusBanner(status: _status),
              const SizedBox(height: 24),

              Center(
                child: PlayerAvatarPicker(
                  initialAvatarUrl: _avatarUrl,
                  onAvatarUpdated: _handleAvatarUpdated,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ces informations rassurent les joueurs sur ton identité professionnelle.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              AppTextField(
                controller: _organizationNameController,
                label: 'Nom de la structure',
                hint: 'Ex : FC Abidjan Scouting',
                icon: Icons.business_outlined,
                required: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              AppDropdownField(
                label: 'Type de structure',
                icon: Icons.category_outlined,
                required: true,
                value: _selectedOrganizationType,
                options: RecruiterLabels.organizationTypes,
                onChanged: (v) => setState(() => _selectedOrganizationType = v),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _jobTitleController,
                label: 'Fonction',
                hint: 'Ex : Recruteur, Directeur sportif…',
                icon: Icons.badge_outlined,
                required: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _recruitmentZoneController,
                label: 'Zone de recrutement',
                hint: 'Ex : Afrique de l\'Ouest (optionnel)',
                icon: Icons.public_rounded,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _licenseController,
                label: 'N° de licence FIFA / SIRET / RCS',
                hint: 'Ex : 12345-FIFA-2024',
                icon: Icons.verified_user_outlined,
                required: true,
              ),
              const SizedBox(height: 16),
              AppPickerField(
                label: 'Pièce justificative',
                required: true,
                icon: _identityDocumentUrl != null
                    ? Icons.check_circle_rounded
                    : Icons.upload_file_rounded,
                hint: 'Ajouter un document',
                value: _isUploadingDocument
                    ? 'Envoi en cours…'
                    : (_identityDocumentUrl != null
                          ? 'Document téléversé'
                          : null),
                trailingIcon: _identityDocumentUrl != null
                    ? Icons.edit_outlined
                    : Icons.add_rounded,
                onTap: _isUploadingDocument ? () {} : _pickAndUploadDocument,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _bioController,
                label: 'Bio',
                hint: 'Présente ta structure et ce que tu recherches…',
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // ============================================================
              // BOUTONS
              // ============================================================
              SizedBox(
                width: double.infinity,
                child: GoldButton(
                  height: 52,
                  fontSize: 15,
                  icon: Icons.check_rounded,
                  label: 'Enregistrer',
                  loading: _isSaving,
                  onPressed: _isSaving ? null : _handleSave,
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

// ============================================================
// BANNIÈRE DE STATUT KYC (sobre, avec tes couleurs)
// ============================================================

class _KycStatusBanner extends StatelessWidget {
  final RecruiterVerificationStatus status;

  const _KycStatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    late final Color color;
    late final String title;
    late final String message;
    late final IconData icon;

    switch (status) {
      case RecruiterVerificationStatus.verified:
        color = AppColors.success;
        title = 'Compte vérifié';
        message =
            'Tu peux contacter librement tous les joueurs de la plateforme.';
        icon = Icons.verified_rounded;
        break;
      case RecruiterVerificationStatus.rejected:
        color = AppColors.error;
        title = 'Dossier refusé';
        message =
            'Mets à jour tes pièces justificatives et resoumets ton dossier.';
        icon = Icons.cancel_rounded;
        break;
      case RecruiterVerificationStatus.pending:
        color = AppColors.warning;
        title = 'Vérification en cours';
        message = 'Soumets ta licence et ta pièce d\'identité pour finaliser ton compte.';
        icon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------- Icône (dans un cercle) --------
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),

          // -------- Texte --------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: context.weight(FontWeight.w700),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
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
      ),
    );
  }
}
