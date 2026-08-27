import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/widgets/player_result_card.dart';
import 'package:mercato_frontend/features/user/data/player_search_repository.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchRepository = PlayerSearchRepository(DioClient());
  final _queryController = TextEditingController();

  static const Color darkBlue = Color(0xFF0F2137);
  static const Color primaryYellow = Color(0xFFFFD600);

  List<PlayerSearchResult> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Chargement initial : tous les joueurs, ordre aléatoire (géré backend).
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _searchRepository.search(
        query: _queryController.text,
      );
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erreur lors du chargement des joueurs.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Recherche déclenchée automatiquement pendant la frappe, avec un
  // léger délai pour éviter une requête à chaque caractère tapé.
  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        title: const Text(
          'EXPLORER LES JOUEURS',
          style: TextStyle(color: primaryYellow, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: darkBlue,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _queryController,
              onChanged: _onQueryChanged,
              onSubmitted: (_) => _search(),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Nom, prénom ou poste...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: primaryYellow, size: 20),
                suffixIcon: _queryController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                        onPressed: () {
                          _queryController.clear();
                          _search();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: darkBlue))
                : _errorMessage != null
                    ? Center(
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                      )
                    : _results.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun joueur trouvé.',
                              style: TextStyle(color: darkBlue, fontSize: 14),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              return PlayerResultCard(
                                player: _results[index],
                                onTapViewProfile: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.detail,
                                  arguments: _results[index],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}