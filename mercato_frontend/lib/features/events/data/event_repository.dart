import 'package:dio/dio.dart'; // Assure-toi d'importer dio pour FormData et MultipartFile
import 'package:mercato_frontend/core/constants/api_endpoints.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/network/paginated_result.dart';
import 'package:mercato_frontend/features/events/domain/event_model.dart';

class EventRepository {
  final DioClient _dioClient;

  EventRepository(this._dioClient);

  /// Liste paginée des événements à venir (les plus proches en premier).
  Future<PaginatedResult<EventModel>> getEvents({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.events,
      queryParameters: {'page': page, 'limit': limit},
    );
    return PaginatedResult.fromJson(response.data, EventModel.fromJson);
  }

  Future<EventModel> getEventById(int id) async {
    final response = await _dioClient.dio.get(ApiEndpoints.eventDetail(id));
    return EventModel.fromJson(response.data['data']);
  }

  /// Événements publiés par le recruteur connecté.
  Future<List<EventModel>> getMyEvents() async {
    final response = await _dioClient.dio.get(ApiEndpoints.myEvents);
    final List data = response.data['data'] ?? [];
    return data.map((json) => EventModel.fromJson(json)).toList();
  }

  Future<EventModel> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    required String location,
    required String organizerName,
    required String imagePath,
  }) async {
    // Utilisation de FormData pour envoyer du texte et un fichier binaire simultanément
    final formData = FormData.fromMap({
      'title': title,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'eventDate': eventDate.toIso8601String(),
      'location': location,
      'organizerName': organizerName,
      // Ajout de l'image sous la clé 'image' (correspondant au middleware .single('image') côté Node.js)
      'image': await MultipartFile.fromFile(imagePath),
    });

    final response = await _dioClient.dio.post(
      ApiEndpoints.events,
      data: formData,
    );
    return EventModel.fromJson(response.data['data']);
  }
}
