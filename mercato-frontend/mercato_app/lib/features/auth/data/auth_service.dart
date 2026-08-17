
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_app/core/constants/api_constants.dart';
import 'package:mercato_app/features/auth/data/models/user_model.dart';
import 'package:mercato_app/services/api_client.dart';


class AuthService {
  final ApiClient _api = ApiClient();
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    required String role, 
    String? phone,
  }) async {
    final response = await _api.dio.post(ApiConstants.register, data: {
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'password': password,
      'role': role,
      'phone': phone,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });

    final data = response.data;
    await _storage.write(key: 'accessToken', value: data['accessToken']);
    await _storage.write(key: 'refreshToken', value: data['refreshToken']);
    await _storage.write(key: 'userRole', value: data['user']['role']);
    // await _storage.write(key: 'userData', value: jsonEncode(data['user']));
    return data;
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    try {
      await _api.dio.post(ApiConstants.logout, data: {'refreshToken': refreshToken});
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'accessToken');
    return token != null;
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: 'userRole');
  }

    Future<bool> tryRefresh() async {
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken == null) return false;

      final response = await _api.dio.post('/auth/refresh-token', data: {
        'refreshToken': refreshToken,
      });

      await _storage.write(key: 'accessToken', value: response.data['accessToken']);
      await _storage.write(key: 'refreshToken', value: response.data['refreshToken']);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  // Stocke le user en JSON pour le retrouver après un redémarrage de l'app
  Future<UserModel?> getStoredUser() async {
    final raw = await _storage.read(key: 'userData');
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw));
  }
  
}