import 'package:mercato_frontend/features/auth/domain/user_model.dart';

class VideoCommentModel {
  final int id;
  final int videoId;
  final String content;
  final UserModel? author;
  final String createdAt;

  VideoCommentModel({
    required this.id,
    required this.videoId,
    required this.content,
    this.author,
    required this.createdAt,
  });

  factory VideoCommentModel.fromJson(Map<String, dynamic> json) {
    return VideoCommentModel(
      id: json['id'],
      videoId: json['videoId'],
      content: json['content'] ?? '',
      author: json['author'] != null
          ? UserModel.fromJson(json['author'])
          : null,
      createdAt: json['createdAt'] ?? '',
    );
  }
}
