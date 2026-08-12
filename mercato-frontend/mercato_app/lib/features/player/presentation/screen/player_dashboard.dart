import 'package:flutter/material.dart';
import 'package:mercato_app/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';


class PlayerDashboard extends StatelessWidget {
  const PlayerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14212C),
        elevation: 0,
        title: const Text(
          'Mercato',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salut, ${user?.firstname ?? "Joueur"} ⚽',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Découvre les dernières opportunités de recrutement',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF14212C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00E676).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFF00E676),
                    child: Icon(Icons.sports_soccer, color: Colors.black, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Profil visible aux recruteurs',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Complète tes statistiques pour augmenter ta visibilité.',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Offres recommandées',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF14212C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Aucune offre récente pour le moment',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}