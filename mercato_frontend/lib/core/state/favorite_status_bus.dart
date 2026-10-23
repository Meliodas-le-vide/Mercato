import 'package:flutter/foundation.dart';

/// Diffuse les changements d'état "favori" à toutes les `PlayerResultCard`
/// actuellement montées pour un même joueur.
///
/// Nécessaire car Explorer / Favoris / etc. chargent chacun leur propre copie
/// indépendante des résultats (des appels API séparés, pas le même objet),
/// et restent montés simultanément (IndexedStack). Sans ce bus, mettre à jour
/// une carte ne prévient pas les autres cartes du même joueur ailleurs dans
/// l'app, qui restent figées sur leur ancien état.
class FavoriteStatusBus {
  FavoriteStatusBus._();
  static final instance = FavoriteStatusBus._();

  final ValueNotifier<MapEntry<int, bool>?> _lastChange = ValueNotifier(null);

  MapEntry<int, bool>? get lastChange => _lastChange.value;

  void notify(int playerId, bool isFavorited) {
    _lastChange.value = MapEntry(playerId, isFavorited);
  }

  void addListener(VoidCallback listener) => _lastChange.addListener(listener);

  void removeListener(VoidCallback listener) =>
      _lastChange.removeListener(listener);
}
