import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mercato_frontend/features/feed/domain/video_comment_model.dart';
import 'package:mercato_frontend/features/feed/domain/video_model.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class VideoRepository {
  final DioClient _dioClient;

  VideoRepository(this._dioClient);

  /// Feed paginé. filter: 'trending' | 'recent' (défaut serveur). position: filtre optionnel par poste.
  Future<List<VideoModel>> getFeed({
    String? filter,
    String? position,
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.videoFeed,
      queryParameters: {
        if (filter != null) 'filter': filter,
        if (position != null) 'position': position,
        'page': page,
        'limit': limit,
      },
    );

    final List data = response.data['data'];
    return data.map((json) => VideoModel.fromJson(json)).toList();
  }

  Future<VideoModel> getVideoById(int id) async {
    final response = await _dioClient.dio.get(ApiEndpoints.videoDetail(id));
    return VideoModel.fromJson(response.data['data']);
  }

  /// Toggle like/unlike. Renvoie l'état à jour.
  Future<({bool liked, int likesCount})> toggleLike(int videoId) async {
    final response = await _dioClient.dio.post(ApiEndpoints.videoLike(videoId));
    return (
      liked: response.data['liked'] as bool,
      likesCount: response.data['likesCount'] as int,
    );
  }

  Future<int> incrementViews(int videoId) async {
    final response = await _dioClient.dio.post(ApiEndpoints.videoViews(videoId));
    return response.data['viewsCount'] as int;
  }

  Future<List<VideoCommentModel>> getComments(int videoId, {int page = 1, int limit = 20}) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.videoComments(videoId),
      queryParameters: {'page': page, 'limit': limit},
    );

    final List data = response.data['data'];
    return data.map((json) => VideoCommentModel.fromJson(json)).toList();
  }

  Future<VideoCommentModel> addComment(int videoId, String content) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.videoComments(videoId),
      data: {'content': content},
    );
    return VideoCommentModel.fromJson(response.data['data']);
  }

  Future<VideoModel> uploadVideo({
    required File videoFile,
    required String title,
    String? description,
    List<String>? tags,
    String? position,
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'video': await MultipartFile.fromFile(videoFile.path),
      'title': title,
      if (description != null) 'description': description,
      if (tags != null) 'tags': tags.join(','),
      if (position != null) 'position': position,
    });

    final response = await _dioClient.dio.post(
      ApiEndpoints.videoUpload,
      data: formData,
      onSendProgress: onProgress,
    );

    return VideoModel.fromJson(response.data['data']);
  }

  Future<void> deleteVideo(int videoId) async {
    await _dioClient.dio.delete(ApiEndpoints.videoDelete(videoId));
  }

  Future<VideoModel> updateVideo(int videoId, {String? description, List<String>? tags}) async {
    final response = await _dioClient.dio.patch(
      ApiEndpoints.videoUpdate(videoId),
      data: {
        if (description != null) 'description': description,
        if (tags != null) 'tags': tags,
      },
    );
    return VideoModel.fromJson(response.data['data']);
  }
Future<List<VideoModel>> getMyVideos() async {
  final response = await _dioClient.dio.get(ApiEndpoints.videoMyVideos); 
  final List data = response.data['data'];
  return data.map((json) => VideoModel.fromJson(json)).toList();
}
}