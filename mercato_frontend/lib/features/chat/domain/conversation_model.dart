class ChatUserSummary {
  final int id;
  final String firstname;
  final String lastname;
  final String? profileImage;

  ChatUserSummary({
    required this.id,
    required this.firstname,
    required this.lastname,
    this.profileImage,
  });

  String get fullName => '$firstname $lastname'.trim();

  factory ChatUserSummary.fromJson(Map<String, dynamic> json) {
    return ChatUserSummary(
      id: json['id'],
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      profileImage: json['profileImage'],
    );
  }
}

class LastMessageSummary {
  final int id;
  final String content;
  final String messageType;
  final int senderId;
  final DateTime createdAt;

  LastMessageSummary({
    required this.id,
    required this.content,
    required this.messageType,
    required this.senderId,
    required this.createdAt,
  });

  factory LastMessageSummary.fromJson(Map<String, dynamic> json) {
    return LastMessageSummary(
      id: json['id'],
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'text',
      senderId: json['senderId'],
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ConversationModel {
  final ChatUserSummary otherUser;
  final LastMessageSummary lastMessage;
  final int unreadCount;

  ConversationModel({
    required this.otherUser,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      otherUser: ChatUserSummary.fromJson(json['otherUser']),
      lastMessage: LastMessageSummary.fromJson(json['lastMessage']),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
