import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/widgets/player_result_card.dart';
import 'package:mercato_frontend/features/player/domain/player_labels.dart';
import 'package:mercato_frontend/features/user/data/player_search_repository.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';

class RecruiterSearchScreen extends StatefulWidget {
  const RecruiterSearchScreen({super.key});

  @override
  State<RecruiterSearchScreen> createState() => _RecruiterSearchScreenState();
}

class _RecruiterSearchScreenState extends State<RecruiterSearchScreen> {
  final _searchRepository = PlayerSearchRepository(DioClient());
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();

  List<PlayerSearchResult> _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  String? _selectedPosition;
  String? _selectedLevel;

  int _page = 1;
  bool _hasMore = true;
  int _seed = DateTime.now().millisecondsSinceEpoch;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (maxScrollExtent > 0 &&
        _scrollController.position.pixels >= maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _seed = DateTime.now().millisecondsSinceEpoch;
    });

    try {
      final result = await _searchRepository.search(
        query: _queryController.text,
        position: _selectedPosition,
        level: _selectedLevel,
        page: 1,
        seed: _seed,
      );
      if (mounted) {
        setState(() {
          _results = result.items;
          _page = result.page;
          _hasMore = result.hasMore && result.items.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Erreur lors du chargement des talents.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final result = await _searchRepository.search(
        query: _queryController.text,
        position: _selectedPosition,
        level: _selectedLevel,
        page: _page + 1,
        seed: _seed,
      );
      if (mounted) {
        setState(() {
          _results.addAll(result.items);
          _page = result.page;
          _hasMore = result.hasMore && result.items.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement talents : $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onQueryChanged(String _) {
    setState(() {}); // Met à jour l'icône "clear"
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> _pickFilter({
    required String title,
    required Map<String, String> options,
    required String? currentValue,
    required ValueChanged<String?> onSelected,
  }) async {
    final colors = context.colors;

    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final sheetColors = sheetContext.colors;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Poignée visuelle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetColors.textTertiary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: context.weight(FontWeight.bold),
                        fontSize: 16,
                        color: sheetColors.textPrimary,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: sheetColors.divider),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        ListTile(
                          title: Text(
                            'Tous',
                            style: TextStyle(
                              color: sheetColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          trailing: currentValue == null
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.primaryYellow,
                                )
                              : null,
                          onTap: () => Navigator.pop(sheetContext, ''),
                        ),
                        for (final entry in options.entries)
                          ListTile(
                            title: Text(
                              entry.value,
                              style: TextStyle(
                                color: sheetColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            trailing: currentValue == entry.key
                                ? const Icon(
                                    Icons.check,
                                    color: AppColors.primaryYellow,
                                  )
                                : null,
                            onTap: () => Navigator.pop(sheetContext, entry.key),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      onSelected(selected.isEmpty ? null : selected);
      _search();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'RECHERCHE DE TALENTS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: context.weight(FontWeight.bold),
          ),
        ),
      ),
      body: Column(
        children: [
          // -------- Barre de recherche + filtres --------
          FadeInDown(
            duration: const Duration(milliseconds: 400),
            child: Container(

              color: colors.surfaceVariant,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  TextField(
                    controller: _queryController,
                    onChanged: _onQueryChanged,
                    onSubmitted: (_) => _search(),
                    style: TextStyle(color: colors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Nom, prénom ou poste...',
                      hintStyle: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primaryYellow,
                        size: 22,
                      ),
                      suffixIcon: _queryController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                color: colors.iconMuted,
                                size: 18,
                              ),
                              onPressed: () {
                                _queryController.clear();
                                _search();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primaryYellow,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _FilterChip(
                        icon: Icons.sports_soccer,
                        label: _selectedPosition == null
                            ? 'Poste'
                            : PlayerLabels.labelFor(
                                PlayerLabels.positions,
                                _selectedPosition,
                              ),
                        isActive: _selectedPosition != null,
                        onTap: () => _pickFilter(
                          title: 'Filtrer par poste',
                          options: PlayerLabels.positions,
                          currentValue: _selectedPosition,
                          onSelected: (v) =>
                              setState(() => _selectedPosition = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FilterChip(
                        icon: Icons.military_tech_outlined,
                        label: _selectedLevel == null
                            ? 'Niveau'
                            : PlayerLabels.labelFor(
                                PlayerLabels.levels,
                                _selectedLevel,
                              ),
                        isActive: _selectedLevel != null,
                        onTap: () => _pickFilter(
                          title: 'Filtrer par niveau',
                          options: PlayerLabels.levels,
                          currentValue: _selectedLevel,
                          onSelected: (v) => setState(() => _selectedLevel = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // -------- Résultats --------
          Expanded(
            child: _isLoading
                ? const Center(child: AppLoader(size: 90))
                : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colors.error, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aucun talent trouvé.',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _results.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: AppLoader(size: 22),
                            ),
                          ),
                        );
                      }

                      return FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        delay: Duration(milliseconds: 40 * (index % 10)),
                        child: PlayerResultCard(
                          player: _results[index],
                          onTapViewProfile: () => Navigator.pushNamed(
                            context,
                            AppRoutes.detail,
                            arguments: _results[index],
                          ),
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

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryYellow : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primaryYellow : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? AppColors.onGold : colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.onGold : colors.textSecondary,
                fontSize: 14,
                fontWeight: isActive
                    ? context.weight(FontWeight.bold)
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
