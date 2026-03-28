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
  final DateTime? lastSeen;

  ChatUser({
    required this.id,
    required this.username,
    required this.email,
    required this.status,
    this.photoUrl,
    this.lastSeen,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      status: (json['status'] ?? 'offline').toString(),
      photoUrl: json['photoUrl']?.toString(),
      lastSeen: DateTime.tryParse((json['lastSeen'] ?? '').toString()),
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
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
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
  final StreamController<Map<String, String>> _presenceController =
      StreamController<Map<String, String>>.broadcast();
  final StreamController<Map<String, dynamic>> _appNotificationsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, bool>> _typingController =
      StreamController<Map<String, bool>>.broadcast();

  io.Socket? _socket;
  String? _currentUserId;
  String? _activeToken;
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, String> _userStatus = {};
  final Map<String, DateTime?> _userLastSeen = {};
  final Map<String, bool> _typingByUser = {};

  String? get currentUserId => _currentUserId;
  Stream<Map<String, dynamic>> get appNotifications =>
      _appNotificationsController.stream;

  Future<void> ensureSocketReady() async {
    try {
      await _initSocket();
    } catch (_) {
      // Ignore transient auth/network errors; caller may retry later.
    }
  }

  Future<void> _initSocket() async {
    await _apiService.init();
    final token = await _apiService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token manquant');
    }

    // Reconnect socket when user session/token changed (logout/login new account).
    if (_activeToken != null && _activeToken != token) {
      reset();
    }

    if (_socket?.connected == true) return;

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

    _socket!.on(
      'message_new',
      (data) => _pushMessage(ChatMessage.fromJson(_toMap(data))),
    );
    _socket!.on(
      'message_sent',
      (data) => _pushMessage(ChatMessage.fromJson(_toMap(data))),
    );
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

      _messagesController.add(
        List<ChatMessage>.from(_messages.values.expand((e) => e)),
      );
    });

    _socket!.on('user_presence', (data) {
      final payload = _toMap(data);
      final userId = (payload['userId'] ?? '').toString();
      final status = (payload['status'] ?? 'offline').toString();
      final lastSeen = DateTime.tryParse(
        (payload['lastSeen'] ?? '').toString(),
      );
      if (userId.isEmpty) return;
      _userStatus[userId] = status;
      if (lastSeen != null) {
        _userLastSeen[userId] = lastSeen;
      }
      _presenceController.add(Map<String, String>.from(_userStatus));
    });

    _socket!.on('app_notification', (data) {
      _appNotificationsController.add(_toMap(data));
    });

    _socket!.on('typing_start', (data) {
      final payload = _toMap(data);
      final fromUserId = (payload['fromUserId'] ?? '').toString();
      if (fromUserId.isEmpty) return;
      _typingByUser[fromUserId] = true;
      _typingController.add(Map<String, bool>.from(_typingByUser));
    });

    _socket!.on('typing_stop', (data) {
      final payload = _toMap(data);
      final fromUserId = (payload['fromUserId'] ?? '').toString();
      if (fromUserId.isEmpty) return;
      _typingByUser[fromUserId] = false;
      _typingController.add(Map<String, bool>.from(_typingByUser));
    });

    _socket!.on('item_created', (data) {
      final payload = _toMap(data);
      final item = _toMap(payload['item']);
      final itemType = (item['itemType'] ?? '').toString();
      _appNotificationsController.add({
        'type': 'shop_item_created',
        'itemType': itemType,
        'title': (item['title'] ?? 'Nouveau contenu').toString(),
        'categorie': (item['categorie'] ?? '').toString(),
      });
    });

    _socket!.connect();
    _activeToken = token;
  }

  Future<List<ChatUser>> getUsers() async {
    await _initSocket();
    final response = await _apiService.dio.get('/messages/users');
    final data = response.data;

    if (data is! List) return [];

    final users = data
        .map((e) => ChatUser.fromJson(_toMap(e)))
        .where((u) => u.id != _currentUserId)
        .toList();

    for (final user in users) {
      _userStatus[user.id] = user.status;
      _userLastSeen[user.id] = user.lastSeen;
    }

    return users;
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

  Future<void> sendTypingStart(String toUserId) async {
    await _initSocket();
    _socket?.emit('typing_start', {'toUserId': toUserId});
  }

  Future<void> sendTypingStop(String toUserId) async {
    await _initSocket();
    _socket?.emit('typing_stop', {'toUserId': toUserId});
  }

  Future<void> markAsRead(String messageId) async {
    await _initSocket();
    await _apiService.dio.patch('/messages/$messageId/read');
  }

  Future<void> reportMessage(String messageId, {String? reason}) async {
    await _initSocket();
    await _apiService.dio.post(
      '/messages/$messageId/report',
      data: {'reason': reason ?? 'inappropriate'},
    );
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    await _initSocket();
    await _apiService.dio.post('/users/friends/request/$targetUserId');
  }

  Future<Map<String, dynamic>> getFriendRequests() async {
    await _initSocket();
    final response = await _apiService.dio.get('/users/friends/requests');
    return _toMap(response.data);
  }

  Future<void> respondFriendRequest(
    String requesterId, {
    required bool accept,
  }) async {
    await _initSocket();
    await _apiService.dio.post(
      '/users/friends/request/$requesterId/respond',
      data: {'action': accept ? 'accept' : 'reject'},
    );
  }

  Future<void> blockUser(String targetUserId) async {
    await _initSocket();
    await _apiService.dio.post('/users/block/$targetUserId');
  }

  Future<List<ChatUser>> getBlockedUsers() async {
    await _initSocket();
    final response = await _apiService.dio.get('/users/blocked');
    final data = response.data;
    if (data is! List) return [];
    return data.map((e) => ChatUser.fromJson(_toMap(e))).toList();
  }

  Future<void> unblockUser(String targetUserId) async {
    await _initSocket();
    await _apiService.dio.post('/users/unblock/$targetUserId');
  }

  void reset() {
    _socket?.dispose();
    _socket = null;
    _currentUserId = null;
    _activeToken = null;
    _messages.clear();
    _userStatus.clear();
    _userLastSeen.clear();
    _typingByUser.clear();
  }

  String getUserStatus(String userId) {
    return _userStatus[userId] ?? 'offline';
  }

  DateTime? getUserLastSeen(String userId) {
    return _userLastSeen[userId];
  }

  Stream<String> userStatusStream(String userId) async* {
    await _initSocket();
    yield getUserStatus(userId);
    yield* _presenceController.stream.map(
      (state) => state[userId] ?? 'offline',
    );
  }

  Stream<DateTime?> userLastSeenStream(String userId) async* {
    await _initSocket();
    yield getUserLastSeen(userId);
    yield* _presenceController.stream.map((_) => getUserLastSeen(userId));
  }

  Stream<bool> userTypingStream(String userId) async* {
    await _initSocket();
    yield _typingByUser[userId] ?? false;
    yield* _typingController.stream.map((state) => state[userId] ?? false);
  }

  void _pushMessage(ChatMessage message) {
    final peerId = message.sender == _currentUserId
        ? message.receiver
        : message.sender;
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
