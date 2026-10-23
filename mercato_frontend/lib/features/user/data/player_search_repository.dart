import 'package:mercato_frontend/core/constants/api_endpoints.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/network/paginated_result.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';

class PlayerSearchRepository {
  final DioClient _dioClient;

  PlayerSearchRepository(this._dioClient);

  /// Recherche unifiée : sans [query], retourne tous les joueurs
  /// complets dans un ordre aléatoire (géré côté backend).
  /// Avec [query], le backend filtre sur prénom OU nom OU poste.
  ///
  /// [seed] doit rester le même entre les pages d'une même session de
  /// recherche pour que l'ordre aléatoire soit stable (sinon la pagination
  /// répète ou saute des résultats d'une page à l'autre).
  Future<PaginatedResult<PlayerSearchResult>> search({
    String? query,
    String? position,
    String? level,
    String? city,
    int page = 1,
    int limit = 20,
    int? seed,
  }) async {
    final Map<String, dynamic> queryParams = {
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (position != null && position.isNotEmpty) 'position': position,
      if (level != null && level.isNotEmpty) 'level': level,
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (seed != null) 'seed': seed,
      'page': page,
      'limit': limit,
    };

    final response = await _dioClient.dio.get(
      ApiEndpoints.playerSearch,
      queryParameters: queryParams,
    );

    return PaginatedResult.fromJson(response.data, PlayerSearchResult.fromJson);
  }

  /// Récupère le profil complet d'un joueur précis, dans le même format
  /// qu'un résultat de [search], pour l'afficher sur DetailScreen.
  Future<PlayerSearchResult> getById(int userId) async {
    final response = await _dioClient.dio.get(ApiEndpoints.playerById(userId));
    return PlayerSearchResult.fromJson(response.data['data']);
  }
}
