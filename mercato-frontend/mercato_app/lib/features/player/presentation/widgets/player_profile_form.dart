import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class PlayerProfileForm extends StatefulWidget {
  const PlayerProfileForm({super.key});

  @override
  State<PlayerProfileForm> createState() => _PlayerProfileFormState();
}

class _PlayerProfileFormState extends State<PlayerProfileForm> {
  static const Color darkBg = Color(0xFF0B141B);
  static const Color cardBg = Color(0xFF1A232A);
  static const Color accentColor = Color(0xFF00E676);

  final _formKey = GlobalKey<FormState>();

  // Fichiers locaux
  File? _profileImage;
  List<File> _videoFiles = [];

  // Champs Fiche Technique
  String _poste = 'Ailier Droit';
  String _piedFort = 'Droitier';
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Champs Stats
  final TextEditingController _matchesController = TextEditingController();
  final TextEditingController _goalsController = TextEditingController();
  final TextEditingController _assistsController = TextEditingController();

  // Sélectionner une photo
  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // Sélectionner/Uploader des fichiers vidéos locaux
  Future<void> _pickVideoFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _videoFiles.addAll(result.paths.map((path) => File(path!)).toList());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        title: const Text('Compléter mon profil'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PHOTO DE PROFIL
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: cardBg,
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? const Icon(Icons.add_a_photo, color: accentColor, size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Ajouter une photo de profil', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. FICHE TECHNIQUE
              _buildSectionTitle('Fiche Technique'),
              const SizedBox(height: 12),
              _buildDropdown('Poste Principal', _poste, ['Ailier Droit', 'Ailier Gauche', 'Buteur', 'Milieu Offensif', 'Défenseur Central'], (val) {
                setState(() => _poste = val!);
              }),
              const SizedBox(height: 12),
              _buildDropdown('Pied Fort', _piedFort, ['Droitier', 'Gaucher', 'Ambidextre'], (val) {
                setState(() => _piedFort = val!);
              }),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_heightController, 'Taille (cm)', TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_weightController, 'Poids (kg)', TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_ageController, 'Âge', TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),

              // 3. STATISTIQUES DE SAISON
              _buildSectionTitle('Statistiques de la saison'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField(_matchesController, 'Matchs', TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_goalsController, 'Buts', TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_assistsController, 'Passes D.', TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),

              // 4. UPLOAD DE VIDÉOS (HIGHLIGHTS)
              _buildSectionTitle('Vidéos & Highlights (Upload)'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickVideoFiles,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withOpacity(0.5), style: BorderStyle.solid),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_call, color: accentColor),
                      SizedBox(width: 10),
                      Text('Uploader une ou plusieurs vidéos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              if (_videoFiles.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('${_videoFiles.length} vidéo(s) sélectionnée(s)', style: const TextStyle(color: accentColor, fontSize: 12)),
              ],

              const SizedBox(height: 32),

              // BOUTON DE SAUVEGARDE
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Envoyer les données et fichiers vers Supabase / Node.js backend
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Enregistrer la fiche', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType keyboardType) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: cardBg,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}