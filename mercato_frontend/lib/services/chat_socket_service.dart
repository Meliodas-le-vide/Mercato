import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:mercato_frontend/core/constants/api_endpoints.dart';
import 'package:mercato_frontend/features/chat/domain/message_model.dart';

/// Singleton qui gère UNE connexion socket partagée dans toute l'app,
/// pour éviter d'ouvrir une nouvelle connexion à chaque écran.
class ChatSocketService {
  ChatSocketService._internal();
  static final ChatSocketService instance = ChatSocketService._internal();

  final _secureStorage = const FlutterSecureStorage();
  socket_io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  /// À appeler une fois après le login (ou au démarrage de l'app si déjà connecté).
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _secureStorage.read(key: 'access_token');
    if (token == null) {
      throw Exception(
        'Impossible de se connecter au chat : aucun token trouvé.',
      );
    }

    //  ApiEndpoints.baseUrl doit être ton URL backend SANS '/api'
    // (ex: 'http://192.168.1.84:5000'), Socket.io se connecte à la racine.
    _socket = socket_io.io(
      ApiEndpoints.baseUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) => print(' Socket connecté'));
    _socket!.onDisconnect((_) => print(' Socket déconnecté'));
    _socket!.onConnectError((err) => print(' Erreur connexion socket: $err'));
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Écoute les nouveaux messages (envoyés OU reçus, le serveur diffuse aux deux côtés).
  void onNewMessage(void Function(MessageModel message) callback) {
    _socket?.on('newMessage', (data) {
      callback(MessageModel.fromJson(Map<String, dynamic>.from(data)));
    });
  }

  void onUserTyping(void Function(int userId) callback) {
    _socket?.on('userTyping', (data) {
      callback(data['userId']);
    });
  }

  void onUserStoppedTyping(void Function(int userId) callback) {
    _socket?.on('userStoppedTyping', (data) {
      callback(data['userId']);
    });
  }

  void onMessagesRead(void Function(int readByUserId) callback) {
    _socket?.on('messagesRead', (data) {
      callback(data['readBy']);
    });
  }

  /// Envoie un message et attend l'accusé de réception du serveur.
  Future<MessageModel> sendMessage({
    required int receiverId,
    required String content,
    String messageType = 'text',
    int? relatedVideoId,
  }) {
    final completer = Completer<MessageModel>();

    if (_socket == null || !_socket!.connected) {
      completer.completeError(Exception('Socket non connecté.'));
      return completer.future;
    }

    _socket!.emitWithAck(
      'sendMessage',
      {
        'receiverId': receiverId,
        'content': content,
        'messageType': messageType,
        if (relatedVideoId != null) 'relatedVideoId': relatedVideoId,
      },
      ack: (response) {
        if (response['error'] != null) {
          completer.completeError(Exception(response['error']));
        } else {
          completer.complete(
            MessageModel.fromJson(Map<String, dynamic>.from(response['data'])),
          );
        }
      },
    );

    return completer.future;
  }

  void notifyTyping(int receiverId) {
    _socket?.emit('typing', {'receiverId': receiverId});
  }

  void notifyStopTyping(int receiverId) {
    _socket?.emit('stopTyping', {'receiverId': receiverId});
  }

  void markAsRead(int otherUserId) {
    _socket?.emit('markAsRead', {'otherUserId': otherUserId});
  }

  /// Retire tous les listeners (à appeler dans dispose() de l'écran de chat
  /// pour éviter les doublons de callbacks si l'utilisateur rouvre l'écran).
  void clearListeners() {
    _socket?.off('newMessage');
    _socket?.off('userTyping');
    _socket?.off('userStoppedTyping');
    _socket?.off('messagesRead');
  }
}
