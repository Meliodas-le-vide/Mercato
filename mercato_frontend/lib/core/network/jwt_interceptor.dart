import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_frontend/core/constants/api_endpoints.dart';

class JwtInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  JwtInterceptor(this._storage, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _storage.read(key: 'access_token');

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Éviter d'intercepter à nouveau les requêtes liées à l'authentification
    final isAuthRoute =
        err.requestOptions.path.contains(ApiEndpoints.refreshToken) ||
        err.requestOptions.path.contains('/auth/login');

    if (err.response?.statusCode == 401 && !isAuthRoute) {
      // DEBUG
      print(
        ' 401 détecté sur ${err.requestOptions.path} -> tentative de refresh...',
      );

      final refreshToken = await _storage.read(key: 'refresh_token');

      // DEBUG
      print(
        ' refresh_token présent en storage : ${refreshToken != null && refreshToken.isNotEmpty}',
      );

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Utilisation d'une nouvelle instance Dio pour éviter les boucles d'interception
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: ApiEndpoints.baseUrl,
              headers: {'Content-Type': 'application/json'},
            ),
          );

          // DEBUG
          print(
            ' POST ${ApiEndpoints.refreshToken} avec refreshToken=${refreshToken.substring(0, 10)}...',
          );

          final response = await refreshDio.post(
            ApiEndpoints.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          // DEBUG
          print(
            'Réponse refresh : status=${response.statusCode} body=${response.data}',
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final newAccessToken =
                response.data['accessToken'] ?? response.data['token'];
            final newRefreshToken = response.data['refreshToken'];

            // DEBUG
            print(
              ' newAccessToken extrait : ${newAccessToken != null ? "OK" : "NULL !!"}',
            );

            // Mise à jour du token d'accès
            await _storage.write(key: 'access_token', value: newAccessToken);

            // Mettre à jour le refresh token uniquement si le serveur en renvoie un nouveau
            if (newRefreshToken != null) {
              await _storage.write(
                key: 'refresh_token',
                value: newRefreshToken,
              );
            }

            // Cloner et rejouer la requête initiale avec les bons headers
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';

            final cloneReq = await _dio.fetch(opts);
            return handler.resolve(cloneReq);
          }
        } catch (e) {
          // DEBUG : affiche la vraie cause de l'échec du refresh
          if (e is DioException) {
            print(
              ' Échec refresh : status=${e.response?.statusCode} body=${e.response?.data} message=${e.message}',
            );

            // On ne détruit la session QUE si le serveur a explicitement rejeté
            // le refresh token (401/403). Une erreur réseau (pas de connexion,
            // timeout, DNS...) n'a pas de e.response -> il ne faut PAS déconnecter
            // l'utilisateur juste parce que le wifi a eu un hoquet.
            final status = e.response?.statusCode;
            final isTokenRejected = status == 401 || status == 403;

            if (isTokenRejected) {
              print(
                ' Refresh token rejeté par le serveur -> nettoyage de la session.',
              );
              await _storage.deleteAll();
            } else {
              print(
                ' Erreur réseau pendant le refresh -> session conservée, on ne déconnecte pas.',
              );
              // On ne touche pas au storage : les tokens restent valides,
              // on retentera au prochain appel.
            }
          } else {
            print(' Échec refresh (non-Dio) : $e');
            // Erreur inattendue non réseau : par prudence on ne déconnecte pas non plus,
            // on laisse la requête d'origine échouer et remonter normalement.
          }
        }
      } else {
        // DEBUG
        print(
          ' Aucun refresh_token trouvé en storage -> impossible de rafraîchir.',
        );
      }
    }

    return handler.next(err);
  }
}
