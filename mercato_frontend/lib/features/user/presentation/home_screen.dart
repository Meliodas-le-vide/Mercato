import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/features/auth/domain/user_model.dart';
import 'package:mercato_frontend/features/player/data/player_repository.dart';
import 'package:mercato_frontend/features/player/domain/player_profile_model.dart';
import 'package:mercato_frontend/features/player/presentation/video_player_screen.dart';
import 'package:mercato_frontend/features/user/data/video_repository.dart';
import 'package:mercato_frontend/features/user/domain/video_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color darkBlue = Color(0xFF0F2137);

  final _videoRepository = VideoRepository(DioClient());
  final _storage = const FlutterSecureStorage();
  final _profileRepository = PlayerProfileRepository(DioClient());

  UserModel? _user;
  PlayerProfileModel? profile;
  List<VideoModel> _videos = [];

  bool _isLoadingFeed = true;
  String? _feedErrorMessage;

  bool _isLoadingUser = true;
  String? _userErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _loadUserData();
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
      if (mounted) {
        setState(() => _userErrorMessage = '[DEBUG:status=${e.response?.statusCode}] ${e.response?.data ?? e.message}');
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
      final videos = await _videoRepository.getFeed(limit: 500);
      videos.shuffle(Random());

      if (mounted) {
        setState(() => _videos = videos);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _feedErrorMessage = 'Impossible de charger le feed pour le moment.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFeed = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: darkBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'MERCATO',
          style: TextStyle(
            color: primaryYellow,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoadingUser
                              ? 'Chargement...'
                              : (_user != null
                                  ? 'Bienvenu, ${_user!.firstname.toUpperCase()}'
                                  : 'Bienvenu, PRÉNOM'),
                          style: const TextStyle(
                            color: darkBlue,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_userErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _userErrorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 10),
                            ),
                          ),
                        const SizedBox(height: 2),
                        const Text(
                          'Sur notre application où vous pouvez mettre en avant vos talents footballistiques',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
           
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // Widget _buildHeaderCircleButton({
  //   required Widget child,
  //   required VoidCallback onTap,
  // }) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       width: 50,
  //       height: 50,
  //       decoration: const BoxDecoration(
  //         color: primaryYellow,
  //         shape: BoxShape.circle,
  //       ),
  //       alignment: Alignment.center,
  //       child: ClipOval(child: child),
  //     ),
  //   );
  // }

  Widget _buildBody() {
    if (_isLoadingFeed) {
      return const Center(child: CircularProgressIndicator(color: darkBlue));
    }

    if (_feedErrorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            Text(_feedErrorMessage!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadFeed,
              child: const Text('Réessayer', style: TextStyle(color: darkBlue)),
            ),
          ],
        ),
      );
    }

    if (_videos.isEmpty) {
      return const Center(
        child: Text(
          'Aucune vidéo disponible.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
      );
    }

    return RefreshIndicator(
      color: darkBlue,
      onRefresh: _loadFeed,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          return VideoCardBlock(
            key: ValueKey(_videos[index].id),
            video: _videos[index],
          );
        },
      ),
    );
  }
}

class VideoCardBlock extends StatefulWidget {
  final VideoModel video;

  const VideoCardBlock({super.key, required this.video});

  @override
  State<VideoCardBlock> createState() => _VideoCardBlockState();
}

class _VideoCardBlockState extends State<VideoCardBlock> {
  final _videoRepository = VideoRepository(DioClient());
  bool _isLiked = false;
  late int _likesCount;

  static const Color primaryYellow = Color(0xFFFFD600);

  @override
  void initState() {
    super.initState();
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

  Future<void> _openPlayer() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: widget.video)),
    );

    if (result != null && mounted) {
      setState(() {
        if (result.containsKey('liked')) {
          _isLiked = result['liked'] as bool;
        }
        if (result.containsKey('likesCount')) {
          _likesCount = result['likesCount'] as int;
          widget.video.likesCount = _likesCount;
        }
      });
    }
  }

  String _resolveThumbnail(VideoModel video) {
    if (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty) {
      return video.thumbnailUrl!;
    }
    final url = video.videoUrl;
    if (url.contains('res.cloudinary.com')) {
      final lastDot = url.lastIndexOf('.');
      if (lastDot != -1) {
        final withoutExt = url.substring(0, lastDot);
        return '${withoutExt.replaceFirst('/upload/', '/upload/so_1/')}.jpg';
      }
    }
    return 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800';
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final author = video.author;

    return Container(
      margin: const EdgeInsets.only(bottom: 19),
      height: 205,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(_resolveThumbnail(video)),
          fit: BoxFit.cover,
        ),
      ),
      child: GestureDetector(
        onTap: _openPlayer,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: author?.Profile_image != null
                        ? NetworkImage(author!.Profile_image!)
                        : null,
                    child: author?.Profile_image == null
                        ? const Icon(Icons.person, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    author != null ? '${author.firstname} ${author.lastname}' : 'Joueur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                ],
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: primaryYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.black, size: 24),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleLike,
                      child: Row(
                        children: [
                          Icon(
                            _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_likesCount',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${video.commentsCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
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
    );
  }
}