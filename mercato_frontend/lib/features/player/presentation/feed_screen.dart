import 'dart:async';
import 'dart:convert';

import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
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
import 'package:mercato_frontend/features/player/data/player_repository.dart';
import 'package:mercato_frontend/features/player/domain/player_profile_model.dart';
import 'package:mercato_frontend/features/player/presentation/video_player_screen.dart';
import 'package:mercato_frontend/features/user/presentation/home_screen.dart'
    show VideoCardBlock;
import 'package:mercato_frontend/features/user/presentation/notifications_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _videoRepository = VideoRepository(DioClient());
  final _storage = const FlutterSecureStorage();
  final _profileRepository = PlayerProfileRepository(DioClient());
  final _feedScrollController = ScrollController();
  final _myVideosScrollController = ScrollController();
  final _notificationRepository = NotificationRepository(DioClient());

  UserModel? _user;
  PlayerProfileModel? profile;
  List<VideoModel> _videos = [];
  List<VideoModel> _myVideos = [];

  int _unreadNotifications = 0;

  bool _isLoadingFeed = true;
  bool _isLoadingMoreFeed = false;
  String? _feedErrorMessage;
  int _feedPage = 1;
  bool _hasMoreFeed = true;

  bool _isLoadingMyVideos = false;
  bool _isLoadingMoreMyVideos = false;
  int _myVideosPage = 1;
  bool _hasMoreMyVideos = true;

  bool _isLoadingUser = true;
  String? _userErrorMessage;

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _loadMyVideos();
    _loadUserData();
    _loadUnreadNotifications();
    _feedScrollController.addListener(_onFeedScroll);
    _myVideosScrollController.addListener(_onMyVideosScroll);
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

  @override
  void dispose() {
    _feedScrollController.removeListener(_onFeedScroll);
    _feedScrollController.dispose();
    _myVideosScrollController.removeListener(_onMyVideosScroll);
    _myVideosScrollController.dispose();
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

  void _onMyVideosScroll() {
    if (!_hasMoreMyVideos || _isLoadingMoreMyVideos || _isLoadingMyVideos) {
      return;
    }
    final maxScrollExtent = _myVideosScrollController.position.maxScrollExtent;
    if (maxScrollExtent > 0 &&
        _myVideosScrollController.position.pixels >= maxScrollExtent - 400) {
      _loadMoreMyVideos();
    }
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
        setState(() => _user = parsedUser);
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
      debugPrint('Erreur loadUserData: $e');
      if (mounted) {
        setState(() => _userErrorMessage = 'Erreur de chargement');
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

  Future<void> _loadMyVideos() async {
    setState(() => _isLoadingMyVideos = true);
    try {
      final result = await _videoRepository.getMyVideos(page: 1);
      if (mounted) {
        setState(() {
          _myVideos = result.items;
          _myVideosPage = result.page;
          _hasMoreMyVideos = result.hasMore && result.items.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de mes vidéos : $e');
    } finally {
      if (mounted) setState(() => _isLoadingMyVideos = false);
    }
  }

  Future<void> _loadMoreMyVideos() async {
    setState(() => _isLoadingMoreMyVideos = true);
    try {
      final result = await _videoRepository.getMyVideos(
        page: _myVideosPage + 1,
      );
      if (mounted) {
        setState(() {
          _myVideos.addAll(result.items);
          _myVideosPage = result.page;
          _hasMoreMyVideos = result.hasMore && result.items.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement mes vidéos: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMoreMyVideos = false);
    }
  }

  String _capitalize(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  /// 👉 Message d'accueil selon l'heure de la journée
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

      // ============================================================
      // APPBAR — Avatar + Bonjour + Prénom + Badge ville + Bouton thème
      // ============================================================
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colors.background,
        toolbarHeight: 76,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // ---- Avatar ----
              _MiniAvatar(imageUrl: _user?.fullProfileImageUrl, size: 44),
              const SizedBox(width: 12),

              // ---- Bonjour + Prénom + badge ville ----
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
              const SizedBox(width: 8),

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
          onRefresh: _selectedTab == 0 ? _loadFeed : _loadMyVideos,
          child: CustomScrollView(
            controller: _selectedTab == 0
                ? _feedScrollController
                : _myVideosScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============================================================
                    // Phrase d'accroche (le "Bonjour + prénom" est dans l'AppBar)
                    // ============================================================
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
                            'Mets en avant ton talent en publiant tes meilleures actions et fais-toi repérer par les recruteurs.',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ============================================================
                    // Carrousel de bannières
                    // ============================================================
                    const Padding(
                      padding: EdgeInsets.fromLTRB(14, 8, 14, 4),
                      child: _ImageBannerCarousel(),
                    ),

                    // ============================================================
                    // Onglets Feed / Mes vidéos
                    // ============================================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              title: 'Feed',
                              isSelected: _selectedTab == 0,
                              onTap: () => setState(() => _selectedTab = 0),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TabButton(
                              title: 'Mes vidéos',
                              isSelected: _selectedTab == 1,
                              onTap: () {
                                setState(() => _selectedTab = 1);
                                if (_myVideos.isEmpty) {
                                  _loadMyVideos();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
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
    final isMyVideos = _selectedTab == 1;

    if (isMyVideos) {
      if (_isLoadingMyVideos) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: AppLoader()),
        );
      }

      if (_myVideos.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
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
                    child: Icon(
                      Icons.video_library_outlined,
                      size: 32,
                      color: colors.iconMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Aucune vidéo publiée',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: context.weight(FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tes vidéos publiées apparaîtront ici.',
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
          ),
        );
      }

      return SliverMainAxisGroup(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return _MyVideoGridCard(
                  video: _myVideos[index],
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerScreen(
                          video: _myVideos[index],
                          playlist: _myVideos,
                        ),
                      ),
                    );
                    _loadMyVideos();
                  },
                );
              }, childCount: _myVideos.length),
            ),
          ),
          if (_hasMoreMyVideos)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: AppLoader(size: 22)),
              ),
            ),
        ],
      );
    }

    if (_isLoadingFeed) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: AppLoader()),
      );
    }

    if (_feedErrorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colors.error,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  _feedErrorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _loadFeed,
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
        ),
      );
    }

    if (_videos.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
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
                  child: Icon(
                    Icons.videocam_outlined,
                    size: 32,
                    color: colors.iconMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Aucune vidéo disponible',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: context.weight(FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Reviens plus tard pour découvrir de nouveaux talents.',
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
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index >= _videos.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: AppLoader(size: 22)),
            );
          }

          return Padding(
            // Pleine largeur : espace vertical entre les cartes uniquement.
            padding: const EdgeInsets.only(bottom: 16),
            child: VideoCardBlock(
              key: ValueKey(_videos[index].id),
              video: _videos[index],
              playlist: _videos,
            ),
          );
        }, childCount: _videos.length + (_hasMoreFeed ? 1 : 0)),
      ),
    );
  }
}

