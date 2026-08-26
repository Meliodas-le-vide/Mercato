import 'package:mercato_frontend/core/constants/api_endpoints.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';

class PlayerSearchRepository {
  final DioClient _dioClient;

  PlayerSearchRepository(this._dioClient);

  /// Recherche de joueurs avec filtres optionnels
  Future<List<PlayerSearchResult>> search({
    String? position,
    String? level,
    String? city,
    int? minAge,
    int? maxAge,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.playerSearch,
      queryParameters: {
        if (position != null && position.isNotEmpty) 'position': position,
        if (level != null && level.isNotEmpty) 'level': level,
        if (city != null && city.isNotEmpty) 'city': city,
        if (minAge != null) 'minAge': minAge,
        if (maxAge != null) 'maxAge': maxAge,
        'page': page,
        'limit': limit,
      },
    );

    final List data = response.data['data'];
    return data.map((json) => PlayerSearchResult.fromJson(json)).toList();
  }
}