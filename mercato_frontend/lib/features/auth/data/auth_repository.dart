import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/core/constants/api_endpoints.dart';

import '../../../core/network/dio_client.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final DioClient _dioClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this._dioClient);

  // Inscription
  Future<void> register({
    required String lastname,
    required String firstname,
    required String email,
    required String password,
    required String role,
    required String phone,
  }) async {
    await _dioClient.dio.post(
      ApiEndpoints.register,
      data: {
        'lastname': lastname,
        'firstname': firstname,
        'email': email,
        'password': password,
        'role': role,
        'phone': phone,
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Mot de passe oublié (code à 6 chiffres envoyé par e-mail)
  // ---------------------------------------------------------------------------

  /// Demande l'envoi d'un code de réinitialisation à [email].
  Future<void> forgotPassword(String email) async {
    await _dioClient.dio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  /// Vérifie le [code] reçu par e-mail.
  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    await _dioClient.dio.post(
      ApiEndpoints.verifyResetCode,
      data: {'email': email, 'code': code},
    );
  }

  /// Définit [newPassword] après validation du [code].
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _dioClient.dio.post(
      ApiEndpoints.resetPassword,
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }

  // Connexion
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );

    final String accessToken = response.data['accessToken'];
    final String refreshToken = response.data['refreshToken'];
    final UserModel user = UserModel.fromJson(response.data['user']);

    // 1. Sauvegarde des tokens & rôle
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(key: 'user_role', value: user.role);

    // 2. SAUVEGARDE DES DONNÉES UTILISATEUR
    await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));

    // 3. SAUVEGARDE DU PROFIL JOUEUR (Si l'API le renvoie lors du login)
    if (response.data['profile'] != null) {
      await _storage.write(
        key: 'profile_data',
        value: jsonEncode(response.data['profile']),
      );
    } else {
      // Si l'API ne renvoie pas le profil au login, on va le chercher sur le serveur
      await fetchAndSavePlayerProfile();
    }

    return user;
  }

  // Récupère et sauvegarde le profil depuis le serveur s'il existe
  Future<void> fetchAndSavePlayerProfile() async {
    try {
      // Ajuste la route selon ton backend (ex: ApiEndpoints.myProfile ou /players/me)
      final response = await _dioClient.dio.get('/players/me');
      if (response.data != null) {
        await _storage.write(
          key: 'profile_data',
          value: jsonEncode(response.data),
        );
      }
    } catch (e) {
      // Si le profil n'existe pas encore côté backend
      await _storage.delete(key: 'profile_data');
    }
  }

  // Déconnexion
  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refresh_token');

    try {
      await _dioClient.dio.post(
        ApiEndpoints.logout,
        data: {'refreshToken': refreshToken},
      );
    } finally {
      // Nettoyage complet du stockage local quoi qu'il arrive
      await _storage.deleteAll();
    }
  }

  // Récupérer le rôle stocké
  Future<String?> getUserRole() async {
    return await _storage.read(key: 'user_role');
  }
}