// ============================================================================
// MINI AVATAR
// ============================================================================
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

// ============================================================================
// CITY BADGE (pastille avec icône + ville)
// ============================================================================
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

// ============================================================================
// TAB BUTTON
// ============================================================================
class _TabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryYellow
                : AppColors.accentOrange,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? colors.background : colors.textSecondary,
            fontWeight: isSelected
                ? context.weight(FontWeight.w700)
                : FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BANNIÈRE
// ============================================================================
class _BannerSlide {
  final String image;
  final String title;
  final String subtitle;
  final Color accent;

  const _BannerSlide({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.accent,
  });
}

const List<_BannerSlide> _bannerSlides = [
  _BannerSlide(
    image: 'assets/images/1.png',
    title: 'Vis le football à 200 %',
    subtitle: 'Découvre les meilleures actions et partage les tiennes.',
    accent: AppColors.primaryYellow,
  ),
  _BannerSlide(
    image: 'assets/images/2.png',
    title: 'Montre ton talent',
    subtitle: 'Publie tes vidéos et fais-toi remarquer par les recruteurs.',
    accent: AppColors.accentOrange,
  ),
  _BannerSlide(
    image: 'assets/images/3.png',
    title: 'Rejoins la communauté',
    subtitle: 'Like et commente les vidéos des autres joueurs.',
    accent: AppColors.verifiedBadge,
  ),
];

class _ImageBannerCarousel extends StatefulWidget {
  const _ImageBannerCarousel();

  @override
  State<_ImageBannerCarousel> createState() => _ImageBannerCarouselState();
}

class _ImageBannerCarouselState extends State<_ImageBannerCarousel> {
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
      final nextPage = (_currentPage + 1) % _bannerSlides.length;
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
            itemCount: _bannerSlides.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              final slide = _bannerSlides[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(slide.image, fit: BoxFit.cover),
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
                            'MON TALENT',
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
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_bannerSlides.length, (index) {
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

// ============================================================================
// MY VIDEO GRID CARD
// ============================================================================
class _MyVideoGridCard extends StatefulWidget {
  final VideoModel video;
  final VoidCallback onTap;

  const _MyVideoGridCard({required this.video, required this.onTap});

  @override
  State<_MyVideoGridCard> createState() => _MyVideoGridCardState();
}

class _MyVideoGridCardState extends State<_MyVideoGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final video = widget.video;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.resolvedThumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: colors.surfaceVariant),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              video.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: context.weight(FontWeight.w600),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.favorite_rounded, size: 12, color: colors.iconMuted),
                const SizedBox(width: 3),
                Text(
                  '${video.likesCount}',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
