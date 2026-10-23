import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mercato_frontend/features/auth/domain/user_model.dart';
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

  /// Indique si le joueur connecté a rempli les champs obligatoires de son
  /// profil (poste, niveau, date de naissance, ville).
  /// Profil inexistant (404) → false. Autre erreur (réseau…) → true, pour
  /// ne pas bloquer l'accès à l'app à cause d'un souci de connexion.
  Future<bool> isProfileComplete() async {
    try {
      final profile = await getMe();
      return profile.isProfileComplete;
    } on DioException catch (e) {
      return e.response?.statusCode != 404;
    }
  }

  /// Met à jour (ou crée, si premier remplissage) le profil joueur.
  /// Si un simple utilisateur ("fan") vient de compléter son profil, le
  /// backend le promeut automatiquement au rôle PLAYER : `user` reflète
  /// alors ce nouveau rôle pour que l'appelant resynchronise le cache local.
  Future<({PlayerProfileModel profile, UserModel? user})> updateMe(
    PlayerProfileModel profile,
  ) async {
    final response = await _dioClient.dio.put(
      ApiEndpoints.playerMe,
      data: profile.toUpdateJson(),
    );
    return (
      profile: PlayerProfileModel.fromJson(response.data['data']),
      user: response.data['user'] != null
          ? UserModel.fromJson(response.data['user'])
          : null,
    );
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
