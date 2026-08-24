import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mercato_frontend/features/player/data/player_repository.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';

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
    if (oldWidget.initialAvatarUrl != widget.initialAvatarUrl && _localFile == null) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil mise à jour !')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'upload de la photo')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryNeon, width: 2),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFF1E2638),
              backgroundImage: backgroundImage,
              child: backgroundImage == null
                  ? const Icon(Icons.person, size: 48, color: Colors.white54)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploading ? null : _pickAndUpload,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryNeon,
                  shape: BoxShape.circle,
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.camera_alt, size: 16, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}