import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mercato_app/core/constants/api_constants.dart';

class ApiClient {
  final _storage = const FlutterSecureStorage();
  late Dio dio;

  ApiClient() {
    dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final newToken = await _storage.read(key: 'accessToken');
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final cloneReq = await dio.fetch(error.requestOptions);
            return handler.resolve(cloneReq);
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken == null) return false;

      final response = await dio.post(ApiConstants.refreshToken, data: {
        'refreshToken': refreshToken,
      });

      await _storage.write(key: 'accessToken', value: response.data['accessToken']);
      await _storage.write(key: 'refreshToken', value: response.data['refreshToken']);
      return true;
    } catch (_) {
      await _storage.deleteAll(); 
      return false;
    }
  }
}