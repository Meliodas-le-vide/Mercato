import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/features/feed/data/video_repository.dart';

class PlayerUploadScreen extends StatefulWidget {
  const PlayerUploadScreen({super.key});

  @override
  State<PlayerUploadScreen> createState() => _PlayerUploadScreenState();
}

class _PlayerUploadScreenState extends State<PlayerUploadScreen> {
  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color darkBlue = Color(0xFF0F2137);

  final _formKey = GlobalKey<FormState>();
  late final VideoRepository _videoRepository;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  String _selectedCategory = 'HIGHLIGHT';
  File? _selectedVideo;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final List<String> _categories = ['HIGHLIGHT', 'MATCH EN ENTIER', 'ANALYSE', 'ENTRAÎNEMENT'];

  @override
  void initState() {
    super.initState();
    _videoRepository = VideoRepository(DioClient());
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedVideo = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une vidéo à publier.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      List<String> tagsList = [_selectedCategory.toLowerCase().replaceAll(' ', '_')];

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vidéo publiée avec succès !'),
          backgroundColor: darkBlue,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Erreur lors du chargement de la vidéo.';
      if (e is DioException && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PUBLIER UNE VIDÉO',
          style: TextStyle(
            color: primaryYellow,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélecteur de vidéo
              GestureDetector(
                onTap: _isUploading ? null : _pickVideo,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _selectedVideo != null ? darkBlue : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedVideo != null ? primaryYellow : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: _selectedVideo != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: primaryYellow, size: 48),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                _selectedVideo!.path.split('/').last,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Cliquer pour modifier',
                              style: TextStyle(color: primaryYellow, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.cloud_upload_outlined, color: darkBlue, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'Sélectionner la vidéo du joueur',
                              style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Format MP4, MOV (Max 100 Mo)',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('INFORMATIONS VIDÉO'),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _titleController,
                label: 'Titre de la vidéo',
                hint: 'ex: SAISON 2025/26 - COMPILATION BUTS',
                icon: Icons.title,
                validator: (val) => val == null || val.trim().isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Décris brièvement les détails ou le contexte...',
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              _buildTextField(
                controller: _tagsController,
                label: 'Mots-clés / Tags (séparés par des virgules)',
                hint: 'ex: dribble, vitesse, coup_franc',
                icon: Icons.local_offer_outlined,
              ),
              const SizedBox(height: 16),

              const Text(
                'Catégorie',
                style: TextStyle(color: darkBlue, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? primaryYellow : darkBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: darkBlue,
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? darkBlue : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              if (_isUploading) ...[
                LinearProgressIndicator(
                  value: _uploadProgress > 0 ? _uploadProgress : null,
                  backgroundColor: Colors.grey.shade200,
                  color: darkBlue,
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Envoi en cours... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: darkBlue, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: primaryYellow, strokeWidth: 2.5),
                        )
                      : const Text(
                          'PUBLIER DANS LE MERCATO',
                          style: TextStyle(
                            color: primaryYellow,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: darkBlue,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: darkBlue, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black45, fontSize: 12),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        prefixIcon: Icon(icon, color: darkBlue, size: 20),
        filled: true,
        fillColor: Colors.grey.shade100,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}