import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/features/player/data/player_repository.dart';

class PlayerAvatarPicker extends StatefulWidget {
  final String? initialAvatarUrl;
  final ValueChanged<String> onAvatarUpdated;

  const PlayerAvatarPicker({
    super.key,
    this.initialAvatarUrl,
    required this.onAvatarUpdated,
  });

  @override
  State<PlayerAvatarPicker> createState() => _PlayerAvatarPickerState();
}

class _PlayerAvatarPickerState extends State<PlayerAvatarPicker> {
  final _repository = PlayerProfileRepository(DioClient());
  final _picker = ImagePicker();

  File? _localFile;
  String? _avatarUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.initialAvatarUrl;
  }

  @override
  void didUpdateWidget(covariant PlayerAvatarPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si le profil parent finit de charger après ce widget (cas fréquent avec un FutureBuilder
    // externe), on récupère la nouvelle URL initiale une fois qu'elle arrive.
    if (oldWidget.initialAvatarUrl != widget.initialAvatarUrl &&
        _localFile == null) {
      _avatarUrl = widget.initialAvatarUrl;
    }
  }

  Future<void> _pickAndUpload() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked == null) return;

    setState(() {
      _localFile = File(picked.path);
      _isUploading = true;
    });

    try {
      final newUrl = await _repository.uploadAvatar(_localFile!);
      if (!mounted) return;
      setState(() => _avatarUrl = newUrl);
      widget.onAvatarUpdated(newUrl);

      _showSnackBar(message: 'Photo de profil mise à jour !', isError: false);
    } catch (e) {
      debugPrint('Erreur upload avatar: $e');
      if (!mounted) return;
      _showSnackBar(
        message: 'Erreur lors de l\'upload de la photo',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Affiche un snackbar en haut de l'écran (helper centralisé).
  void _showSnackBar({required String message, required bool isError}) {
    if (isError) {
      AppSnackbar.error(context, message);
    } else {
      AppSnackbar.success(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? backgroundImage;
    if (_localFile != null) {
      backgroundImage = FileImage(_localFile!);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(_avatarUrl!);
    }

    return Center(
      child: Stack(
        children: [
          // -------- Avatar cercle --------
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentOrange, width: 2),
            ),
            child: CircleAvatar(
              radius: 50,
              // ⚠️ Fond sombre bleuté volontaire : c'est le style du fallback
              // avatar (avec l'anneau orange), cohérent dans les 2 thèmes.
              backgroundColor: const Color(0xFF1E2638),
              backgroundImage: backgroundImage,
              child: backgroundImage == null
                  ? Icon(
                      Icons.person,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.54),
                    )
                  : null,
            ),
          ),

          // -------- Bouton caméra --------
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploading ? null : _pickAndUpload,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.accentOrange,
                  shape: BoxShape.circle,
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onGold,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: AppColors.onGold,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
