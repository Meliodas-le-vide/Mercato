import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/features/player/presentation/video_player_screen.dart';
import 'package:mercato_frontend/features/user/data/notification_repository.dart';
import 'package:mercato_frontend/features/user/data/video_repository.dart';
import 'package:mercato_frontend/features/user/domain/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationRepository = NotificationRepository(DioClient());
  final _videoRepository = VideoRepository(DioClient());
  final _scrollController = ScrollController();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int? _openingVideoId;

  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _notificationRepository.getMyNotifications(page: 1);
      if (mounted) {
        setState(() {
          _notifications = result.items;
          _page = result.page;
          _hasMore = result.hasMore && result.items.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement notifications : $e');
      if (mounted)
        setState(
          () => _errorMessage = 'Impossible de charger tes notifications.',
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final result = await _notificationRepository.getMyNotifications(
        page: _page + 1,
      );
      if (mounted) {
        setState(() {
          _notifications.addAll(result.items);
          _page = result.page;
          _hasMore = result.hasMore && result.items.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement notifications : $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _markAllAsRead() async {
    final hasUnread = _notifications.any((n) => !n.isRead);
    if (!hasUnread) return;

    setState(() {
      _notifications = _notifications
          .map(
            (n) => NotificationModel(
              id: n.id,
              type: n.type,
              message: n.message,
              isRead: true,
              videoId: n.videoId,
              actor: n.actor,
              createdAt: n.createdAt,
            ),
          )
          .toList();
    });

    try {
      await _notificationRepository.markAllAsRead();
    } catch (e) {
      debugPrint('Erreur markAllAsRead : $e');
    }
  }

  Future<void> _onTapNotification(NotificationModel notification) async {
    if (!notification.isRead) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: notification.id,
            type: notification.type,
            message: notification.message,
            isRead: true,
            videoId: notification.videoId,
            actor: notification.actor,
            createdAt: notification.createdAt,
          );
        }
      });
      try {
        await _notificationRepository.markAsRead(notification.id);
      } catch (e) {
        debugPrint('Erreur markAsRead : $e');
      }
    }

    if (notification.type == NotificationType.newVideo &&
        notification.videoId != null) {
      setState(() => _openingVideoId = notification.videoId);
      try {
        final video = await _videoRepository.getVideoById(
          notification.videoId!,
        );
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
          );
        }
      } catch (e) {
        debugPrint('Erreur ouverture vidéo depuis notification : $e');
        if (mounted) {
          AppSnackbar.error(context, 'Cette vidéo n\'est plus disponible.');
        }
      } finally {
        if (mounted) setState(() => _openingVideoId = null);
      }
    }
  }

  String _formatRelativeDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '';

    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 30) return 'il y a ${(diff.inDays / 30).floor()} mois';
    if (diff.inDays >= 1) return 'il y a ${diff.inDays} j';
    if (diff.inHours >= 1) return 'il y a ${diff.inHours} h';
    if (diff.inMinutes >= 1) return 'il y a ${diff.inMinutes} min';
    return 'à l\'instant';
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.newVideo:
        return Icons.play_circle_fill;
      case NotificationType.newFavorite:
        return Icons.favorite;
      case NotificationType.unknown:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: semantic.background,
      appBar: AppBar(
        title: Text(
          'NOTIFICATIONS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: context.weight(FontWeight.bold),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Tout marquer lu',
                style: TextStyle(
                  color: AppColors.primaryYellow,
                  fontSize: 14,
                  fontWeight: context.weight(FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(semantic),
    );
  }

  Widget _buildBody(AppSemanticColors semantic) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryYellow),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _load,
              child: Text(
                'Réessayer',
                style: TextStyle(color: semantic.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_none,
                color: AppColors.primaryYellow,
                size: 100,
              ),
              const SizedBox(height: 12),
              Text(
                'Aucune notification pour le moment.\nMets des joueurs en favori pour être averti de leurs nouvelles vidéos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: semantic.textSecondary, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryYellow,
      onRefresh: _load,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _notifications.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= _notifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryYellow,
                  ),
                ),
              ),
            );
          }

          final notification = _notifications[index];
          final isOpeningThis =
              _openingVideoId == notification.videoId &&
              notification.videoId != null;

          return Material(
            color: notification.isRead
                ? semantic.surface
                : AppColors.primaryYellow.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: isOpeningThis
                  ? null
                  : () => _onTapNotification(notification),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: semantic.background,
                          backgroundImage:
                              notification.actor?.fullProfileImageUrl != null
                              ? NetworkImage(
                                  notification.actor!.fullProfileImageUrl!,
                                )
                              : null,
                          child: notification.actor?.fullProfileImageUrl == null
                              ? Icon(
                                  Icons.person,
                                  color: semantic.textSecondary,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryYellow,
                              border: Border.all(
                                color: semantic.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _iconFor(notification.type),
                              size: 11,
                              color: AppColors.onGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.message,
                            style: TextStyle(
                              color: semantic.textPrimary,
                              fontSize: 13.5,
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : context.weight(FontWeight.w700),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatRelativeDate(notification.createdAt),
                            style: TextStyle(
                              color: semantic.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOpeningThis)
                      const Padding(
                        padding: EdgeInsets.only(left: 8, top: 4),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryYellow,
                          ),
                        ),
                      )
                    else if (!notification.isRead)
                      Container(
                        margin: const EdgeInsets.only(left: 8, top: 4),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
