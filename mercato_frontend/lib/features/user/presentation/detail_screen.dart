import 'dart:convert';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/gold_button.dart';
import 'package:mercato_frontend/core/widgets/report_sheet.dart';
import 'package:mercato_frontend/features/auth/domain/user_model.dart';
import 'package:mercato_frontend/features/chat/domain/conversation_model.dart';
import 'package:mercato_frontend/features/chat/presentation/chat_screen.dart';
import 'package:mercato_frontend/features/player/domain/player_labels.dart';
import 'package:mercato_frontend/features/player/presentation/video_player_screen.dart';
import 'package:mercato_frontend/features/recruiter/data/recruiter_profile_repository.dart';
import 'package:mercato_frontend/features/recruiter/domain/recruiter_profile_model.dart';
import 'package:mercato_frontend/features/user/data/video_repository.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';
import 'package:mercato_frontend/features/user/domain/video_model.dart';

class DetailScreen extends StatefulWidget {
  final PlayerSearchResult player;

  const DetailScreen({super.key, required this.player});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  final _videoRepository = VideoRepository(DioClient());
  final _recruiterProfileRepository = RecruiterProfileRepository(DioClient());
  late final AnimationController _controller;
  late final Animation<double> _animation;

  String? _viewerRole;
  bool? _recruiterVerified;

