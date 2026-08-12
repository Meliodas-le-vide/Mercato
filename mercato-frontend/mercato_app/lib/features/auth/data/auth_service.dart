import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_app/core/constants/api_constants.dart';
import 'package:mercato_app/features/auth/data/models/user_model.dart';


class AuthService {
  final _storage = const FlutterSecureStorage();

  //Clés de stockage
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  //Inscription
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstname': firstName,
          'lastname': lastName,
          'email': email,
          'phone': phone,
          'password': password,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Compte créé avec succès'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'inscription',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Impossible de contacter le serveur'};
    }
  }

  //Connexion
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        //Sauvegarde du token
        if (data['accessToken'] != null) {
          await _storage.write(key: _tokenKey, value: data['accessToken']);
        }

        //Sauvegarde et parsing de l'utilisateur
        UserModel? user;
        if (data['user'] != null) {
          user = UserModel.fromJson(data['user']);
          await _storage.write(
            key: _userKey,
            value: jsonEncode(user.toJson()),
          );
        }

        return {
          'success': true,
          'user': user,
          'token': data['accessToken'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Identifiants incorrects',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Impossible de contacter le serveur'};
    }
  }

  //Récupérer le token stocké
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
  

  //Récupérer l'utilisateur connecté 
  Future<UserModel?> getCurrentUser() async {
    try {
      final userStr = await _storage.read(key: _userKey);
      if (userStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(userStr);
        return UserModel.fromJson(userMap);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  //Déconnexion
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}