/// Libellés lisibles pour les valeurs d'énumération du profil recruteur
/// (type de structure). Même logique que PlayerLabels côté joueur.
class RecruiterLabels {
  static const Map<String, String> organizationTypes = {
    'CLUB': 'Club',
    'AGENCE': 'Agence de recrutement',
    'CENTRE_FORMATION': 'Centre de formation',
    'INDEPENDANT': 'Indépendant / Freelance',
  };

  static String labelFor(
    Map<String, String> map,
    String? key, {
    String fallback = 'N/C',
  }) {
    if (key == null || key.isEmpty) return fallback;
    return map[key] ?? key;
  }
}
