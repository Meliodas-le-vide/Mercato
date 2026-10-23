import 'package:mercato_frontend/core/constants/api_endpoints.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/network/paginated_result.dart';
import 'package:mercato_frontend/features/user/domain/player_search_result.dart';

class FavoriteRepository {
  final DioClient _dioClient;

  FavoriteRepository(this._dioClient);

  /// Ajoute ou retire un joueur des favoris. Retourne le nouvel état.
  Future<bool> toggleFavorite(int playerId) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.favoriteToggle(playerId),
    );
    return response.data['favorited'] as bool;
  }

  /// Liste paginée des joueurs mis en favori par l'utilisateur connecté.
  Future<PaginatedResult<PlayerSearchResult>> getMyFavorites({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.favorites,
      queryParameters: {'page': page, 'limit': limit},
    );
    return PaginatedResult.fromJson(response.data, PlayerSearchResult.fromJson);
  }
}
