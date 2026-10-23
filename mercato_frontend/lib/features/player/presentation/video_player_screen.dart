import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/features/user/data/player_search_repository.dart';
import 'package:mercato_frontend/features/user/presentation/detail_screen.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:video_player/video_player.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/features/user/data/video_repository.dart';
import 'package:mercato_frontend/features/user/domain/video_comment_model.dart';
import 'package:mercato_frontend/features/user/domain/video_model.dart';

String _formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
  return count.toString();
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  return '$m:${s.toString().padLeft(2, '0')}';
}

String? _formatYear(String iso) {
  final dt = DateTime.tryParse(iso);
  return dt?.year.toString();
}

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  final List<VideoModel>? playlist;

  const VideoPlayerScreen({super.key, required this.video, this.playlist});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final List<VideoModel> _videos;
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    final playlist = widget.playlist;
    if (playlist != null && playlist.isNotEmpty) {
      _videos = playlist;
      final index = playlist.indexWhere((v) => v.id == widget.video.id);
      _currentIndex = index == -1 ? 0 : index;
    } else {
      _videos = [widget.video];
      _currentIndex = 0;
    }
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        // Le clavier est géré dans le sheet des commentaires.
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _videos.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) => _ReelPage(
                key: ValueKey(_videos[index].id),
                video: _videos[index],
                isActive: index == _currentIndex,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.35),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ReelPage extends StatefulWidget {
  final VideoModel video;
  final bool isActive;

  const _ReelPage({super.key, required this.video, required this.isActive});

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> {
  final _videoRepository = VideoRepository(DioClient());
  final _playerSearchRepository = PlayerSearchRepository(DioClient());

  late VideoPlayerController _controller;
  bool _isVideoReady = false;
  bool _hasViewBeenCounted = false;
  bool _isLoadingProfile = false;
  bool _pausedByUser = false;
  bool _descriptionExpanded = false;

  late bool _liked;
  late int _likesCount;
  late int _viewsCount;
  late int _commentsCount;

  final Map<int, Offset> _hearts = {};
  int _heartSeed = 0;

  @override
  void initState() {
    super.initState();
    _liked = widget.video.isLiked;
    _likesCount = widget.video.likesCount;
    _viewsCount = widget.video.viewsCount;
    _commentsCount = widget.video.commentsCount;

    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
          ..setLooping(true)
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() => _isVideoReady = true);
            if (widget.isActive) _controller.play();
          });

    _controller.addListener(_onVideoPlayerPositionChanged);
  }

  @override
  void didUpdateWidget(covariant _ReelPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive || !_isVideoReady) return;
    if (widget.isActive) {
      _pausedByUser = false;
      _controller.play();
    } else {
      _controller.pause();
    }
  }

  void _onVideoPlayerPositionChanged() {
    if (!mounted || _hasViewBeenCounted) return;
    if (_controller.value.position.inSeconds >= 2) {
      _registerView();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoPlayerPositionChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _registerView() async {
    _hasViewBeenCounted = true;
    try {
      final newCount = await _videoRepository.incrementViews(widget.video.id);
      if (mounted) setState(() => _viewsCount = newCount);
    } catch (e) {
      debugPrint('Erreur incrementViews : $e');
    }
  }

  Future<void> _toggleLike() async {
    final previousLiked = _liked;
    final previousCount = _likesCount;

    setState(() {
      _liked = !_liked;
      _likesCount += _liked ? 1 : -1;
    });

    try {
      final result = await _videoRepository.toggleLike(widget.video.id);
      if (mounted) {
        setState(() {
          _liked = result.liked;
          _likesCount = result.likesCount;
          widget.video.isLiked = result.liked;
          widget.video.likesCount = result.likesCount;
        });
      }
    } catch (e) {
      debugPrint('Erreur toggleLike : $e');
      if (mounted) {
        setState(() {
          _liked = previousLiked;
          _likesCount = previousCount;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (!_isVideoReady) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _pausedByUser = true;
      } else {
        _controller.play();
        _pausedByUser = false;
      }
    });
  }

  void _onDoubleTap(TapDownDetails details) {
    final key = _heartSeed++;
    setState(() => _hearts[key] = details.localPosition);
    if (!_liked) _toggleLike();
  }

  Future<void> _openPlayerProfile() async {
    final authorId = widget.video.author?.id;
    if (authorId == null || _isLoadingProfile) return;

    setState(() => _isLoadingProfile = true);
    try {
      final player = await _playerSearchRepository.getById(authorId);
      if (!mounted) return;
      _controller.pause();
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(player: player)),
      );
      if (mounted && widget.isActive && !_pausedByUser) _controller.play();
    } catch (e) {
      debugPrint('Erreur getById (player) : $e');
      if (mounted) {
        AppSnackbar.error(context, 'Impossible de charger ce profil.');
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _openComments() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        videoId: widget.video.id,
        commentsCount: _commentsCount,
        onCommentAdded: () => setState(() => _commentsCount += 1),
      ),
    );
  }

  void _share() {
    AppSnackbar.info(context, 'Le partage arrive bientôt.');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isPaused = _isVideoReady && !_controller.value.isPlaying;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ---- Vidéo ----
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _togglePlayPause,
          onDoubleTapDown: _onDoubleTap,
          onDoubleTap: () {},
          child: _isVideoReady
              ? _buildVideo()
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    _frame9x16(
                      Image.network(
                        widget.video.resolvedThumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const Center(child: AppLoader()),
                  ],
                ),
        ),

        // ---- Dégradés pour la lisibilité ----
        const _EdgeGradient(top: true, height: 120),
        const _EdgeGradient(top: false, height: 320),

        // ---- Icône pause ----
        if (isPaused)
          IgnorePointer(
            child: Center(
              child: Icon(
                Icons.play_arrow_rounded,
                size: 84,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),

        // ---- Cœurs du double-tap ----
        for (final entry in _hearts.entries)
          _HeartBurst(
            key: ValueKey(entry.key),
            position: entry.value,
            onDone: () => setState(() => _hearts.remove(entry.key)),
          ),

        // ---- Actions à droite (centrées verticalement) ----
        Positioned(
          right: 10,
          top: 0,
          bottom: 0,
          child: Center(child: _buildActionRail()),
        ),

        // ---- Infos en bas à gauche ----
        Positioned(
          left: 16,
          right: 88,
          bottom: bottomInset + 72,
          child: _buildInfo(),
        ),

        // ---- Barre de progression ----
        if (_isVideoReady)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            child: SizedBox(
              height: 14,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: EdgeInsets.zero,
                  colors: VideoProgressColors(
                    playedColor: AppColors.accentOrange,
                    bufferedColor: Colors.white.withValues(alpha: 0.3),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Cadre vertical 9:16 centré : le contenu le remplit (cover) sans
  /// déformation, ce qui dépasse est rogné.
  Widget _frame9x16(Widget child) {
    return Center(
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: ClipRect(child: child),
      ),
    );
  }

  Widget _buildVideo() {
    final size = _controller.value.size;

    return _frame9x16(
      FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width > 0 ? size.width : 9,
          height: size.height > 0 ? size.height : 16,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }

  Widget _buildActionRail() {
    final author = widget.video.author;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar de l'auteur → profil
        GestureDetector(
          onTap: _openPlayerProfile,
          child: SizedBox(
            width: 52,
            height: 60,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: CircleAvatar(
                    radius: 23,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage: author?.Profile_image != null
                        ? NetworkImage(author!.Profile_image!)
                        : null,
                    child: _isLoadingProfile
                        ? const AppLoader(size: 18)
                        : author?.Profile_image == null
                        ? const Icon(
                            Icons.person_rounded,
                            color: Colors.white70,
                            size: 24,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentOrange,
                    ),
                    child: const Icon(
                      Icons.person_search_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _RailButton(
          icon: Icons.favorite_rounded,
          color: _liked ? AppColors.error : Colors.white,
          label: _formatCount(_likesCount),
          onTap: _toggleLike,
        ),
        const SizedBox(height: 16),
        _RailButton(
          icon: Icons.chat_bubble_rounded,
          label: _formatCount(_commentsCount),
          onTap: _openComments,
        ),
        const SizedBox(height: 16),
        _RailButton(
          icon: Icons.reply_rounded,
          mirrored: true,
          label: 'Partager',
          onTap: _share,
        ),
        const SizedBox(height: 16),
        _RailButton(
          icon: Icons.visibility_rounded,
          label: _formatCount(_viewsCount),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    final video = widget.video;
    final author = video.author;
    final description = video.description;
    final year = _formatYear(video.createdAt);

    final meta = [
      if (_isVideoReady) _formatDuration(_controller.value.duration),
      ?year,
    ].join(' · ');

    const shadow = [Shadow(color: Colors.black54, blurRadius: 6)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _openPlayerProfile,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  author != null
                      ? '@${author.firstname} ${author.lastname}'
                      : '@Joueur',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: context.weight(FontWeight.w700),
                    shadows: shadow,
                  ),
                ),
              ),
              if (video.position != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primaryYellow.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    video.position!.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primaryYellow,
                      fontSize: 10.5,
                      fontWeight: context.weight(FontWeight.w700),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          video.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: context.weight(FontWeight.w600),
            height: 1.3,
            shadows: shadow,
          ),
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () =>
                setState(() => _descriptionExpanded = !_descriptionExpanded),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topLeft,
              child: Text(
                description,
                maxLines: _descriptionExpanded ? 8 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13.5,
                  height: 1.4,
                  shadows: shadow,
                ),
              ),
            ),
          ),
        ],
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                meta,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12.5,
                  shadows: shadow,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bouton de la colonne d'actions
// ---------------------------------------------------------------------------

class _RailButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool mirrored;

  const _RailButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = Colors.white,
    this.mirrored = false,
  });

  @override
  Widget build(BuildContext context) {
    const shadow = [Shadow(color: Colors.black54, blurRadius: 8)];

    Widget iconWidget = Icon(icon, size: 34, color: color, shadows: shadow);
    if (mirrored) {
      iconWidget = Transform.flip(flipX: true, child: iconWidget);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: KeyedSubtree(key: ValueKey(color), child: iconWidget),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: context.weight(FontWeight.w600),
                shadows: shadow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dégradé haut / bas
// ---------------------------------------------------------------------------

class _EdgeGradient extends StatelessWidget {
  final bool top;
  final double height;

  const _EdgeGradient({required this.top, required this.height});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: top ? 0 : null,
      bottom: top ? null : 0,
      height: height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: top ? 0.45 : 0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _HeartBurst extends StatefulWidget {
  final Offset position;
  final VoidCallback onDone;

  const _HeartBurst({super.key, required this.position, required this.onDone});

  @override
  State<_HeartBurst> createState() => _HeartBurstState();
}

class _HeartBurstState extends State<_HeartBurst>
    with SingleTickerProviderStateMixin {
  static const double _size = 96;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..forward().whenComplete(widget.onDone);

  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.4,
        end: 1.15,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 35,
    ),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 15),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
  ]).animate(_anim);

  late final Animation<double> _opacity = TweenSequence([
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 35),
  ]).animate(_anim);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - _size / 2,
      top: widget.position.dy - _size / 2,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, child) => Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(0, -30 * _anim.value),
              child: Transform.scale(scale: _scale.value, child: child),
            ),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            size: _size,
            color: AppColors.error,
            shadows: [Shadow(color: Colors.black38, blurRadius: 12)],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Commentaires (bottom sheet) : chargement paginé + envoi
