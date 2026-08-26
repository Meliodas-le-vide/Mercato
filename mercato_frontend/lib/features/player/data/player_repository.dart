import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mercato_frontend/features/user/domain/video_model.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/player_profile_model.dart';


class PlayerProfileRepository {
  final DioClient _dioClient;

  PlayerProfileRepository(this._dioClient);

  /// Récupère le profil joueur connecté
  Future<PlayerProfileModel> getMe() async {
    final response = await _dioClient.dio.get(ApiEndpoints.playerMe);
    return PlayerProfileModel.fromJson(response.data['data']);
  }

  /// Met à jour (ou crée, si premier remplissage) le profil joueur
  Future<PlayerProfileModel> updateMe(PlayerProfileModel profile) async {
    final response = await _dioClient.dio.put(
      ApiEndpoints.playerMe,
      data: profile.toUpdateJson(),
    );
    return PlayerProfileModel.fromJson(response.data['data']);
  }

  /// Upload de la photo de profil
  Future<String> uploadAvatar(File imageFile) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(imageFile.path),
    });

    final response = await _dioClient.dio.post(
      ApiEndpoints.playerAvatar,
      data: formData,
    );

    return response.data['profileImage'] as String;
  }

  /// Vidéos publiées par le joueur connecté
  Future<List<VideoModel>> getMyVideos() async {
    final response = await _dioClient.dio.get(ApiEndpoints.videoMyVideos);
    final List data = response.data['data'];
    return data.map((json) => VideoModel.fromJson(json)).toList();
  }

  /// Statistiques sportives du joueur
  Future<Map<String, dynamic>> getStats() async {
    final response = await _dioClient.dio.get(ApiEndpoints.playerStats);
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Mise à jour des statistiques
  Future<Map<String, dynamic>> updateStats({
    int? goals,
    int? assists,
    int? matchesPlayed,
    int? cardsYellow,
    int? cardsRed,
  }) async {
    final response = await _dioClient.dio.put(
      ApiEndpoints.playerStats,
      data: {
        if (goals != null) 'goals': goals,
        if (assists != null) 'assists': assists,
        if (matchesPlayed != null) 'matchesPlayed': matchesPlayed,
        if (cardsYellow != null) 'cardsYellow': cardsYellow,
        if (cardsRed != null) 'cardsRed': cardsRed,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Vue d'ensemble de la performance des vidéos du joueur
  Future<Map<String, dynamic>> getAnalytics() async {
    final response = await _dioClient.dio.get(ApiEndpoints.playerAnalytics);
    return response.data['data'] as Map<String, dynamic>;
  }
}