  List<VideoModel> _videos = [];
  bool _isLoadingVideos = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _loadViewerRole();
    _loadVideos();
  }

  Future<void> _loadViewerRole() async {
    final userJson = await _storage.read(key: 'user_data');
    if (userJson == null || !mounted) return;
    final user = UserModel.fromJson(jsonDecode(userJson));
    setState(() => _viewerRole = user.role);

    if (user.role == 'RECRUITER' || user.role == 'CLUB_AGENT') {
      _loadRecruiterVerification();
    }
  }

  Future<void> _loadRecruiterVerification() async {
    RecruiterVerificationStatus status = RecruiterVerificationStatus.pending;
    try {
      final profile = await _recruiterProfileRepository.getMe();
      status = profile.verificationStatus;
    } catch (_) {}
    if (mounted) setState(() => _recruiterVerified = status.isVerified);
  }

  Future<void> _loadVideos() async {
    try {
      final result = await _videoRepository.getPlayerVideos(
        widget.player.user.id,
      );
      if (mounted) setState(() => _videos = result.items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingVideos = false);
    }
  }

  void _openVideo(VideoModel video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(video: video, playlist: _videos),
      ),
    );
  }

  Future<void> _contactPlayer() async {
    final userJson = await _storage.read(key: 'user_data');
    if (userJson == null || !mounted) return;

    final currentUser = UserModel.fromJson(jsonDecode(userJson));
    final currentUserId = currentUser.id;

    final targetUser = widget.player.user;
    final otherUserSummary = ChatUserSummary(
      id: targetUser.id,
      firstname: targetUser.firstname,
      lastname: targetUser.lastname,
      profileImage: targetUser.Profile_image,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          currentUserId: currentUserId,
          otherUser: otherUserSummary,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final player = widget.player;
    final profile = player.profile;
    final user = player.user;
    final hasImage =
        user.Profile_image != null && user.Profile_image!.isNotEmpty;
    final hasClub =
        profile.currentClub != null && profile.currentClub!.trim().isNotEmpty;
    final imageHeight = MediaQuery.of(context).size.height * 0.42;
    final canContact =
        _viewerRole == 'RECRUITER' || _viewerRole == 'CLUB_AGENT';

    return Scaffold(
      backgroundColor: colors.background,
      bottomNavigationBar: canContact ? _buildContactBar(colors) : null,
      body: Column(
        children: [
          SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'player-avatar-${user.id}',
                  child: ScaleTransition(
                    scale: _animation,
                    child: hasImage
                        ? Image.network(
                            user.Profile_image!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: colors.surfaceVariant,
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 80,
                                color: colors.iconMuted,
                              ),
                            ),
                          )
                        : Container(
                            color: colors.surfaceVariant,
                            child: Icon(
                              Icons.person_outline_rounded,
                              size: 80,
                              color: colors.iconMuted,
                            ),
                          ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 90,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, colors.background],
                        ),
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => showReportSheet(
                            context,
                            targetUserId: user.id,
                            targetLabel: player.fullName,
                          ),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.flag_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 500),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            PlayerLabels.labelFor(
                              PlayerLabels.positions,
                              profile.position,
                              fallback: 'POSTE N/C',
                            ).toUpperCase(),
                            style: TextStyle(
                              color: colors.background,
                              fontWeight: context.weight(FontWeight.w700),
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            profile.currentClub ?? 'Sans club',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      player.fullName,
                      style: TextStyle(
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: context.weight(FontWeight.w700),
                        letterSpacing: -0.5,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  FadeInDown(
                    duration: const Duration(milliseconds: 700),
                    delay: const Duration(milliseconds: 150),
                    child: Text(
                      [
                        if (player.age != null) '${player.age} ans',
                        if (profile.city?.isNotEmpty ?? false) profile.city!,
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // -------- Bio --------
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    FadeInDown(
                      duration: const Duration(milliseconds: 750),
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        profile.bio!,
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (hasClub) ...[
                    Row(
                      children: [
                        Expanded(
                          child: FadeInLeft(
                            duration: const Duration(milliseconds: 750),
                            delay: const Duration(milliseconds: 200),
                            child: _buildStatBadge(
                              colors,
                              title: '${profile.goals}',
                              label: 'Buts',
                              icon: Icons.sports_soccer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 750),
                            delay: const Duration(milliseconds: 250),
                            child: _buildStatBadge(
                              colors,
                              title: '${profile.matchesPlayed}',
                              label: 'Matchs',
                              icon: Icons.sports,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FadeInRight(
                            duration: const Duration(milliseconds: 750),
                            delay: const Duration(milliseconds: 300),
                            child: _buildStatBadge(
                              colors,
                              title: '${profile.assists}',
                              label: 'Passes D.',
                              icon: Icons.handshake_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  FadeInUp(
                    duration: const Duration(milliseconds: 750),
                    delay: const Duration(milliseconds: 300),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (profile.height != null)
                          _buildInfoChip(
                            colors,
                            icon: Icons.height,
                            label: '${profile.height} cm',
                          ),
                        if (profile.weight != null)
                          _buildInfoChip(
                            colors,
                            icon: Icons.monitor_weight_outlined,
                            label: '${profile.weight} kg',
                          ),
                        if (profile.strongFoot != null)
                          _buildInfoChip(
                            colors,
                            icon: Icons.sports_soccer_outlined,
                            label: PlayerLabels.labelFor(
                              PlayerLabels.feet,
                              profile.strongFoot,
                            ),
                          ),
                        if (profile.city != null && profile.city!.isNotEmpty)
                          _buildInfoChip(
                            colors,
                            icon: Icons.location_on_outlined,
                            label: profile.city!,
                          ),
                        if (profile.country != null &&
                            profile.country!.isNotEmpty)
                          _buildInfoChip(
                            colors,
                            icon: Icons.flag_outlined,
                            label: profile.country!,
                          ),
                      ],
                    ),
                  ),

                  if (!_isLoadingVideos && _videos.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    FadeInUp(
                      duration: const Duration(milliseconds: 750),
                      delay: const Duration(milliseconds: 350),
                      child: _buildVideosSection(colors),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosSection(AppSemanticColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Vidéos',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 17,
                fontWeight: context.weight(FontWeight.w700),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${_videos.length})',
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _videos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final video = _videos[index];
              return GestureDetector(
                onTap: () => _openVideo(video),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 140,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
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
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.55),
                                  ],
                                ),
                              ),
                            ),

                            const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Titre
                    SizedBox(
                      width: 130,
                      child: Text(
                        video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactBar(AppSemanticColors colors) {
    final isVerified = _recruiterVerified ?? false;
    final isLoading = _recruiterVerified == null;

    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: isVerified
              ? GoldButton(
                  height: 46,
                  width: double.infinity,
                  fontSize: 14,
                  icon: Icons.chat_bubble_outline,
                  label: 'Contacter ce joueur',
                  onPressed: _contactPlayer,
                )
              : Container(
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.textSecondary,
                          ),
                        )
                      else ...[
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 15,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Compte en attente de vérification',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(
    AppSemanticColors colors, {
    required String title,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accentOrange, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: context.weight(FontWeight.w700),
              letterSpacing: -0.3,
              color: colors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    AppSemanticColors colors, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accentOrange, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
