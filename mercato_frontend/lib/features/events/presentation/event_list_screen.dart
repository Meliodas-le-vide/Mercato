import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/features/events/data/event_repository.dart';
import 'package:mercato_frontend/features/events/domain/event_model.dart';
import 'package:mercato_frontend/features/events/presentation/event_detail_screen.dart';

String _formatEventDate(DateTime date) {
  const months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day ${months[date.month - 1]} • ${hour}h$minute';
}

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final _eventRepository = EventRepository(DioClient());
  final _scrollController = ScrollController();

  List<EventModel> _events = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
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

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _eventRepository.getEvents(page: 1);
      if (mounted) {
        setState(() {
          _events = result.items;
          _page = result.page;
          _hasMore = result.hasMore && result.items.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Impossible de charger les événements.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final result = await _eventRepository.getEvents(page: _page + 1);
      if (mounted) {
        setState(() {
          _events.addAll(result.items);
          _page = result.page;
          _hasMore = result.hasMore && result.items.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement événements: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
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
          'EVENEMENT',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: context.weight(FontWeight.w700),
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SafeArea(top: false, child: _buildBody(colors)),
    );
  }

  Widget _buildBody(AppSemanticColors colors) {
    if (_isLoading) return const Center(child: AppLoader());

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: colors.error, size: 40),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _loadEvents,
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
                  'Réessayer',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: context.weight(FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_events.isEmpty) {
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
                  color: AppColors.accentOrange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_outlined,
                  size: 32,
                  color: AppColors.accentOrange,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Aucun événement à venir',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: context.weight(FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Les prochains événements apparaîtront ici.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accentOrange,
      backgroundColor: colors.surface,
      onRefresh: _loadEvents,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _events.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _events.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: AppLoader(size: 22)),
            );
          }

          final event = _events[index];
          return _EventCard(event: event);
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      event.eventDate.day.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: context.weight(FontWeight.w800),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _monthShort(event.eventDate.month),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: context.weight(FontWeight.w700),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: context.weight(FontWeight.w700),
                        height: 1.25,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 13,
                          color: AppColors.primaryYellow,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _formatEventDate(event.eventDate),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.accentOrange,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            event.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 12,
                          color: AppColors.accentOrange,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            event.organizerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.accentOrange,
                              fontSize: 11.5,
                              fontWeight: context.weight(FontWeight.w700),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 4, left: 6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: colors.iconMuted,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthShort(int month) {
    const months = [
      'JAN',
      'FÉV',
      'MAR',
      'AVR',
      'MAI',
      'JUIN',
      'JUIL',
      'AOÛ',
      'SEP',
      'OCT',
      'NOV',
      'DÉC',
    ];
    return months[month - 1];
  }
}
