import 'package:mercato_frontend/core/constants/api_endpoints.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/features/chat/domain/conversation_model.dart';
import 'package:mercato_frontend/features/chat/domain/message_model.dart';

class ChatRepository {
  final DioClient _dioClient;

  ChatRepository(this._dioClient);

  Future<List<ConversationModel>> getConversations() async {
    // utilisation directe de la constante ApiEndpoints.conversations
    final response = await _dioClient.dio.get(ApiEndpoints.conversations);
    final List list = response.data['data'] ?? [];
    return list.map((json) => ConversationModel.fromJson(json)).toList();
  }

  Future<List<MessageModel>> getConversationHistory(
    int otherUserId, {
    int page = 1,
    int limit = 30,
  }) async {
    // utilisation de la fonction conversationMessages(otherUserId)
    final response = await _dioClient.dio.get(
      ApiEndpoints.conversationMessages(otherUserId),
      queryParameters: {'page': page, 'limit': limit},
    );
    final List list = response.data['data'] ?? [];
    return list.map((json) => MessageModel.fromJson(json)).toList();
  }

  /// envoi via REST (fallback si le socket est déconnecté).
  Future<MessageModel> sendMessageRest({
    required int receiverId,
    required String content,
    String messageType = 'text',
    int? relatedVideoId,
  }) async {
    // utilisation de la constante ApiEndpoints.messages
    final response = await _dioClient.dio.post(
      ApiEndpoints.messages,
      data: {
        'receiverId': receiverId,
        'content': content,
        'messageType': messageType,
        'relatedVideoId': ?relatedVideoId,
      },
    );
    return MessageModel.fromJson(response.data['data']);
  }

  Future<void> markConversationAsRead(int otherUserId) async {
    // utilisation de la fonction markConversationRead(otherUserId)
    await _dioClient.dio.patch(ApiEndpoints.markConversationRead(otherUserId));
  }
}
