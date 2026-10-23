class MessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final bool isRead;
  final String
  messageType; // 'text' | 'video_share' | 'offer' | 'trial_request'
  final int? relatedVideoId;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.messageType,
    this.relatedVideoId,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'] ?? '',
      isRead: json['isRead'] ?? false,
      messageType: json['messageType'] ?? 'text',
      relatedVideoId: json['relatedVideoId'],
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Utilitaire pour l'affichage dans le chat : est-ce que CE message
  /// a été envoyé par l'utilisateur actuellement connecté ?
  bool isMine(int currentUserId) => senderId == currentUserId;
}
