import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final ThemeController instance = ThemeController._internal();
  ThemeController._internal();

  static const String _key = 'theme_mode';

  /// Par défaut : mode sombre.
  final ValueNotifier<ThemeMode> modeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.dark,
  );

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Raccourcis pratiques
  bool get isDark => modeNotifier.value == ThemeMode.dark;
  bool get isLight => modeNotifier.value == ThemeMode.light;

  /// Charge le thème sauvegardé au démarrage.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    modeNotifier.value = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark, // défaut : sombre
    };
    _loaded = true;
  }

  /// Change le thème et le persiste.
  Future<void> setMode(ThemeMode mode) async {
    modeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_key, value);
  }

  /// Bascule entre clair et sombre.
  Future<void> toggle() {
    final next = modeNotifier.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    return setMode(next);
  }
}
