import 'dart:async';

import 'package:dio/dio.dart';
import 'package:ivox/core/services/api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatUser {
  final String id;
  final String username;
  final String email;
  final String status;
  final String? photoUrl;

  ChatUser({
    required this.id,
    required this.username,
    required this.email,
    required this.status,
    this.photoUrl,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      status: (json['status'] ?? 'offline').toString(),
      photoUrl: json['photoUrl']?.toString(),
    );
  }
}

class ChatMessage {
  final String messageId;
  final String sender;
  final String receiver;
  final String message;
  final String status;
  final DateTime createdAt;

  ChatMessage({
    required this.messageId,
    required this.sender,
    required this.receiver,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: (json['messageId'] ?? '').toString(),
      sender: (json['sender'] ?? '').toString(),
      receiver: (json['receiver'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      status: (json['status'] ?? 'sent').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class ChatServices {
  static final ChatServices _instance = ChatServices._internal();
  ChatServices._internal();
  factory ChatServices() => _instance;

  final ApiService _apiService = ApiService();

  final StreamController<List<ChatMessage>> _messagesController =
      StreamController<List<ChatMessage>>.broadcast();

  io.Socket? _socket;
  String? _currentUserId;
  final Map<String, List<ChatMessage>> _messages = {};

  String? get currentUserId => _currentUserId;

  Future<void> _initSocket() async {
    if (_socket?.connected == true) return;

    await _apiService.init();
    final token = await _apiService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token manquant');
    }

    final me = await _apiService.dio.get('/auth/me');
    final meData = _toMap(me.data);
    _currentUserId = (meData['id'] ?? '').toString();

    if (_currentUserId == null || _currentUserId!.isEmpty) {
      throw Exception('Utilisateur introuvable');
    }

    final baseUrl = _apiService.dio.options.baseUrl.replaceAll('/api', '');

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.onConnect((_) {
      _socket!.emit('user_join', {'userId': _currentUserId});
    });

    _socket!.on('message_new', (data) => _pushMessage(ChatMessage.fromJson(_toMap(data))));
    _socket!.on('message_sent', (data) => _pushMessage(ChatMessage.fromJson(_toMap(data))));
    _socket!.on('message_read', (data) {
      final payload = _toMap(data);
      final targetId = (payload['messageId'] ?? '').toString();
      if (targetId.isEmpty) return;

      for (final key in _messages.keys) {
        final updated = _messages[key]!.map((m) {
          if (m.messageId != targetId) return m;
          return ChatMessage(
            messageId: m.messageId,
            sender: m.sender,
            receiver: m.receiver,
            message: m.message,
            status: 'read',
            createdAt: m.createdAt,
          );
        }).toList();
        _messages[key] = updated;
      }
    });

    _socket!.connect();
  }

  Future<List<ChatUser>> getUsers() async {
    await _initSocket();
    final response = await _apiService.dio.get('/messages/users');
    final data = response.data;

    if (data is! List) return [];

    return data
        .map((e) => ChatUser.fromJson(_toMap(e)))
        .where((u) => u.id != _currentUserId)
        .toList();
  }

  Future<List<ChatMessage>> loadMessages(String withUserId) async {
    await _initSocket();
    final response = await _apiService.dio.get('/messages/$withUserId');
    final data = response.data;

    if (data is! List) {
      _messages[withUserId] = [];
      _messagesController.add([]);
      return [];
    }

    final list = data.map((e) => ChatMessage.fromJson(_toMap(e))).toList();
    _messages[withUserId] = list;
    _messagesController.add(list);

    _socket?.emit('chat_join', {'withUserId': withUserId});
    return list;
  }

  Stream<List<ChatMessage>> getMessages(String withUserId) async* {
    await loadMessages(withUserId);
    yield _messages[withUserId] ?? [];
    yield* _messagesController.stream.map((_) => _messages[withUserId] ?? []);
  }

  Future<void> sendMessage(String receiverId, String message) async {
    await _initSocket();
    final text = message.trim();
    if (text.isEmpty) return;

    try {
      final response = await _apiService.dio.post(
        '/messages',
        data: {'receiver': receiverId, 'message': text},
      );
      final created = ChatMessage.fromJson(_toMap(response.data));
      _pushMessage(created);
    } on DioException catch (error) {
      final raw = error.response?.data;
      if (raw is Map && raw['message'] != null) {
        throw Exception(raw['message'].toString());
      }
      throw Exception('Envoi impossible');
    }
  }

  Future<void> markAsRead(String messageId) async {
    await _initSocket();
    await _apiService.dio.patch('/messages/$messageId/read');
  }

  void _pushMessage(ChatMessage message) {
    final peerId = message.sender == _currentUserId ? message.receiver : message.sender;
    final list = _messages.putIfAbsent(peerId, () => []);

    final existing = list.indexWhere((m) => m.messageId == message.messageId);
    if (existing >= 0) {
      list[existing] = message;
    } else {
      list.add(message);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    _messagesController.add(List<ChatMessage>.from(list));
  }

  Map<String, dynamic> _toMap(dynamic input) {
    if (input is Map<String, dynamic>) return input;
    if (input is Map) {
      return input.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }
}
