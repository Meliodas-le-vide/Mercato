import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/widgets/player_avatar_picker.dart';
import 'package:mercato_frontend/features/player/data/player_repository.dart';
import 'package:mercato_frontend/features/player/domain/player_profile_model.dart';
import '../../auth/domain/user_model.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color darkBlue = Color(0xFF0F2137);

  final _repository = PlayerProfileRepository(DioClient());
  final _storage = const FlutterSecureStorage();

  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  UserModel? _currentUser;
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
    _firstnameController.dispose();
    _lastnameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    setState(() => _isLoading = true);

    try {
      final userJson = await _storage.read(key: 'user_data');
      if (userJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        _firstnameController.text = _currentUser?.firstname ?? '';
        _lastnameController.text = _currentUser?.lastname ?? '';
        _phoneController.text = _currentUser?.phone ?? '';
        _avatarUrl = _currentUser?.Profile_image;
      }

   
    } catch (_) {
      // Ignoré si le profil joueur n'existe pas encore en base
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

    await _storage.write(key: 'user_data', value: jsonEncode(updatedUser.toJson()));
  }

  Future<void> _handleSave() async {
    if (_firstnameController.text.trim().isEmpty || _lastnameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le prénom et le nom sont obligatoires')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Sauvegarde des infos de localisation simples
      final profile = PlayerProfileModel(
        userId: _currentUser?.id ?? 0,
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
      );
      await _repository.updateMe(profile);

      // Mise à jour du cache utilisateur local (User)
      if (_currentUser != null) {
        final updatedUser = UserModel(
          id: _currentUser!.id,
          firstname: _firstnameController.text.trim(),
          lastname: _lastnameController.text.trim(),
          email: _currentUser!.email,
          phone: _phoneController.text.trim(),
          role: _currentUser!.role,
          Profile_image: _avatarUrl,
        );
        await _storage.write(key: 'user_data', value: jsonEncode(updatedUser.toJson()));
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès !')),
      );

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
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: darkBlue)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'ÉDITER LE PROFIL',
          style: TextStyle(color: primaryYellow, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlayerAvatarPicker(
                initialAvatarUrl: _avatarUrl,
                onAvatarUpdated: _handleAvatarUpdated,
              ),
              const SizedBox(height: 24),

              _buildTextField(_firstnameController, 'Prénom *', Icons.person_outline),
              const SizedBox(height: 12),

              _buildTextField(_lastnameController, 'Nom *', Icons.person_outline),
              const SizedBox(height: 12),

              _buildTextField(
                _phoneController,
                'Téléphone',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildTextField(_cityController, 'Ville', Icons.location_city_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_countryController, 'Pays', Icons.public_outlined)),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkBlue,
                  foregroundColor: primaryYellow,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: primaryYellow),
                      )
                    : const Text(
                        'ENREGISTRER',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
              ),
              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler', style: TextStyle(color: Colors.black54, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: darkBlue, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        fillColor: const Color(0xFFF4F6F8),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: Icon(icon, color: darkBlue.withOpacity(0.5), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}