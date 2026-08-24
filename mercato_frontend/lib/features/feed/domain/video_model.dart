import 'package:mercato_frontend/features/auth/domain/user_model.dart';

class VideoModel {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final List<String> tags;
  final String? position;
  final String videoUrl;
  final String? thumbnailUrl;
  final int viewsCount;
  int likesCount;
  final int commentsCount;
  final UserModel? author;
  final String createdAt;

  VideoModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.tags = const [],
    this.position,
    required this.videoUrl,
    this.thumbnailUrl,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.author,
    required this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'] ?? '',
      description: json['description'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      position: json['position'],
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      viewsCount: json['viewsCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      author: json['author'] != null ? UserModel.fromJson(json['author']) : null,
      createdAt: json['createdAt'] ?? '',
    );
  }
}