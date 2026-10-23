import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/theme/theme_controller.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/features/auth/domain/user_model.dart';
import 'package:mercato_frontend/features/user/data/notification_repository.dart';
import 'package:mercato_frontend/features/user/data/video_repository.dart';
import 'package:mercato_frontend/features/user/domain/video_model.dart';
import 'package:mercato_frontend/features/user/presentation/favoris_screen.dart';
import 'package:mercato_frontend/features/user/presentation/home_screen.dart'
    show VideoCardBlock;
import 'package:mercato_frontend/features/user/presentation/notifications_screen.dart';
import 'package:mercato_frontend/features/recruiter/presentation/recruiter_profile_screen.dart';
import 'package:mercato_frontend/features/recruiter/presentation/recruiter_search_screen.dart';

class _PositionGroup {
  static const gardien = 'GARDIEN';
  static const defenseur = 'DEFENSEUR';
  static const milieu = 'MILIEU';
  static const attaquant = 'ATTAQUANT';

  static String? groupFor(String? rawPosition) {
    if (rawPosition == null) return null;
    if (rawPosition == 'GARDIEN') return gardien;
    if (rawPosition.startsWith('DEFENSEUR') ||
        rawPosition.startsWith('LATERAL')) {
      return defenseur;
    }
    if (rawPosition.startsWith('MILIEU')) return milieu;
    if (rawPosition.startsWith('AILIER') || rawPosition == 'ATTAQUANT') {
      return attaquant;
    }
    return null;
  }
}

class RecruiterHomeScreen extends StatefulWidget {
  const RecruiterHomeScreen({super.key});

  @override
  State<RecruiterHomeScreen> createState() => _RecruiterHomeScreenState();
}

class _RecruiterHomeScreenState extends State<RecruiterHomeScreen> {
  final _videoRepository = VideoRepository(DioClient());
  final _storage = const FlutterSecureStorage();
  final _notificationRepository = NotificationRepository(DioClient());

  UserModel? _user;
  List<VideoModel> _videos = [];
  final _feedScrollController = ScrollController();

  bool _isLoadingFeed = true;
  bool _isLoadingMoreFeed = false;
  String? _feedErrorMessage;

  bool _isLoadingUser = true;
  String? _userErrorMessage;

  String? _selectedGroup;

