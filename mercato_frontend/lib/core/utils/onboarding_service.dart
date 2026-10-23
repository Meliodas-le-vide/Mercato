import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _keyIsFirstTime = 'is_first_time_user';

  /// Vérifie si l'utilisateur ouvre l'application pour la première fois
  static Future<bool> isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    // Par défaut, renvoie true si la clé n'existe pas encore
    return prefs.getBool(_keyIsFirstTime) ?? true;
  }

  /// Marque l'onboarding comme complété (pour ne plus l'afficher)
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsFirstTime, false);
  }
}
