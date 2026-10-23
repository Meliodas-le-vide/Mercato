import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/theme/theme_controller.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:mercato_frontend/features/auth/domain/user_model.dart';
import 'package:mercato_frontend/features/player/data/player_repository.dart';
import 'package:mercato_frontend/features/player/domain/player_profile_model.dart';
import 'package:mercato_frontend/features/player/presentation/video_player_screen.dart';
import 'package:mercato_frontend/features/user/data/notification_repository.dart';
import 'package:mercato_frontend/features/user/data/video_repository.dart';
import 'package:mercato_frontend/features/user/domain/video_model.dart';
import 'package:mercato_frontend/features/user/presentation/explore_screen.dart';
import 'package:mercato_frontend/features/user/presentation/favoris_screen.dart';
import 'package:mercato_frontend/features/user/presentation/notifications_screen.dart';
import 'package:mercato_frontend/features/user/presentation/profile_screen.dart';

String _formatViews(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)} M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)} k';
  return count.toString();
}

String _formatRelativeDate(String iso) {
  final date = DateTime.tryParse(iso);
  if (date == null) return '';

  final diff = DateTime.now().difference(date);
  if (diff.inDays >= 365) {
    final years = (diff.inDays / 365).floor();
    return 'il y a $years an${years > 1 ? 's' : ''}';
  }
  if (diff.inDays >= 30) {
    final months = (diff.inDays / 30).floor();
    return 'il y a $months mois';
  }
  if (diff.inDays >= 1) {
    return 'il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
  }
  if (diff.inHours >= 1) {
    return 'il y a ${diff.inHours} h';
  }
  if (diff.inMinutes >= 1) {
    return 'il y a ${diff.inMinutes} min';
  }
  return 'à l\'instant';
}

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _videoRepository = VideoRepository(DioClient());
  final _storage = const FlutterSecureStorage();
  final _profileRepository = PlayerProfileRepository(DioClient());
  final _notificationRepository = NotificationRepository(DioClient());

  UserModel? _user;
  PlayerProfileModel? profile;
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

      try {
        profile = await _profileRepository.getMe();
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          profile = null;
        } else {
          rethrow;
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(
          () => _userErrorMessage =
              '[DEBUG:status=${e.response?.statusCode}] ${e.response?.data ?? e.message}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _userErrorMessage = '[DEBUG:parsing] $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
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
      if (mounted) {
        setState(() => _isLoadingFeed = false);
      }
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

  String _capitalize(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  /// Message d'accueil selon l'heure de la journée.
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 17) return 'Bon après-midi';
    return 'Bonsoir';
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
                      _isLoadingUser ? 'Chargement…' : _greeting(),
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
                                ? _capitalize(_user!.firstname)
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
                        if ((profile?.city ?? '').isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _CityBadge(
                            city: profile!.city!,
                            color: AppColors.verifiedBadge,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ---- Bouton thème ----
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
        child: RefreshIndicator(
          color: AppColors.accentOrange,
          onRefresh: _loadFeed,
          child: CustomScrollView(
            controller: _feedScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Phrase d'accroche ----
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_userErrorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                _userErrorMessage!,
                                style: TextStyle(
                                  color: colors.error,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          Text(
                            'Découvre les talents qui montent et suis tes joueurs préférés.',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ---- Carrousel de bannières ----
                    const Padding(
                      padding: EdgeInsets.fromLTRB(14, 8, 14, 4),
                      child: _AppPromoBanner(),
                    ),

                    // ---- Catégories ----
                    _CategoryChipsRow(
                      selectedGroup: _selectedGroup,
                      onSelected: (group) =>
                          setState(() => _selectedGroup = group),
                    ),
                  ],
                ),
              ),
              _buildSliverContent(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverContent(AppSemanticColors colors) {
    if (_isLoadingFeed) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: AppLoader()),
      );
    }

    if (_feedErrorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorState(message: _feedErrorMessage!, onRetry: _loadFeed),
      );
    }

    if (_videos.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(
          icon: Icons.videocam_outlined,
          title: 'Aucune vidéo disponible',
          subtitle: 'Reviens plus tard pour découvrir de nouveaux talents.',
        ),
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
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(
          icon: Icons.filter_alt_outlined,
          title: 'Aucune vidéo dans cette catégorie',
          subtitle: 'Essaie une autre catégorie ou reviens plus tard.',
          actionLabel: 'Voir toutes les vidéos',
          onAction: () => setState(() => _selectedGroup = null),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index >= filteredVideos.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: AppLoader(size: 22)),
            );
          }

          final video = filteredVideos[index];
          // Espace vertical entre les cartes, sans marge sur les côtés.
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: VideoCardBlock(
              key: ValueKey(video.id),
              video: video,
              playlist: filteredVideos,
            ),
          );
        }, childCount: filteredVideos.length + (_hasMoreFeed ? 1 : 0)),
      ),
    );
  }
}

