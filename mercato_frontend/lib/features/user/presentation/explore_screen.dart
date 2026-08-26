import 'package:flutter/material.dart';
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
  final _cityController = TextEditingController();

  static const Color darkBlue = Color(0xFF0F2137);
  static const Color primaryYellow = Color(0xFFFFD600);

  // --- Filtres ---
  // ⚠️ Ajuste ces listes pour qu'elles correspondent EXACTEMENT aux valeurs
  // acceptées par ton backend (l'enum "position" et "level" de PlayerProfile).
  static const List<String> _positions = [
    'Gardien',
    'Défenseur',
    'Milieu',
    'Attaquant',
    'Ailier',
  ];
  static const List<String> _levels = [
    'Amateur',
    'Semi-professionnel',
    'Professionnel',
  ];

  String? _selectedPosition;
  String? _selectedLevel;
  RangeValues _ageRange = const RangeValues(15, 35);

  List<PlayerSearchResult> _results = [];
  bool _isLoading = false;
  bool _hasSearchedOnce = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Premier chargement sans filtre pour ne pas laisser l'écran vide
    _search();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearchedOnce = true;
    });

    try {
      final results = await _searchRepository.search(
        position: _selectedPosition,
        level: _selectedLevel,
        city: _cityController.text.trim(),
        minAge: _ageRange.start.round(),
        maxAge: _ageRange.end.round(),
      );
      if (mounted) setState(() => _results = results);
    } catch (e) {
      debugPrint('Erreur recherche joueurs : $e');
      if (mounted) setState(() => _errorMessage = 'Impossible de charger les résultats.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedPosition = null;
      _selectedLevel = null;
      _ageRange = const RangeValues(15, 35);
      _cityController.clear();
    });
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        title: const Text(
          'EXPLORER',
          style: TextStyle(color: primaryYellow, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFiltersPanel(),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      color: darkBlue,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildDropdown('Poste', _positions, _selectedPosition, (v) => setState(() => _selectedPosition = v))),
              const SizedBox(width: 10),
              Expanded(child: _buildDropdown('Niveau', _levels, _selectedLevel, (v) => setState(() => _selectedLevel = v))),
            ],
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _cityController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Ville',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.white54, size: 18),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Âge', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(
                '${_ageRange.start.round()} - ${_ageRange.end.round()} ans',
                style: const TextStyle(color: primaryYellow, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryYellow,
              inactiveTrackColor: Colors.white24,
              thumbColor: primaryYellow,
              overlayColor: primaryYellow.withOpacity(0.2),
              rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: RangeSlider(
              values: _ageRange,
              min: 14,
              max: 45,
              divisions: 31,
              onChanged: (values) => setState(() => _ageRange = values),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'RECHERCHER',
                    style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Réinitialiser', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    List<String> options,
    String? selected,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          hint: Text(hint, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          isExpanded: true,
          dropdownColor: darkBlue,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tous', style: TextStyle(color: Colors.white70))),
            ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
          ],
          onChanged: (v) {
            onChanged(v);
            _search();
          },
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: darkBlue));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            const SizedBox(height: 12),
            TextButton(onPressed: _search, child: const Text('Réessayer', style: TextStyle(color: darkBlue))),
          ],
        ),
      );
    }

    if (_hasSearchedOnce && _results.isEmpty) {
      return const Center(
        child: Text(
          'Aucun joueur ne correspond à ces critères.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
      );
    }

    return RefreshIndicator(
      color: darkBlue,
      onRefresh: _search,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          return PlayerResultCard(player: _results[index]);
        },
      ),
    );
  }
}