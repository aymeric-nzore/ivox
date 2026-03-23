import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../../../features/chat/services/chat_services.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  final ChatServices _chatService = ChatServices();
  int _notificationId = 0;
  Timer? _socketRetryTimer;

  /// Initialize the notification service
  Future<void> initialize() async {
    tzdata.initializeTimeZones();

    // Android initialization
    const androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize with settings parameter
    await _notifications.initialize(
      settings: InitializationSettings(
        android: androidInitSettings,
        iOS: iosInitSettings,
      ),
      onDidReceiveNotificationResponse: (response) => {},
    );

    // Request iOS permissions
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request Android 13+ notification permission when available.
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Listen immediately; socket events will arrive once connected.
    _listenToSocketNotifications();

    // Initialize socket and keep retrying in case token/network wasn't ready.
    await _initializeChatServiceAndListen();
    _socketRetryTimer ??= Timer.periodic(const Duration(seconds: 10), (_) {
      _chatService.ensureSocketReady();
    });
  }

  /// Initialize ChatService socket and set up notification listener
  Future<void> _initializeChatServiceAndListen() async {
    try {
      await _chatService.ensureSocketReady();
    } catch (_) {
      // Will be retried by periodic timer.
    }
  }

  /// Listen to Socket.IO notifications
  void _listenToSocketNotifications() {
    if (_notificationSubscription != null) {
      return; // Already listening
    }

    _notificationSubscription =
        _chatService.appNotifications.listen((notification) {
      _handleSocketNotification(notification);
    });
  }

  /// Handle notifications from Socket.IO
  void _handleSocketNotification(Map<String, dynamic> notification) {
    final type = (notification['type'] ?? '').toString();

    switch (type) {
      case 'friend_request':
        final fromUsername =
            (notification['fromUsername'] ?? 'Quelqu\'un').toString();
        _showNotification(
          title: 'Nouvelle demande d\'ami',
          body: '$fromUsername a envoyé une demande d\'ami',
        );
        break;

      case 'friend_request_response':
        final fromUsername =
            (notification['fromUsername'] ?? 'Utilisateur').toString();
        final action = (notification['action'] ?? '').toString();
        final accepted = action == 'accept';
        _showNotification(
          title: accepted
              ? '✓ Demande acceptée'
              : '✗ Demande refusée',
          body: '$fromUsername a ${accepted ? 'accepté' : 'refusé'} votre demande d\'ami',
        );
        break;

      case 'chat_message':
        final preview =
            (notification['preview'] ?? 'Nouveau message').toString();
        _showNotification(
          title: 'Nouveau message',
          body: preview,
        );
        break;

      case 'shop_item_created':
        final title = (notification['title'] ?? 'Nouveau son').toString();
        _showNotification(
          title: 'Nouvelle musique disponible',
          body: title,
        );
        break;

      default:
        break;
    }
  }

  /// Show a local notification
  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    _notificationId++;

    const androidDetails = AndroidNotificationDetails(
      'ivox_notifications',
      'IVOX Notifications',
      channelDescription: 'Notifications pour demandes d\'ami, messages, etc',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Dispose resources
  void dispose() {
    _notificationSubscription?.cancel();
    _socketRetryTimer?.cancel();
  }
}




