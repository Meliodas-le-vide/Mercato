import 'package:flutter/material.dart';
import 'package:mercato_frontend/core/constants/app_colors.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/theme/app_theme.dart';
import 'package:mercato_frontend/core/widgets/app_loader.dart';
import 'package:mercato_frontend/features/chat/data/chat_repository.dart';
import 'package:mercato_frontend/features/chat/domain/conversation_model.dart';
import 'package:mercato_frontend/features/chat/presentation/chat_screen.dart';
import 'package:mercato_frontend/services/chat_socket_service.dart';

class ConversationsListScreen extends StatefulWidget {
  final int currentUserId;

  const ConversationsListScreen({super.key, required this.currentUserId});

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final _repository = ChatRepository(DioClient());

  List<ConversationModel> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();

    ChatSocketService.instance.onNewMessage((_) {
      if (mounted) _load(silent: true);
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final result = await _repository.getConversations();
      if (mounted) {
        setState(() {
          _conversations = result;
          _errorMessage = null;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('ERREUR CHARGEMENT CONVERSATIONS: $e');
      debugPrint('STACKTRACE: $stackTrace');

      if (mounted && !silent) {
        setState(
          () => _errorMessage = 'Impossible de charger les conversations.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          'MESSAGE',
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
      return _StateView(
        icon: Icons.error_outline_rounded,
        iconColor: colors.error,
        title: 'Oups…',
        subtitle: _errorMessage!,
        actionLabel: 'Réessayer',
        onAction: () => _load(),
      );
    }

    if (_conversations.isEmpty) {
      return _StateView(
        icon: Icons.chat_bubble_outline_rounded,
        iconColor: AppColors.accentOrange,
        title: 'Aucune conversation',
        subtitle:
            'Tes échanges avec les joueurs et recruteurs apparaîtront ici.',
      );
    }

    return RefreshIndicator(
      color: AppColors.accentOrange,
      backgroundColor: colors.surface,
      onRefresh: () => _load(silent: false),
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: _conversations.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, thickness: 1, indent: 76, color: colors.divider),
        itemBuilder: (context, index) {
          final conv = _conversations[index];
          return _ConversationTile(
            conversation: conv,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    currentUserId: widget.currentUserId,
                    otherUser: conv.otherUser,
                  ),
                ),
              );
              _load(silent: true);
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isUnread = conversation.unreadCount > 0;
    final user = conversation.otherUser;

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUnread
                            ? AppColors.accentOrange
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: colors.surfaceVariant,
                      backgroundImage: user.profileImage != null
                          ? NetworkImage(user.profileImage!)
                          : null,
                      child: user.profileImage == null
                          ? Text(
                              user.firstname.isNotEmpty
                                  ? user.firstname[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: AppColors.accentOrange,
                                fontWeight: context.weight(FontWeight.w700),
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                  ),

                  if (isUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _capitalize(user.fullName),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: isUnread
                            ? context.weight(FontWeight.w700)
                            : context.weight(FontWeight.w600),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    Row(
                      children: [
                        if (conversation.lastMessage.messageType != 'text') ...[
                          _MessageTypeIcon(
                            type: conversation.lastMessage.messageType,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            _previewText(conversation),
                            style: TextStyle(
                              color: isUnread
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                              fontWeight: isUnread
                                  ? context.weight(FontWeight.w600)
                                  : FontWeight.w400,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              if (isUnread)
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    conversation.unreadCount > 99
                        ? '99+'
                        : '${conversation.unreadCount}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: context.weight(FontWeight.w700),
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String name) {
    if (name.isEmpty) return name;
    return name
        .split(' ')
        .map(
          (word) =>
              word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  String _previewText(ConversationModel conv) {
    switch (conv.lastMessage.messageType) {
      case 'video_share':
        return 'Vidéo partagée';
      case 'offer':
        return 'Proposition envoyée';
      case 'trial_request':
        return 'Demande d\'essai';
      default:
        return conv.lastMessage.content;
    }
  }
}

class _MessageTypeIcon extends StatelessWidget {
  final String type;

  const _MessageTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (type) {
      case 'video_share':
        icon = Icons.videocam_outlined;
        break;
      case 'offer':
        icon = Icons.local_offer_outlined;
        break;
      case 'trial_request':
        icon = Icons.assignment_outlined;
        break;
      default:
        icon = Icons.chat_bubble_outline_rounded;
    }

    return Icon(icon, size: 14, color: AppColors.accentOrange);
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
