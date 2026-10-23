import 'package:mercato_frontend/features/auth/domain/user_model.dart';

enum NotificationType { newVideo, newFavorite, unknown }

NotificationType _typeFromString(String? raw) {
  switch (raw) {
    case 'NEW_VIDEO':
      return NotificationType.newVideo;
    case 'NEW_FAVORITE':
      return NotificationType.newFavorite;
    default:
      return NotificationType.unknown;
  }
}

class NotificationModel {
  final int id;
  final NotificationType type;
  final String message;
  final bool isRead;
  final int? videoId;
  final UserModel? actor;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    this.videoId,
    this.actor,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: _typeFromString(json['type']),
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      videoId: json['videoId'] ?? json['video']?['id'],
      actor: json['actor'] != null ? UserModel.fromJson(json['actor']) : null,
      createdAt: json['createdAt'] ?? '',
    );
  }
}
