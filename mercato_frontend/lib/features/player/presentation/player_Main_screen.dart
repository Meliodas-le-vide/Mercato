import 'package:flutter/material.dart';
import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/features/player/presentation/feed_screen.dart';


class PlayerMainScreen extends StatefulWidget {
  const PlayerMainScreen({super.key});

  @override
  State<PlayerMainScreen> createState() => _PlayerMainScreenState();
}

class _PlayerMainScreenState extends State<PlayerMainScreen> {
  int _currentIndex = 0;

  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color darkBlue = Color(0xFF0F2137);

  final List<Widget> _pages = [
    const FeedScreen(),
    const _PlaceholderEventsScreen(),
    const _PlaceholderSearchScreen(),
    const _PlaceholderMessageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          Positioned(
            right: 20,
            bottom: 30,
            child: FloatingActionButton(
              backgroundColor: primaryYellow,
              elevation: 4,
              shape: const CircleBorder(),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.upload);
              },
              child: const Icon(Icons.add, color: darkBlue, size: 35),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 100,
        decoration: const BoxDecoration(
          color: darkBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home,
                label: 'Home',
                isSelected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                label: 'Events',
                isSelected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavItem(
                icon: Icons.search,
                label: 'Search',
                isSelected: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavItem(
                icon: Icons.mail_outline,
                label: 'Message',
                isSelected: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),          
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color primaryYellow = Color(0xFFFFD600);

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? primaryYellow : Colors.white54,
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryYellow : Colors.white54,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}



class _PlaceholderEventsScreen extends StatelessWidget {
  const _PlaceholderEventsScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Events')));
}

class _PlaceholderSearchScreen extends StatelessWidget {
  const _PlaceholderSearchScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Search')));
}

class _PlaceholderMessageScreen extends StatelessWidget {
  const _PlaceholderMessageScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Message')));
}