  int _feedPage = 1;
  bool _hasMoreFeed = true;

  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _loadUserData();
    _loadUnreadNotifications();
    _feedScrollController.addListener(_onFeedScroll);
  }

  @override
  void dispose() {
    _feedScrollController.removeListener(_onFeedScroll);
    _feedScrollController.dispose();
    super.dispose();
  }

  void _onFeedScroll() {
    if (!_hasMoreFeed || _isLoadingMoreFeed || _isLoadingFeed) return;
    final maxScrollExtent = _feedScrollController.position.maxScrollExtent;
    if (maxScrollExtent > 0 &&
        _feedScrollController.position.pixels >= maxScrollExtent - 400) {
      _loadMoreFeed();
    }
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final count = await _notificationRepository.getUnreadCount();
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (e) {
      debugPrint('Erreur getUnreadCount : $e');
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    _loadUnreadNotifications();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUser = true;
      _userErrorMessage = null;
    });

    try {
      final userJson = await _storage.read(key: 'user_data');
      if (userJson != null) {
        final parsedUser = UserModel.fromJson(jsonDecode(userJson));
        if (mounted) setState(() => _user = parsedUser);
      }
    } catch (e) {
      debugPrint('Erreur loadUserData: $e');
      if (mounted) {
        setState(() => _userErrorMessage = 'Erreur de chargement');
      }
    } finally {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoadingFeed = true;
      _feedErrorMessage = null;
    });

    try {
      final result = await _videoRepository.getFeed(page: 1);
      if (mounted) {
        setState(() {
          _videos = result.items;
          _feedPage = result.page;
          _hasMoreFeed = result.hasMore && result.items.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _feedErrorMessage =
              'Impossible de charger le feed pour le moment.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingFeed = false);
    }
  }

  Future<void> _loadMoreFeed() async {
    setState(() => _isLoadingMoreFeed = true);
    try {
      final result = await _videoRepository.getFeed(page: _feedPage + 1);
      if (mounted) {
        setState(() {
          _videos.addAll(result.items);
          _feedPage = result.page;
          _hasMoreFeed = result.hasMore && result.items.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement feed: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMoreFeed = false);
    }
  }

  /// Message d'accueil selon l'heure de la journée.
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 17) return 'Bon après-midi';
    return 'Bonsoir';
  }

  String _capitalize(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
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
        backgroundColor: colors.background,
        toolbarHeight: 76,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 20, right: 8),
          child: Row(
            children: [
              _MiniAvatar(imageUrl: _user?.fullProfileImageUrl, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLoadingUser ? 'Chargement…' : '${_greeting()} ',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _user != null
                                ? '${_capitalize(_user!.firstname)} '
                                      '${_capitalize(_user!.lastname)}'
                                : 'Bienvenue',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 17,
                              fontWeight: context.weight(FontWeight.w800),
                              letterSpacing: -0.3,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Recruteur',
                            style: TextStyle(
                              color: AppColors.accentOrange,
                              fontSize: 10.5,
                              fontWeight: context.weight(FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  context.isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  size: 22,
                ),
                color: colors.iconMuted,
                tooltip: context.isDark ? 'Mode clair' : 'Mode sombre',
                onPressed: () => ThemeController.instance.toggle(),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_userErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _userErrorMessage!,
                        style: TextStyle(color: colors.error, fontSize: 10),
                      ),
                    ),
                  Text(
                    'Découvre les talents qui montent et repère tes futures recrues.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            _CategoryChipsRow(
              selectedGroup: _selectedGroup,
              onSelected: (group) => setState(() => _selectedGroup = group),
            ),

            Expanded(child: _buildBody(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppSemanticColors colors) {
    if (_isLoadingFeed) {
      return const Center(child: AppLoader());
    }

    if (_feedErrorMessage != null) {
      return _StateView(
        icon: Icons.error_outline_rounded,
        iconColor: colors.error,
        title: 'Oups…',
        subtitle: _feedErrorMessage!,
        actionLabel: 'Réessayer',
        onAction: _loadFeed,
      );
    }

    if (_videos.isEmpty) {
      return const _StateView(
        icon: Icons.videocam_outlined,
        iconColor: AppColors.accentOrange,
        title: 'Aucune vidéo disponible',
        subtitle: 'Reviens plus tard pour découvrir de nouveaux talents.',
      );
    }

    final filteredVideos = _selectedGroup == null
        ? _videos
        : _videos
              .where(
                (v) => _PositionGroup.groupFor(v.position) == _selectedGroup,
              )
              .toList();

    if (filteredVideos.isEmpty) {
      return _StateView(
        icon: Icons.filter_alt_outlined,
        iconColor: AppColors.accentOrange,
        title: 'Aucune vidéo dans cette catégorie',
        subtitle: 'Essaie une autre catégorie ou reviens plus tard.',
        actionLabel: 'Voir toutes les vidéos',
        onAction: () => setState(() => _selectedGroup = null),
      );
    }

    final showLoadMoreFooter = _hasMoreFeed;

    return RefreshIndicator(
      color: AppColors.accentOrange,
      backgroundColor: colors.surface,
      onRefresh: _loadFeed,
      child: ListView.builder(
        controller: _feedScrollController,
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredVideos.length + 2 + (showLoadMoreFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _RecruiterPromoBanner();
          }

          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Text(
                '${filteredVideos.length} vidéo${filteredVideos.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          if (index - 2 >= filteredVideos.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: AppLoader(size: 22)),
            );
          }

          final video = filteredVideos[index - 2];
          // Pleine largeur : espace vertical entre les cartes uniquement.
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: VideoCardBlock(
              key: ValueKey(video.id),
              video: video,
              playlist: filteredVideos,
            ),
          );
        },
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _MiniAvatar({required this.imageUrl, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceVariant,
        border: Border.all(color: colors.border),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(imageUrl!, fit: BoxFit.cover)
            : Icon(
                Icons.person_outline_rounded,
                size: size * 0.55,
                color: colors.textSecondary,
              ),
      ),
    );
  }
}

class _CategoryChipData {
  final String label;
  final IconData icon;
  final String? group;

  const _CategoryChipData(this.label, this.icon, this.group);
}

const List<_CategoryChipData> _categoryChips = [
  _CategoryChipData('Toutes', Icons.apps_rounded, null),
  _CategoryChipData(
    'Gardien',
    Icons.sports_handball_rounded,
    _PositionGroup.gardien,
  ),
  _CategoryChipData(
    'Défenseur',
    Icons.shield_rounded,
    _PositionGroup.defenseur,
  ),
  _CategoryChipData('Milieu', Icons.hub_rounded, _PositionGroup.milieu),
  _CategoryChipData(
    'Attaquant',
    Icons.sports_soccer_rounded,
    _PositionGroup.attaquant,
  ),
];

class _CategoryChipsRow extends StatelessWidget {
  final String? selectedGroup;
  final ValueChanged<String?> onSelected;

  const _CategoryChipsRow({
    required this.selectedGroup,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _categoryChips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final data = _categoryChips[index];
          final isActive = selectedGroup == data.group;

          return GestureDetector(
            onTap: () => onSelected(data.group),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? colors.textPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? colors.textPrimary : colors.border,
                ),
              ),
              child: Center(
                child: Text(
                  data.label,
                  style: TextStyle(
                    color: isActive ? colors.background : colors.textSecondary,
                    fontSize: 13,
                    fontWeight: isActive
                        ? context.weight(FontWeight.w700)
                        : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StateView extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateView({
    required this.icon,
    required this.iconColor,
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
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: iconColor),
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

class _PromoSlide {
  final String badge;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final String imagePath;
  final Color accent;
  final WidgetBuilder destinationBuilder;

  const _PromoSlide({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.imagePath,
    required this.accent,
    required this.destinationBuilder,
  });
}

final List<_PromoSlide> _recruiterPromoSlides = [
  _PromoSlide(
    badge: 'RECRUTEMENT',
    title: 'Trouve la prochaine\npépite du foot',
    subtitle: 'Explore les profils et filtre selon tes critères.',
    buttonLabel: 'Rechercher des joueurs',
    imagePath: 'assets/images/1.png',
    accent: AppColors.primaryYellow,
    destinationBuilder: (_) => const RecruiterSearchScreen(),
  ),
  _PromoSlide(
    badge: 'FAVORIS',
    title: 'Suis tes joueurs\nrepérés',
    subtitle: 'Retrouve facilement les profils que tu as mis de côté.',
    buttonLabel: 'Voir mes favoris',
    imagePath: 'assets/images/2.png',
    accent: AppColors.verifiedBadge,
    destinationBuilder: (_) => const FavorisScreen(),
  ),
  _PromoSlide(
    badge: 'PROFIL',
    title: 'Complète ton profil\nrecruteur',
    subtitle: 'Un profil vérifié inspire confiance aux joueurs.',
    buttonLabel: 'Mon profil',
    imagePath: 'assets/images/3.png',
    accent: AppColors.accentOrange,
    destinationBuilder: (_) => const RecruiterProfileScreen(),
  ),
];

class _RecruiterPromoBanner extends StatefulWidget {
  const _RecruiterPromoBanner();

  @override
  State<_RecruiterPromoBanner> createState() => _RecruiterPromoBannerState();
}

class _RecruiterPromoBannerState extends State<_RecruiterPromoBanner> {
  late final PageController _pageController = PageController(
    viewportFraction: 0.92,
  );
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % _recruiterPromoSlides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        SizedBox(
          height: 175,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _recruiterPromoSlides.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              final slide = _recruiterPromoSlides[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: slide.destinationBuilder),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(slide.imagePath, fit: BoxFit.cover),

                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.55),
                                slide.accent.withValues(alpha: 0.35),
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              stops: const [0.0, 0.4, 0.7, 1.0],
                            ),
                          ),
                        ),

                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: slide.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              slide.badge,
                              style: TextStyle(
                                color: slide.accent == AppColors.primaryYellow
                                    ? AppColors.onGold
                                    : Colors.white,
                                fontSize: 9,
                                fontWeight: context.weight(FontWeight.w800),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                slide.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: context.weight(FontWeight.w700),
                                  height: 1.15,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                slide.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_recruiterPromoSlides.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryYellow
                    : colors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
