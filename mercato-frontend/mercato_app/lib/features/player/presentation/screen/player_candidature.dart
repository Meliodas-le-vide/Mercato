import 'package:flutter/material.dart';

class PlayerApplications extends StatelessWidget {
  const PlayerApplications({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14212C),
        elevation: 0,
        title: const Text('Mes Postulations', style: TextStyle(color: Colors.white)),
      ),
      body: const Center(
        child: Text(
          'Suivi de tes candidatures auprès des clubs',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}