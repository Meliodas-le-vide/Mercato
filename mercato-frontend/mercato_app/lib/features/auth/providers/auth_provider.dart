// lib/features/auth/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:mercato_app/features/auth/data/auth_service.dart';
import 'package:mercato_app/features/auth/data/models/user_model.dart';


class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();

  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;

  bool get isCheckingAuth => _isCheckingAuth;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  /// Appelé au démarrage de l'app (voir main.dart)
  Future<void> checkAuthStatus() async {
    _isCheckingAuth = true;
    notifyListeners();

    try {
      final accessToken = await _storage.read(key: 'accessToken');

      if (accessToken == null) {
        _isAuthenticated = false;
      } else if (JwtDecoder.isExpired(accessToken)) {
        // access token expiré -> on tente un refresh silencieux
        final refreshed = await _authService.tryRefresh();
        if (refreshed) {
          await _loadUserFromStorage();
          _isAuthenticated = true;
        } else {
          await _authService.clearSession();
          _isAuthenticated = false;
        }
      } else {
        await _loadUserFromStorage();
        _isAuthenticated = true;
      }
    } catch (e) {
      _isAuthenticated = false;
    }

    _isCheckingAuth = false;
    notifyListeners();
  }

  Future<void> _loadUserFromStorage() async {
    final userJson = await _authService.getStoredUser();
    if (userJson != null) {
      _user = userJson;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _authService.login(email, password);
      _user = UserModel.fromJson(data['user']);
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(
        firstname: firstname,
        lastname: lastname,
        email: email,
        password: password,
        role: role,
        phone: phone,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  String _extractErrorMessage(dynamic e) {
    
    try {
      final response = (e as dynamic).response;
      if (response != null && response.data['message'] != null) {
        return response.data['message'];
      }
    } catch (_) {}
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}