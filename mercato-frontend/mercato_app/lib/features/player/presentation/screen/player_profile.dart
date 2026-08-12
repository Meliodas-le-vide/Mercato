import 'package:flutter/material.dart';
import 'package:mercato_app/features/player/presentation/widgets/player_profile_form.dart';
import 'package:provider/provider.dart';
import 'package:mercato_app/features/auth/providers/auth_provider.dart';


class PlayerProfile extends StatelessWidget {
  const PlayerProfile({super.key});

  static const Color darkBg = Color(0xFF0B141B);
  static const Color cardBg = Color(0xFF1A232A);
  static const Color accentColor = Color(0xFF00E676);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        title: const Text('Mon Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Spacer(),
            // Avatar & Info minimalistes
            CircleAvatar(
              radius: 50,
              backgroundColor: accentColor.withOpacity(0.15),
              child: const Icon(Icons.person, size: 60, color: accentColor),
            ),
            const SizedBox(height: 16),
            Text(
              '${user?.firstname ?? "Joueur"} ${user?.lastname ?? ""}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Bouton vers le Formulaire complet
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.edit_document),
                label: const Text('Remplir / Modifier ma fiche sportive', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlayerProfileForm()),
                  );
                },
              ),
            ),

            const Spacer(),

            // Bouton Déconnexion
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  foregroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}