// ---------------------------------------------------------------------------

class _CommentsSheet extends StatefulWidget {
  final int videoId;
  final int commentsCount;
  final VoidCallback onCommentAdded;

  const _CommentsSheet({
    required this.videoId,
    required this.commentsCount,
    required this.onCommentAdded,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _videoRepository = VideoRepository(DioClient());
  final _commentController = TextEditingController();

  late int _commentsCount = widget.commentsCount;
  List<VideoCommentModel> _comments = [];
  bool _isLoadingComments = true;
  bool _isLoadingMoreComments = false;
  int _commentsPage = 1;
  bool _hasMoreComments = true;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final result = await _videoRepository.getComments(
        widget.videoId,
        page: 1,
        limit: 10,
      );
      if (mounted) {
        setState(() {
          _comments = result.items;
          _commentsPage = result.page;
          _hasMoreComments = result.hasMore && result.items.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Erreur getComments : $e');
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _loadMoreComments() async {
    setState(() => _isLoadingMoreComments = true);
    try {
      final result = await _videoRepository.getComments(
        widget.videoId,
        page: _commentsPage + 1,
        limit: 10,
      );
      if (mounted) {
        setState(() {
          _comments.addAll(result.items);
          _commentsPage = result.page;
          _hasMoreComments = result.hasMore && result.items.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Erreur getComments : $e');
    } finally {
      if (mounted) setState(() => _isLoadingMoreComments = false);
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isPostingComment) return;

    setState(() => _isPostingComment = true);
    try {
      final newComment = await _videoRepository.addComment(
        widget.videoId,
        content,
      );
      if (mounted) {
        setState(() {
          _comments.insert(0, newComment);
          _commentsCount += 1;
          _commentController.clear();
        });
        widget.onCommentAdded();
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      debugPrint('Erreur addComment : $e');
      if (mounted) {
        AppSnackbar.error(context, 'Impossible d\'envoyer le commentaire.');
      }
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final height = MediaQuery.of(context).size.height * 0.68;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ---- En-tête ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          '${_formatCount(_commentsCount)} commentaire${_commentsCount > 1 ? 's' : ''}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: context.weight(FontWeight.w700),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: colors.icon),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),

            // ---- Liste ----
            Expanded(
              child: _isLoadingComments
                  ? const Center(child: AppLoader(size: 22))
                  : _comments.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun commentaire pour le moment.\nSois le premier !',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      children: [
                        for (final comment in _comments)
                          _buildCommentTile(comment, colors),
                        if (_hasMoreComments)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: _isLoadingMoreComments
                                  ? const AppLoader(size: 20)
                                  : TextButton(
                                      onPressed: _loadMoreComments,
                                      child: Text(
                                        'Voir plus de commentaires',
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: context.weight(
                                            FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ),
            ),

            _buildCommentInputBar(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(
    VideoCommentModel comment,
    AppSemanticColors colors,
  ) {
    final author = comment.author;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.surfaceVariant,
            backgroundImage: author?.Profile_image != null
                ? NetworkImage(author!.Profile_image!)
                : null,
            child: author?.Profile_image == null
                ? Icon(
                    Icons.person_outline_rounded,
                    color: colors.textSecondary,
                    size: 16,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author != null
                      ? '${author.firstname} ${author.lastname}'
                      : 'Utilisateur',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: context.weight(FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  comment.content,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInputBar(AppSemanticColors colors) {
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.divider)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  minLines: 1,
                  maxLines: 4,
                  controller: _commentController,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ajouter un commentaire…',
                    filled: true,
                    fillColor: colors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: AppColors.accentOrange,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  onSubmitted: (_) => _postComment(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isPostingComment ? null : _postComment,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isPostingComment
                        ? AppColors.accentOrange.withValues(alpha: 0.5)
                        : AppColors.accentOrange,
                    shape: BoxShape.circle,
                  ),
                  child: _isPostingComment
                      ? const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: AppLoader(size: 16),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
