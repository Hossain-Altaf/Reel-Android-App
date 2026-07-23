import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import '../models/message.dart';
import '../models/conversation.dart';
import 'auth_service.dart';

class ChatService {
  static const String baseUrl = 'http://localhost:5000/api';
  static const String socketUrl = 'http://localhost:5000';
  // Remember: swap localhost <-> 10.0.2.2 depending on emulator vs physical phone,
  // same as the other services.

  final AuthService _authService = AuthService();
  socket_io.Socket? _socket;

  Future<String> getOrCreateConversation(String otherUserId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/conversations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'otherUserId': otherUserId}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to start conversation');
    }

    return data['_id'];
  }

  Future<List<Conversation>> fetchConversations() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/conversations'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load conversations');
    }

    final List data = jsonDecode(response.body);
    return data.map((json) => Conversation.fromJson(json)).toList();
  }

  Future<List<Message>> fetchMessages(String conversationId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/conversations/$conversationId/messages'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load messages');
    }

    final List data = jsonDecode(response.body);
    return data.map((json) => Message.fromJson(json)).toList();
  }

  /// Connects the socket once. Safe to call multiple times — does nothing if already connected.
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    _socket = socket_io.io(
      socketUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .build(),
    );

    _socket!.connect();
  }

  void onNewMessage(void Function(Message message, String conversationId) callback) {
    _socket?.on('new_message', (data) {
      final message = Message.fromJson(data['message']);
      callback(message, data['conversationId']);
    });
  }

  Future<Message> sendMessage(String conversationId, String text) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Not connected to chat server');
    }

    final completer = Completer<Message>();
    _socket!.emitWithAck('send_message', {'conversationId': conversationId, 'text': text},
        ack: (response) {
          if (response['error'] != null) {
            completer.completeError(Exception(response['error']));
          } else {
            completer.complete(Message.fromJson(response['message']));
          }
        });

    return completer.future;
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}