import 'package:flutter/material.dart';
import 'package:mercato_app/features/player/presentation/screen/player_candidature.dart';
import 'package:mercato_app/features/player/presentation/screen/player_dashboard.dart';
import 'package:mercato_app/features/player/presentation/screen/player_message.dart';
import 'package:mercato_app/features/player/presentation/screen/player_profile.dart';


class PlayerHomeScreen extends StatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    PlayerDashboard(),
    PlayerApplications(),
    PlayerMessage(),
    PlayerProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF14212C),
        selectedItemColor: const Color(0xFF00E676),
        unselectedItemColor: Colors.white38,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.feed_outlined),
            activeIcon: Icon(Icons.feed),
            label: 'Fil d\'actu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Postulations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}