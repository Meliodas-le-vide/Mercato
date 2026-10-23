import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/widgets/app_snackbar.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/features/chat/data/chat_repository.dart';
import 'package:mercato_frontend/features/chat/domain/conversation_model.dart';
import 'package:mercato_frontend/features/chat/domain/message_model.dart';
import 'package:mercato_frontend/services/chat_socket_service.dart';

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final ChatUserSummary otherUser;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _repository = ChatRepository(DioClient());
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _socket = ChatSocketService.instance;

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _otherUserTyping = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _listenSocket();
    _repository.markConversationAsRead(widget.otherUser.id);
  }

  @override
  void dispose() {
    _socket.clearListeners();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _repository.getConversationHistory(
        widget.otherUser.id,
      );
      if (mounted) {
        setState(() => _messages = history);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Erreur loadHistory: $e');
      if (mounted) {
        _showErrorSnackBar('Impossible de charger la conversation.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _listenSocket() {
    _socket.onNewMessage((message) {
      final belongsHere =
          (message.senderId == widget.otherUser.id &&
              message.receiverId == widget.currentUserId) ||
          (message.senderId == widget.currentUserId &&
              message.receiverId == widget.otherUser.id);
      if (!belongsHere || !mounted) return;

      setState(() => _messages.add(message));
      _scrollToBottom();

      if (message.senderId == widget.otherUser.id) {
        _repository.markConversationAsRead(widget.otherUser.id);
      }
    });

    _socket.onUserTyping((userId) {
      if (userId == widget.otherUser.id && mounted) {
        setState(() => _otherUserTyping = true);
      }
    });

    _socket.onUserStoppedTyping((userId) {
      if (userId == widget.otherUser.id && mounted) {
        setState(() => _otherUserTyping = false);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final content = _textController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();
    _socket.notifyStopTyping(widget.otherUser.id);

    try {
      await _socket.sendMessage(
        receiverId: widget.otherUser.id,
        content: content,
      );
    } catch (e) {
      try {
        final sent = await _repository.sendMessageRest(
          receiverId: widget.otherUser.id,
          content: content,
        );
        if (mounted) {
          setState(() => _messages.add(sent));
          _scrollToBottom();
        }
      } catch (_) {
        if (mounted) {
          _showErrorSnackBar('Échec de l\'envoi du message.');
        }
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showErrorSnackBar(String message) {
    AppSnackbar.error(context, message);
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
        toolbarHeight: 64,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.icon,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentOrange.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: colors.surfaceVariant,
                backgroundImage: widget.otherUser.profileImage != null
                    ? NetworkImage(widget.otherUser.profileImage!)
                    : null,
                child: widget.otherUser.profileImage == null
                    ? const Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: AppColors.accentOrange,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.otherUser.fullName,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: context.weight(FontWeight.w600),
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  if (_otherUserTyping)
                    Text(
                      'En train d\'écrire…',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.accentOrange,
                        fontWeight: context.weight(FontWeight.w600),
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Text(
                      'Vu récemment',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList(colors)),
          _buildInputField(colors),
        ],
      ),
    );
  }

  Widget _buildMessagesList(AppSemanticColors colors) {
    if (_isLoading) return const Center(child: AppLoader());

    if (_messages.isEmpty) {
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
                  Icons.chat_bubble_outline_rounded,
                  size: 32,
                  color: AppColors.accentOrange,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Commence la conversation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: context.weight(FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Envoie ton premier message à ${widget.otherUser.firstname}.',
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

    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.72;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMine = msg.isMine(widget.currentUserId);

        final showDate =
            index == 0 ||
            !_isSameDay(_messages[index - 1].createdAt, msg.createdAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDate) _buildDateSeparator(msg.createdAt, colors),
            _buildMessageBubble(
              msg: msg,
              isMine: isMine,
              maxWidth: maxBubbleWidth,
              colors: colors,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required MessageModel msg,
    required bool isMine,
    required double maxWidth,
    required AppSemanticColors colors,
  }) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primaryYellow : colors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null : Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                color: isMine ? AppColors.onGold : colors.textPrimary,
                fontSize: 14.5,
                height: 1.35,
              ),
            ),

            ...[
              const SizedBox(height: 3),
              Text(
                _formatTime(msg.createdAt),
                style: TextStyle(
                  color: isMine
                      ? AppColors.onGold.withValues(alpha: 0.6)
                      : colors.textTertiary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime? dt, AppSemanticColors colors) {
    final label = _formatDate(dt);
    if (label.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: context.weight(FontWeight.w600),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(AppSemanticColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildCircleAction(icon: Icons.mic_none_rounded, onTap: () {}),
            const SizedBox(width: 8),

            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accentOrange.withValues(alpha: 0.15),
                  ),
                ),
                child: TextField(
                  minLines: 1,
                  maxLines: 4,
                  controller: _textController,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14.5,
                    height: 1.35,
                  ),
                  onChanged: (text) {
                    if (text.isNotEmpty) {
                      _socket.notifyTyping(widget.otherUser.id);
                    } else {
                      _socket.notifyStopTyping(widget.otherUser.id);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Écris ton message…',
                    hintStyle: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            GestureDetector(
              onTap: _isSending ? null : _handleSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isSending
                      ? AppColors.accentOrange.withValues(alpha: 0.5)
                      : AppColors.accentOrange,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: AppLoader(size: 18),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.accentOrange.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.accentOrange, size: 22),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dt.year, dt.month, dt.day);

    final diff = today.difference(dateOnly).inDays;
    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';

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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  bool _isSameDay(DateTime? d1, DateTime? d2) {
    if (d1 == null || d2 == null) return false;
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
