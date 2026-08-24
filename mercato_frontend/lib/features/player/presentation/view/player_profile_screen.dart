import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/features/auth/domain/user_model.dart';
import 'package:mercato_frontend/features/player/data/player_repository.dart';
import 'package:mercato_frontend/features/player/domain/player_profile_model.dart';

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({super.key});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color darkBlue = Color(0xFF0F2137);

  final _storage = const FlutterSecureStorage();
  final _profileRepository = PlayerProfileRepository(DioClient());

  UserModel? _user;
  PlayerProfileModel? _profile;

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
        _profile = await _profileRepository.getMe();
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          _profile = null;
        } else {
          rethrow;
        }
      }
    } on DioException catch (e) {
      debugPrint('DioException profil : status=${e.response?.statusCode} message=${e.message}');
      if (mounted) {
        setState(() => _errorMessage = 'Erreur lors du chargement de votre profil.');
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données : $e');
      if (mounted) {
        setState(() => _errorMessage = 'Une erreur inattendue est survenue.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _completeProfile() async {
    final completed = await Navigator.pushNamed(context, AppRoutes.completeProfile);
    if (completed == true) {
      _loadUserData();
    }
  }

  void _editProfile() async {
    final updated = await Navigator.pushNamed(context, AppRoutes.editProfile);
    if (updated == true) {
      _loadUserData();
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: darkBlue,
        title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: TextStyle(color: Colors.white70),
        ),
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
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  String _calculateAge(String? birthDateStr) {
    if (birthDateStr == null || birthDateStr.isEmpty) return '--';
    try {
      DateTime birthDate = DateTime.parse(birthDateStr);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age.toString();
    } catch (_) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: darkBlue),
        ),
      );
    }

    final bool isConfigured = _profile?.isProfileComplete ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PROFILE',
          style: TextStyle(
            color: primaryYellow,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: darkBlue,
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadUserData,
                        child: const Text('Réessayer', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: darkBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryYellow, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white12,
                                backgroundImage: _user?.Profile_image != null
                                    ? NetworkImage(_user!.Profile_image!)
                                    : null,
                                child: _user?.Profile_image == null
                                    ? const Icon(Icons.person, size: 36, color: Colors.white54)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _editProfile,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: primaryYellow,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 14,
                                    color: darkBlue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPillBadge(
                                icon: Icons.sports_soccer,
                                label: _profile?.position?.toUpperCase() ?? 'NON DÉFINI',
                                bgColor: Colors.white.withOpacity(0.15),
                                textColor: Colors.white,
                              ),
                              const SizedBox(height: 6),
                              _buildPillBadge(
                                icon: Icons.check_circle,
                                label: _profile?.currentClub?.toUpperCase() ?? 'SANS CLUB',
                                bgColor: primaryYellow.withOpacity(0.2),
                                textColor: primaryYellow,
                                borderColor: primaryYellow,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${_user?.firstname.toUpperCase() ?? 'PRÉNOM'} ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          TextSpan(
                            text: _user?.lastname.toUpperCase() ?? 'NOM',
                            style: const TextStyle(
                              color: primaryYellow,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      isConfigured
                          ? (_profile?.bio ?? 'Aucune biographie renseignée.')
                          : 'Bienvenue ! Ton profil n\'est pas encore visible par les recruteurs. Renseigne tes informations pour maximiser tes chances.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: isConfigured ? _editProfile : _completeProfile,
                        icon: Icon(
                          isConfigured ? Icons.edit : Icons.flash_on,
                          size: 18,
                          color: darkBlue,
                        ),
                        label: Text(
                          isConfigured ? 'ÉDITER LE PROFIL' : 'CONFIGURER LE PROFIL',
                          style: const TextStyle(
                            color: darkBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 2.1,
                children: [
                  _buildStatTile(
                    icon: Icons.cake_outlined,
                    label: 'ÂGE',
                    value: isConfigured ? '${_calculateAge(_profile?.birthDate)} ans' : '--',
                  ),
                  _buildStatTile(
                    icon: Icons.height,
                    label: 'TAILLE',
                    value: isConfigured && _profile?.height != null ? '${_profile!.height} cm' : '--',
                  ),
                  _buildStatTile(
                    icon: Icons.directions_walk,
                    label: 'PIED',
                    value: isConfigured ? (_profile?.strongFoot ?? '--') : '--',
                  ),
                  _buildStatTile(
                    icon: Icons.fitness_center,
                    label: 'POIDS',
                    value: isConfigured && _profile?.weight != null ? '${_profile!.weight} kg' : '--',
                  ),
                ],
              ),
            

              _buildSectionTitle('STATS SUR LE TERRAIN', Icons.leaderboard),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: darkBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Matchs Joués', '${_profile?.matchesPlayed ?? 0}'),
                    const Divider(color: Colors.white12),
                    _buildDetailRow('Buts marqués', '${_profile?.goals ?? 0}'),
                    const Divider(color: Colors.white12),
                    _buildDetailRow('Passes décisives', '${_profile?.assists ?? 0}'),
                    const Divider(color: Colors.white12),
                    _buildDetailRow('Cartons Jaunes', '${_profile?.cardsYellow ?? 0}'),
                    const Divider(color: Colors.white12),
                    _buildDetailRow('Cartons Rouges', '${_profile?.cardsRed ?? 0}'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
             
              _buildSectionTitle('INFORMATIONS DE CONTACT', Icons.alternate_email),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: darkBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Email', _user?.email ?? 'Non renseigné'),
                    const Divider(color: Colors.white12),
                    _buildDetailRow('Téléphone', _user?.phone ?? 'Non renseigné'),
                    const Divider(color: Colors.white12),
                    _buildDetailRow('Ville', _profile?.city ?? 'Non renseigné'),
                    const Divider(color: Colors.white12),
                    _buildDetailRow('Pays', _profile?.country ?? 'Non renseigné'),
                  ],
                ),
              ),
              const SizedBox(height: 45),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: darkBlue, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: darkBlue,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPillBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryYellow.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryYellow, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}