import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/core/widgets/player_avatar_picker.dart';
import 'package:mercato_frontend/features/player/data/player_repository.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/dio_client.dart';
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

  static const Map<String, String> _positions = {
    'GARDIEN': 'Gardien',
    'DEFENSEUR_CENTRAL': 'Défenseur central',
    'LATERAL_DROIT': 'Latéral droit',
    'LATERAL_GAUCHE': 'Latéral gauche',
    'MILIEU_DEFENSIF': 'Milieu défensif',
    'MILIEU_CENTRAL': 'Milieu central',
    'MILIEU_OFFENSIF': 'Milieu offensif',
    'AILIER_DROIT': 'Ailier droit',
    'AILIER_GAUCHE': 'Ailier gauche',
    'ATTAQUANT': 'Attaquant',
  };

  static const Map<String, String> _feet = {
    'DROIT': 'Droit',
    'GAUCHE': 'Gauche',
    'AMBIDEXTRE': 'Ambidextre',
  };

  static const Map<String, String> _levels = {
    'AMATEUR': 'Amateur',
    'SEMI_PRO': 'Semi-professionnel',
    'PRO': 'Professionnel',
  };

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  /// Précharge le profil existant (toujours le cas ici, puisqu'on édite)
  Future<void> _loadExistingProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _repository.getMe();
      setState(() {
        _selectedPosition = profile.position;
        _selectedFoot = profile.strongFoot;
        _selectedLevel = profile.level;
        _birthDate = profile.birthDate != null ? DateTime.tryParse(profile.birthDate!) : null;
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

    // Avatar : chargé depuis le cache local (mis à jour à chaque login/register/upload)
    try {
      final userJson = await _storage.read(key: 'user_data');
      if (userJson != null) {
        final user = UserModel.fromJson(jsonDecode(userJson));
        setState(() => _avatarUrl = user.Profile_image);
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  /// Met à jour le cache local user_data avec la nouvelle URL d'avatar,
  /// pour que PlayerProfileScreen affiche la nouvelle photo sans appel réseau.
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

    await _storage.write(key: 'user_data', value: jsonEncode(updatedUser.toJson()));
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(now.year - 60),
      lastDate: DateTime(now.year - 5),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (_selectedPosition == null || _selectedLevel == null || _birthDate == null || _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poste, niveau, date de naissance et ville sont obligatoires')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profile = PlayerProfileModel(
        userId: 0, // ignoré à l'update, le backend utilise le token
        position: _selectedPosition,
        strongFoot: _selectedFoot,
        birthDate: _birthDate!.toIso8601String().split('T').first,
        level: _selectedLevel,
        currentClub: _clubController.text.trim().isEmpty ? null : _clubController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        height: int.tryParse(_heightController.text.trim()),
        weight: int.tryParse(_weightController.text.trim()),
      );

      await _repository.updateMe(profile);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour !')),
      );

      // Toujours poussé depuis l'écran profil -> on revient dessus avec le signal de rafraîchissement.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'enregistrement du profil')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E1A),
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryNeon)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text('Éditer ton profil', style: TextStyle(color: Colors.white)),
        elevation: 0,
              leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlayerAvatarPicker(
                initialAvatarUrl: _avatarUrl,
                onAvatarUpdated: _handleAvatarUpdated,
              ),
              const SizedBox(height: 20),

              const Text(
                'Ces informations seront visibles par les recruteurs.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 20),

              _buildDropdown('Poste *', _selectedPosition, _positions, (v) => setState(() => _selectedPosition = v)),
              const SizedBox(height: 12),

              _buildDropdown('Pied fort', _selectedFoot, _feet, (v) => setState(() => _selectedFoot = v)),
              const SizedBox(height: 12),

              _buildDropdown('Niveau *', _selectedLevel, _levels, (v) => setState(() => _selectedLevel = v)),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickBirthDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2638),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _birthDate == null
                            ? 'Date de naissance *'
                            : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                        style: TextStyle(
                          color: _birthDate == null ? Colors.white38 : Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.white54, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildTextField(_clubController, 'Club actuel (optionnel)', Icons.shield_outlined),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildTextField(_cityController, 'Ville *', Icons.location_on_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_countryController, 'Pays', Icons.public)),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_heightController, 'Taille (cm)', Icons.height,
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(_weightController, 'Poids (kg)', Icons.monitor_weight_outlined,
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _bioController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Parle un peu de toi, de ton parcours...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  fillColor: const Color(0xFF1E2638),
                  filled: true,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNeon,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Enregistrer les modifications', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        fillColor: const Color(0xFF1E2638),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: Icon(icon, color: Colors.white54, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    String? value,
    Map<String, String> options,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2638),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          isExpanded: true,
          dropdownColor: const Color(0xFF1E2638),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          items: options.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}