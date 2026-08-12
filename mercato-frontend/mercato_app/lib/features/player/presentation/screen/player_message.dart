import 'package:flutter/material.dart';

class PlayerMessage extends StatelessWidget {
  const PlayerMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14212C),
        elevation: 0,
        title: const Text('Messages', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Text(
          'Discussions avec les recruteurs et agents',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}