class _CityBadge extends StatelessWidget {
  final String city;
  final Color color;

  const _CityBadge({required this.city, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.place_outlined, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            city,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: context.weight(FontWeight.w700),
              letterSpacing: 0.1,
            ),
          ),
        ],
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
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
              child: Icon(icon, size: 34, color: colors.iconMuted),
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
                    borderRadius: BorderRadius.circular(8),
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: colors.surfaceVariant,
              ),
              child: Text(
                'Réessayer',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: context.weight(FontWeight.w600),
                  fontSize: 13,
                ),
              ),
            ),
          ],
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
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accentOrange : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? AppColors.primaryYellow
                      : AppColors.accentOrange,
                ),
              ),
              child: Center(
                child: Text(
                  data.label,
                  style: TextStyle(
                    color: isActive ? colors.background : colors.textSecondary,
                    fontSize: 14,
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

class _PromoSlide {
  final String tag;
  final String title;
  final String subtitle;
  final String imagePath;
  final Color accent;
  final WidgetBuilder destinationBuilder;

  const _PromoSlide({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.accent,
    required this.destinationBuilder,
  });
}

final List<_PromoSlide> _promoSlides = [
  _PromoSlide(
    tag: 'Explorer',
    title: 'Montre ton talent\nau monde entier',
    subtitle: 'Publie tes meilleures actions et fais-toi repérer.',
    imagePath: 'assets/images/1.png',
    accent: AppColors.primaryYellow,
    destinationBuilder: (_) => const ExploreScreen(),
  ),
  _PromoSlide(
    tag: 'Favoris',
    title: 'Suis tes joueurs\npréférés',
    subtitle: 'Ajoute-les en favoris pour ne rater aucune vidéo.',
    imagePath: 'assets/images/2.png',
    accent: AppColors.accentOrange,
    destinationBuilder: (_) => const FavorisScreen(),
  ),
  _PromoSlide(
    tag: 'Profil',
    title: 'Construis ton profil\nde joueur',
    subtitle: 'Poste, niveau, stats : donne envie aux recruteurs.',
    imagePath: 'assets/images/3.png',
    accent: AppColors.verifiedBadge,
    destinationBuilder: (_) => const ProfileScreen(),
  ),
];

class _AppPromoBanner extends StatefulWidget {
  const _AppPromoBanner();

  @override
  State<_AppPromoBanner> createState() => _AppPromoBannerState();
}

class _AppPromoBannerState extends State<_AppPromoBanner> {
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
      final nextPage = (_currentPage + 1) % _promoSlides.length;
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
            itemCount: _promoSlides.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              final slide = _promoSlides[index];

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
                              slide.tag.toUpperCase(),
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
          children: List.generate(_promoSlides.length, (index) {
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
      ],
    );
  }
}

class VideoCardBlock extends StatefulWidget {
  final VideoModel video;

  final List<VideoModel>? playlist;

  const VideoCardBlock({super.key, required this.video, this.playlist});

  @override
  State<VideoCardBlock> createState() => _VideoCardBlockState();
}

class _VideoCardBlockState extends State<VideoCardBlock> {
  final _videoRepository = VideoRepository(DioClient());
  bool _isLiked = false;
  late int _likesCount;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.video.isLiked;
    _likesCount = widget.video.likesCount;
  }

  Future<void> _toggleLike() async {
    final previousLiked = _isLiked;
    final previousCount = _likesCount;

    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      final result = await _videoRepository.toggleLike(widget.video.id);
      if (mounted) {
        setState(() {
          _isLiked = result.liked;
          _likesCount = result.likesCount;
          widget.video.isLiked = result.liked;
          widget.video.likesCount = result.likesCount;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLiked = previousLiked;
          _likesCount = previousCount;
        });
      }
    }
  }

  void _sendGift() {
    AppSnackbar.info(
      context,
      'Les cadeaux aux joueurs arrivent bientôt !',
      title: 'Cadeau',
    );
  }

  Future<void> _openPlayer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VideoPlayerScreen(video: widget.video, playlist: widget.playlist),
      ),
    );

    if (mounted) {
      setState(() {
        _isLiked = widget.video.isLiked;
        _likesCount = widget.video.likesCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final video = widget.video;
    final author = video.author;

    return GestureDetector(
      onTap: _openPlayer,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SizedBox(
          width: double.infinity,
          height: 320,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  video.resolvedThumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: colors.surfaceVariant),
                ),

                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (video.position != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentOrange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                               
                                  Text(
                                    video.position!.toUpperCase(),
                                    style: TextStyle(
                                      color: AppColors.surfaceVariantLight,
                                      fontSize: 10,
                                      fontWeight: context.weight(
                                        FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),

                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: colors.background,
                                backgroundImage:
                                    author?.fullProfileImageUrl != null
                                    ? NetworkImage(author!.fullProfileImageUrl!)
                                    : null,
                                child: author?.fullProfileImageUrl == null
                                    ? Icon(
                                        Icons.person,
                                        size: 12,
                                        color: colors.textSecondary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                (author != null
                                        ? '${author.firstname} ${author.lastname}'
                                        : 'Joueur')
                                    .toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.accentOrange,
                                  fontSize: 13.5,
                                  fontWeight: context.weight(FontWeight.w700),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: context.weight(FontWeight.w700),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              const Icon(
                                Icons.remove_red_eye_rounded,
                                size: 14,
                                color: AppColors.primaryYellow,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_formatViews(video.viewsCount)} vues',
                                style: TextStyle(
                                  color: AppColors.primaryYellow,
                                  fontSize: 12,
                                  fontWeight: context.weight(FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatRelativeDate(video.createdAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ---- Actions : like · commentaires · cadeau ----
                          Row(
                            children: [
                              _CardAction(
                                onTap: _toggleLike,
                                icon: AnimatedScale(
                                  scale: _isLiked ? 1.2 : 1.0,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.elasticOut,
                                  child: Icon(
                                    _isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: _isLiked
                                        ? AppColors.error
                                        : Colors.white,
                                    size: 24,
                                  ),
                                ),
                                label: _formatViews(_likesCount),
                                labelColor: _isLiked
                                    ? AppColors.error
                                    : Colors.white,
                              ),
                              const SizedBox(width: 12),
                              _CardAction(
                                onTap: _openPlayer,
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Colors.white,
                                  size: 23,
                                ),
                                label: _formatViews(video.commentsCount),
                              ),
                              const SizedBox(width: 12),
                              _CardAction(
                                onTap: _sendGift,
                                highlighted: true,
                                icon: const Icon(
                                  Icons.card_giftcard_rounded,
                                  color: AppColors.onGold,
                                  size: 23,
                                ),
                                label: 'Cadeau',
                                labelColor: AppColors.onGold,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pilule d'action sur la carte vidéo (like, commentaires, cadeau).
class _CardAction extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final Color labelColor;
  final bool highlighted;

  const _CardAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor = Colors.white,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: highlighted
              ? const LinearGradient(
                  colors: AppColors.goldGradient,
                  stops: AppColors.goldGradientStops,
                )
              : null,
          color: highlighted ? null : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(24),
          border: highlighted
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 14,
                fontWeight: context.weight(FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
