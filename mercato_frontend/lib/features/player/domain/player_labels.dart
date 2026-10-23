/// Libellés lisibles pour les valeurs d'énumération stockées côté backend
/// (poste, pied fort, niveau). Partagé entre les écrans d'édition de profil
/// et les écrans d'affichage (détail joueur, carte de résultat de recherche).
class PlayerLabels {
  static const Map<String, String> positions = {
    'GARDIEN': 'Gardien',
    'DEFENSEUR_CENTRAL': 'Défenseur central',
    'LATERAL_DROIT': 'Latéral droit',
    'LATERAL_GAUCHE': 'Latéral gauche',
    'MILIEU_DEFENSIF': 'Milieu défensif',
    'MILIEU_CENTRAL': 'Milieu central',
    'MILIEU_OFFENSIF': 'Milieu offensif',
    'AILIER_DROIT': 'Ailier droit',
    'AILIER_GAUCHE': 'Ailier gauche',
    'ATTAQUANT': 'Attaquant',
  };

  static const Map<String, String> feet = {
    'DROIT': 'Droit',
    'GAUCHE': 'Gauche',
    'AMBIDEXTRE': 'Ambidextre',
  };

  static const Map<String, String> levels = {
    'AMATEUR': 'Amateur',
    'SEMI_PRO': 'Semi-professionnel',
    'PRO': 'Professionnel',
  };

  /// Renvoie le libellé lisible pour [key] dans [map], ou [key] tel quel
  /// (voire [fallback]) si aucune correspondance n'existe.
  static String labelFor(
    Map<String, String> map,
    String? key, {
    String fallback = 'N/C',
  }) {
    if (key == null || key.isEmpty) return fallback;
    return map[key] ?? key;
  }
}
