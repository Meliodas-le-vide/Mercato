import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_text_field.dart';
import 'package:mercato_frontend/core/widgets/gold_button.dart';
import 'package:mercato_frontend/features/events/data/event_repository.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventRepository = EventRepository(DioClient());

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _organizerController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _organizerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null && mounted) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final colors = context.colors;

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
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
    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final colors = context.colors;

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
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
    if (time != null && mounted) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      _showSnackBar(
        message: 'Ajoute une image pour l\'événement.',
        isError: true,
      );
      return;
    }

    if (_selectedDate == null) {
      _showSnackBar(
        message: 'Choisis une date pour l\'événement.',
        isError: true,
      );
      return;
    }

    final time = _selectedTime ?? const TimeOfDay(hour: 9, minute: 0);
    final eventDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      time.hour,
      time.minute,
    );

    setState(() => _isSubmitting = true);
    try {
      await _eventRepository.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        eventDate: eventDateTime,
        location: _locationController.text.trim(),
        organizerName: _organizerController.text.trim(),
        imagePath: _selectedImage!.path,
      );

      if (!mounted) return;

      _showSnackBar(message: 'Événement publié.', isError: false);
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Erreur createEvent: $e');
      if (mounted) {
        _showSnackBar(
          message: 'Impossible de publier l\'événement.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.icon,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PUBLIER UN EVENEMENT',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: context.weight(FontWeight.w700),
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Image de l\'événement',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: context.weight(FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            _ImagePicker(image: _selectedImage, onTap: _pickImage),
            const SizedBox(height: 24),

            AppTextField(
              controller: _titleController,
              label: 'Titre',
              hint: 'Ex : Essai détection U19',
              icon: Icons.title_rounded,
              required: true,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _organizerController,
              label: 'Organisateur',
              hint: 'Ex : FC Abidjan Scouting',
              icon: Icons.groups_outlined,
              required: true,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Organisateur requis'
                  : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _locationController,
              label: 'Lieu',
              hint: 'Ex : Stade Félix Houphouët-Boigny, Abidjan',
              icon: Icons.place_outlined,
              required: true,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Lieu requis' : null,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppDateField(
                    label: 'Date',
                    icon: Icons.event_outlined,
                    hint: 'Choisir',
                    required: true,
                    value: _selectedDate,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPickerField(
                    label: 'Heure',
                    icon: Icons.schedule_rounded,
                    hint: '09:00',
                    trailingIcon: Icons.access_time_rounded,
                    value: _selectedTime?.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Programme, catégories d\'âge, matériel à prévoir…',
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 28),

            GoldButton(
              height: 52,
              width: double.infinity,
              fontSize: 15,
              icon: Icons.event_available_rounded,
              label: 'Publier l\'événement',
              loading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;

  const _ImagePicker({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasImage = image != null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: hasImage
              ? colors.surface
              : AppColors.accentOrange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasImage
                ? AppColors.accentOrange
                : AppColors.accentOrange.withValues(alpha: 0.3),
            width: hasImage ? 1.5 : 1,
          ),
          image: hasImage
              ? DecorationImage(image: FileImage(image!), fit: BoxFit.cover)
              : null,
        ),
        child: hasImage
            ? Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'Modifier',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: context.weight(FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 24,
                      color: AppColors.accentOrange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ajouter une image',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: context.weight(FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'JPG ou PNG · Max 5 Mo',
                    style: TextStyle(color: colors.textTertiary, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}
