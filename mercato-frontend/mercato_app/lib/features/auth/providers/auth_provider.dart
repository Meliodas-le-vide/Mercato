import 'package:flutter/material.dart';
import 'package:mercato_app/features/auth/data/auth_service.dart';
import 'package:mercato_app/features/auth/data/models/user_model.dart';


class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  bool _isCheckingAuth = true; //Utilisé au démarrage de l'app (Splash Screen)
  String? _errorMessage;

  //Getters pour consommer l'état dans l'UI
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isCheckingAuth => _isCheckingAuth;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;

  //Vérifie la présence d'une session au lancement de l'application
  Future<void> checkAuthStatus() async {
    _isCheckingAuth = true;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      if (token != null) {
        _user = await _authService.getCurrentUser();
      } else {
        _user = null;
      }
    } catch (e) {
      _user = null;
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  //Inscription d'un nouvel utilisateur
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      password: password,
      role: role,
    );

    _isLoading = false;

    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  //Connexion de l'utilisateur
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(
      email: email,
      password: password,
    );

    _isLoading = false;

    if (result['success']) {
      _user = result['user'];
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  //Deconnexion
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}