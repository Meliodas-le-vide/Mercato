import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/features/user/data/video_repository.dart';
import 'package:mercato_frontend/features/user/domain/video_comment_model.dart';
import 'package:mercato_frontend/features/user/domain/video_model.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  static const Color primaryYellow = Color(0xFFFFD600);
  static const Color darkBlue = Color(0xFF0F2137);

  final _videoRepository = VideoRepository(DioClient());
  final _commentController = TextEditingController();

  late VideoPlayerController _controller;
  bool _isVideoReady = false;
  bool _hasViewBeenCounted = false;
  bool _showControls = true;

  bool _liked = false;
  late int _likesCount;
  late int _viewsCount;
  late int _commentsCount;

  List<VideoCommentModel> _comments = [];
  bool _isLoadingComments = true;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.video.likesCount;
    _viewsCount = widget.video.viewsCount;
    _commentsCount = widget.video.commentsCount;

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _isVideoReady = true);
        _controller.play();
      });

    _controller.addListener(_onVideoPlayerPositionChanged);
    _loadComments();
  }

  void _onVideoPlayerPositionChanged() {
    if (!mounted) return;
    setState(() {});

    if (!_hasViewBeenCounted && _controller.value.position.inSeconds >= 2) {
      _registerView();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoPlayerPositionChanged);
    _controller.dispose();
    _commentController.dispose();
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

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final list = await _videoRepository.getComments(widget.video.id);
      if (mounted) {
        setState(() {
          _comments = list;
          _commentsCount = list.length;
        });
      }
    } catch (e) {
      debugPrint('Erreur getComments : $e');
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isPostingComment) return;

    setState(() => _isPostingComment = true);
    try {
      final newComment = await _videoRepository.addComment(widget.video.id, content);
      if (mounted) {
        setState(() {
          _comments.insert(0, newComment);
          _commentsCount += 1;
          _commentController.clear();
        });
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      debugPrint('Erreur addComment : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'envoyer le commentaire.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final author = video.author;

    return Scaffold(
      backgroundColor: darkBlue,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 400,
              child: Container(
                color: Colors.black,
                child: _isVideoReady
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _showControls = !_showControls),
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: _controller.value.aspectRatio > 0
                                    ? _controller.value.aspectRatio
                                    : 16 / 9,
                                child: VideoPlayer(_controller),
                              ),
                            ),
                          ),
                          if (_showControls)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _controller.value.isPlaying
                                      ? _controller.pause()
                                      : _controller.play();
                                });
                              },
                              child: Container(
                                color: Colors.black38,
                                child: Icon(
                                  _controller.value.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: primaryYellow,
                                  size: 56,
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: primaryYellow,
                                bufferedColor: Colors.white24,
                                backgroundColor: Colors.white10,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
                              onPressed: () => Navigator.pop(context, {
                                'liked': _liked,
                                'likesCount': _likesCount,
                              }),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: primaryYellow),
                      ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatCount(_viewsCount)} vues',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white10,
                          backgroundImage: author?.Profile_image != null
                              ? NetworkImage(author!.Profile_image!)
                              : null,
                          child: author?.Profile_image == null
                              ? const Icon(Icons.person, color: Colors.white54, size: 18)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                author != null
                                    ? '${author.firstname} ${author.lastname}'
                                    : 'Joueur',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (video.position != null)
                                Text(
                                  video.position!.toUpperCase(),
                                  style: const TextStyle(
                                    color: primaryYellow,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildActionButton(
                            icon: _liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            label: _formatCount(_likesCount),
                            color: _liked ? primaryYellow : Colors.white,
                            onTap: _toggleLike,
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.chat_bubble_outline,
                            label: _formatCount(_commentsCount),
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.share_outlined,
                            label: 'Partager',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (video.description != null && video.description!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          video.description!,
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Divider(color: Colors.white12),
                    Text(
                      'Commentaires ($_commentsCount)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingComments)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: primaryYellow),
                        ),
                      )
                    else if (_comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Aucun commentaire pour le moment.',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildCommentTile(_comments[index]);
                        },
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1828),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Ajouter un commentaire...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _postComment(),
                    ),
                  ),
                  IconButton(
                    icon: _isPostingComment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: primaryYellow),
                          )
                        : const Icon(Icons.send_rounded, color: primaryYellow),
                    onPressed: _isPostingComment ? null : _postComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(VideoCommentModel comment) {
    final author = comment.author;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.white10,
          backgroundImage: author?.Profile_image != null ? NetworkImage(author!.Profile_image!) : null,
          child: author?.Profile_image == null
              ? const Icon(Icons.person, color: Colors.white54, size: 14)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author != null ? '${author.firstname} ${author.lastname}' : 'Utilisateur',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                comment.content,
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}