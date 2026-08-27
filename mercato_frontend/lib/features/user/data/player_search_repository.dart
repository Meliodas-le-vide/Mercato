import 'package:mercato_frontend/core/constants/api_endpoints.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';

class PlayerSearchRepository {
  final DioClient _dioClient;

  PlayerSearchRepository(this._dioClient);

  /// Recherche unifiée : sans [query], retourne tous les joueurs
  /// complets dans un ordre aléatoire (géré côté backend).
  /// Avec [query], le backend filtre sur prénom OU nom OU poste.
  Future<List<PlayerSearchResult>> search({
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> queryParams = {
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      'page': page,
      'limit': limit,
    };

    final response = await _dioClient.dio.get(
      ApiEndpoints.playerSearch,
      queryParameters: queryParams,
    );

    final List list = response.data['data'] ?? [];
    return list.map((json) => PlayerSearchResult.fromJson(json)).toList();
  }
}