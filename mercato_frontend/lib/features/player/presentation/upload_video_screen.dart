import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/widgets/app_text_field.dart';
import 'package:mercato_frontend/core/widgets/gold_button.dart';
import 'package:mercato_frontend/features/user/data/video_repository.dart';

class PlayerUploadScreen extends StatefulWidget {
  const PlayerUploadScreen({super.key});

  @override
  State<PlayerUploadScreen> createState() => _PlayerUploadScreenState();
}

class _PlayerUploadScreenState extends State<PlayerUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  late final VideoRepository _videoRepository;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  String _selectedCategory = 'HIGHLIGHT';
  File? _selectedVideo;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _pickerPressed = false;

  final List<String> _categories = [
    'HIGHLIGHT',
    'MATCH EN ENTIER',
    'ANALYSE',
    'ENTRAÎNEMENT',
  ];

  @override
  void initState() {
    super.initState();
    _videoRepository = VideoRepository(DioClient());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _selectedVideo = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVideo == null) {
      _showSnackBar(
        message: 'Veuillez sélectionner une vidéo à publier.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      List<String> tagsList = [
        _selectedCategory.toLowerCase().replaceAll(' ', '_'),
      ];

      if (_tagsController.text.trim().isNotEmpty) {
        final customTags = _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty);
        tagsList.addAll(customTags);
      }

      await _videoRepository.uploadVideo(
        videoFile: _selectedVideo!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        tags: tagsList,
        onProgress: (sent, total) {
          if (total > 0) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );

      if (!mounted) return;

      _showSnackBar(message: 'Vidéo publiée avec succès !', isError: false);

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Erreur lors du chargement de la vidéo.';
      if (e is DioException && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }

      _showSnackBar(message: errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
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
          'Publier une vidéo',
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _VideoPicker(
                  file: _selectedVideo,
                  isDisabled: _isUploading,
                  isPressed: _pickerPressed,
                  onTapDown: () => setState(() => _pickerPressed = true),
                  onTapUp: () => setState(() => _pickerPressed = false),
                  onTapCancel: () => setState(() => _pickerPressed = false),
                  onTap: _pickVideo,
                ),
                const SizedBox(height: 28),

                AppTextField(
                  controller: _titleController,
                  label: 'Titre',
                  hint: 'Ex : Compilation buts saison 2025/26',
                  icon: Icons.title_rounded,
                  required: true,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Décris brièvement le contexte…',
                  required: true,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),
                _CategoryField(
                  categories: _categories,
                  selected: _selectedCategory,
                  onChanged: (cat) => setState(() => _selectedCategory = cat),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _tagsController,
                  label: 'Mots-clés (séparés par des virgules)',
                  hint: 'dribble, vitesse, coup franc',
                  icon: Icons.tag_rounded,
                ),
                const SizedBox(height: 32),

                if (_isUploading) ...[
                  _UploadProgress(progress: _uploadProgress),
                  const SizedBox(height: 20),
                ],

                GoldButton(
                  height: 52,
                  width: double.infinity,
                  fontSize: 15,
                  label: 'Publier la vidéo',
                  icon: Icons.cloud_upload_outlined,
                  loading: _isUploading,
                  onPressed: _isUploading ? null : _submitData,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoPicker extends StatelessWidget {
  final File? file;
  final bool isDisabled;
  final bool isPressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;
  final VoidCallback onTap;

  const _VideoPicker({
    required this.file,
    required this.isDisabled,
    required this.isPressed,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasFile = file != null;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      onTapDown: isDisabled ? null : (_) => onTapDown(),
      onTapUp: isDisabled ? null : (_) => onTapUp(),
      onTapCancel: isDisabled ? null : onTapCancel,
      child: AnimatedScale(
        scale: isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasFile ? AppColors.accentOrange : colors.border,
              width: hasFile ? 1.5 : 1,
            ),
          ),
          child: hasFile
              ? _buildSelected(context, colors)
              : _buildEmpty(context, colors),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, AppSemanticColors colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloud_upload_outlined,
            color: colors.iconMuted,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sélectionner une vidéo',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: context.weight(FontWeight.w600),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'MP4, MOV · Max 100 Mo',
          style: TextStyle(color: colors.textTertiary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSelected(BuildContext context, AppSemanticColors colors) {
    final fileName = file!.path.split('/').last;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.accentOrange,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            fileName,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: context.weight(FontWeight.w600),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          const Text(
            'Appuyer pour modifier',
            style: TextStyle(
              color: AppColors.accentOrange,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  const _CategoryField({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: context.weight(FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selected,
          dropdownColor: colors.surface,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.iconMuted,
          ),
          style: TextStyle(color: colors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.category_outlined,
              size: 20,
              color: colors.iconMuted,
            ),
          ),
          items: [
            for (final cat in categories)
              DropdownMenuItem(value: cat, child: Text(cat)),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

class _UploadProgress extends StatelessWidget {
  final double progress;

  const _UploadProgress({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final percentage = (progress * 100).toStringAsFixed(0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(color: colors.surfaceVariant),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.accentOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 14, height: 14, child: AppLoader(size: 14)),
            const SizedBox(width: 8),
            Text(
              'Envoi en cours… $percentage %',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
