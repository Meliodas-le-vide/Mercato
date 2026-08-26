import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/features/auth/domain/user_model.dart';
import 'package:mercato_frontend/features/player/data/player_repository.dart';
import 'package:mercato_frontend/features/player/domain/player_profile_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color darkBlue = Color(0xFF0F2137);

  final _storage = const FlutterSecureStorage();
  final _profileRepository = PlayerProfileRepository(DioClient());

  UserModel? _user;
  PlayerProfileModel? profile;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userJson = await _storage.read(key: 'user_data');
      if (userJson != null) {
        _user = UserModel.fromJson(jsonDecode(userJson));
      }

      try {
        profile = await _profileRepository.getMe();
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          profile = null;
        } else {
          rethrow;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erreur lors du chargement des données.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _editProfile() async {
    final updated = await Navigator.pushNamed(context, AppRoutes.edit);
    if (updated == true) _loadUserData();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkBlue,
        title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se déconnecter', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.deleteAll();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
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
        title: const Text(
          'MON PROFIL',
          style: TextStyle(color: primaryYellow, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: RefreshIndicator(
          color: darkBlue,
          onRefresh: _loadUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
        
              
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: darkBlue.withOpacity(0.1),
                        backgroundImage: _user?.Profile_image != null ? NetworkImage(_user!.Profile_image!) : null,
                        child: _user?.Profile_image == null
                            ? const Icon(Icons.person, size: 45, color: darkBlue)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_user?.firstname ?? ''} ${_user?.lastname ?? ''}'.toUpperCase(),
                        style: const TextStyle(color: darkBlue, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user?.email ?? '',
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user?.phone ?? '',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 13
                        ),
                      )
                    ],
                  ),
                ),
        
                const SizedBox(height: 20),
        
            
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit, size: 16, color: darkBlue),
                    label: const Text('MODIFIER MES INFORMATIONS', style: TextStyle(color: darkBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: darkBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
        
                const SizedBox(height: 7),

                 SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _editProfile,
                    label: const Text('DEVENIR JOUEUR', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: darkBlue,
                      side: const BorderSide(color: darkBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
        
                // Container(
                //   padding: const EdgeInsets.all(16),
                //   decoration: BoxDecoration(
                //     color: darkBlue,
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Column(
                //     children: [
                //       _buildInfoRow('Téléphone',  ?? 'Non renseigné'),
                //       const Divider(color: Colors.white12),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildInfoRow(String label, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
  //         Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
  //       ],
  //     ),
  //   );
  // }
}