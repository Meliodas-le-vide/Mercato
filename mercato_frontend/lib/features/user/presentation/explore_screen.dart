import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mercato_frontend/config/routes/app_routes.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/widgets/player_result_card.dart';
import 'package:mercato_frontend/features/player/domain/player_labels.dart';
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
        setState(() => _errorMessage = 'Impossible de charger les joueurs.');
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
      debugPrint('Erreur chargement joueurs: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onQueryChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  void _clearQuery() {
    _queryController.clear();
    _search();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedPosition = null;
      _selectedLevel = null;
    });
    _search();
  }

  bool get _hasActiveFilters =>
      _selectedPosition != null || _selectedLevel != null;

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
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetColors.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: context.weight(FontWeight.w700),
                          fontSize: 17,
                          color: sheetColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),

                  Divider(height: 1, color: sheetColors.divider),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _SheetOption(
                          label: 'Tous',
                          isSelected: currentValue == null,
                          onTap: () => Navigator.pop(sheetContext, ''),
                        ),
                        for (final entry in options.entries)
                          _SheetOption(
                            label: entry.value,
                            isSelected: currentValue == entry.key,
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
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colors.surface,
        titleSpacing: 20,
        toolbarHeight: 64,
        title: Text(
          'EXPLORER',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: context.weight(FontWeight.w700),
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              color: colors.surface,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  _SearchField(
                    controller: _queryController,
                    onChanged: _onQueryChanged,
                    onSubmitted: (_) => _search(),
                    onClear: _clearQuery,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _FilterChip(
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
                      const SizedBox(width: 8),
                      _FilterChip(
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

                      if (_hasActiveFilters) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: _clearAllFilters,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: colors.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Effacer',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: context.weight(FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            Expanded(child: _buildResults(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(AppSemanticColors colors) {
    if (_isLoading) {
      return const Center(child: AppLoader());
    }

    if (_errorMessage != null) {
      return _StateView(
        icon: Icons.error_outline_rounded,
        title: 'Oups…',
        subtitle: _errorMessage!,
        actionLabel: 'Réessayer',
        onAction: _search,
      );
    }

    if (_results.isEmpty) {
      final hasQuery = _queryController.text.isNotEmpty || _hasActiveFilters;
      return _StateView(
        icon: Icons.search_off_rounded,
        title: hasQuery ? 'Aucun joueur trouvé' : 'Aucun joueur disponible',
        subtitle: hasQuery
            ? 'Essaie d\'autres mots-clés ou modifie les filtres.'
            : 'Reviens plus tard pour découvrir de nouveaux talents.',
        actionLabel: hasQuery ? 'Effacer les filtres' : null,
        onAction: hasQuery ? _clearAllFilters : null,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: _results.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: AppLoader(size: 22)),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(color: colors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Nom, prénom ou poste…',
        hintStyle: TextStyle(color: colors.textTertiary, fontSize: 15),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colors.iconMuted,
          size: 20,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.close_rounded,
                    color: colors.iconMuted,
                    size: 18,
                  ),
                ),
              )
            : null,
        filled: true,
        fillColor: colors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.textPrimary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colors.textPrimary : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? colors.background : colors.textSecondary,
                fontSize: 13,
                fontWeight: isActive
                    ? context.weight(FontWeight.w600)
                    : FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.close_rounded,
                size: 13,
                color: colors.background.withValues(alpha: 0.7),
              ),
            ] else ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: colors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SheetOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                  fontSize: 15,
                  fontWeight: isSelected
                      ? context.weight(FontWeight.w700)
                      : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, size: 20, color: colors.textPrimary),
          ],
        ),
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateView({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: colors.iconMuted),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: context.weight(FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: colors.surfaceVariant,
                ),
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: context.weight(FontWeight.w600),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
