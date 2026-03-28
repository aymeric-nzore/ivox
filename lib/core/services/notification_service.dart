import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../../../features/chat/services/chat_services.dart';
import 'dart:async';
import 'package:ivox/firebase_options.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String channelId = 'ivox_notifications';
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        channelId,
        'IVOX Notifications',
        description: 'Notifications pour demandes d\'ami, messages, etc',
        importance: Importance.max,
      );

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  StreamSubscription<RemoteMessage>? _fcmForegroundSubscription;
  final ChatServices _chatService = ChatServices();
  int _notificationId = 0;
  Timer? _socketRetryTimer;
  final Map<String, DateTime> _recentNotificationKeys = {};

  Future<void> _ensureFirebaseReady() async {
    if (Firebase.apps.isNotEmpty) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') {
        rethrow;
      }
    }
  }

  /// Initialize the notification service
  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    await _ensureFirebaseReady();

    // Android initialization
    const androidInitSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

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
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Request Android 13+ notification permission when available.
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Ensure the same channel exists for FCM background/system notifications.
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    // Keep iOS heads-up presentation enabled when app is foreground.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Listen immediately; socket events will arrive once connected.
    _listenToSocketNotifications();
    _listenToForegroundFcmNotifications();

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

    _notificationSubscription = _chatService.appNotifications.listen((
      notification,
    ) {
      _handleSocketNotification(notification);
    });
  }

  /// Handle notifications from Socket.IO
  void _handleSocketNotification(Map<String, dynamic> notification) {
    final type = (notification['type'] ?? '').toString();

    switch (type) {
      case 'friend_request':
        final fromUsername = (notification['fromUsername'] ?? 'Quelqu\'un')
            .toString();
        _showNotificationDedup(
          dedupKey:
              'friend_request:${notification['fromUserId'] ?? fromUsername}',
          title: 'Nouvelle demande d\'ami',
          body: '$fromUsername a envoyé une demande d\'ami',
        );
        break;

      case 'friend_request_response':
        final fromUsername = (notification['fromUsername'] ?? 'Utilisateur')
            .toString();
        final action = (notification['action'] ?? '').toString();
        final accepted = action == 'accept';
        _showNotificationDedup(
          dedupKey:
              'friend_response:${notification['fromUserId'] ?? fromUsername}:$action',
          title: accepted ? '✓ Demande acceptée' : '✗ Demande refusée',
          body:
              '$fromUsername a ${accepted ? 'accepté' : 'refusé'} votre demande d\'ami',
        );
        break;

      case 'chat_message':
        final preview = (notification['preview'] ?? 'Nouveau message')
            .toString();
        final fromUsername = (notification['fromUsername'] ?? '').toString();
        final title = fromUsername.isNotEmpty
            ? 'Nouveau message de $fromUsername'
            : 'Nouveau message';
        _showNotificationDedup(
          dedupKey: 'chat_message:${notification['messageId'] ?? preview}',
          title: title,
          body: preview,
        );
        break;

      case 'shop_item_created':
        final title = (notification['title'] ?? 'Nouveau son').toString();
        final itemType = (notification['itemType'] ?? '').toString();
        final notifTitle = switch (itemType) {
          'animation' => 'Nouvelle animation disponible',
          'avatar' => 'Nouvel avatar disponible',
          _ => 'Nouvelle musique disponible',
        };
        _showNotificationDedup(
          dedupKey: 'shop_item_created:$title',
          title: notifTitle,
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
      channelId,
      'IVOX Notifications',
      channelDescription: 'Notifications pour demandes d\'ami, messages, etc',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: 'ic_launcher',
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

  void _listenToForegroundFcmNotifications() {
    try {
      _fcmForegroundSubscription ??= FirebaseMessaging.onMessage.listen((
        message,
      ) {
        final data = message.data;
        final type = (data['type'] ?? '').toString();
        final messageId = (data['messageId'] ?? '').toString();
        final fromUsername = (data['fromUsername'] ?? '').toString();

        final title =
            message.notification?.title ??
            (type == 'chat_message'
                ? (fromUsername.isNotEmpty
                      ? 'Nouveau message de $fromUsername'
                      : 'Nouveau message')
                : 'Nouvelle notification');
        final body =
            message.notification?.body ??
            (data['preview'] ??
                    data['message'] ??
                    'Vous avez une nouvelle notification')
                .toString();

        _showNotificationDedup(
          dedupKey: 'fcm:$type:${messageId.isNotEmpty ? messageId : body}',
          title: title,
          body: body,
        );
      });
    } catch (_) {
      // Keep socket/local notifications active even if FCM listener fails to start.
    }
  }

  void _showNotificationDedup({
    required String dedupKey,
    required String title,
    required String body,
  }) {
    final now = DateTime.now();
    _recentNotificationKeys.removeWhere(
      (_, createdAt) => now.difference(createdAt).inSeconds > 5,
    );

    if (_recentNotificationKeys.containsKey(dedupKey)) {
      return;
    }

    _recentNotificationKeys[dedupKey] = now;
    _showNotification(title: title, body: body);
  }

  /// Dispose resources
  void dispose() {
    _notificationSubscription?.cancel();
    _fcmForegroundSubscription?.cancel();
    _socketRetryTimer?.cancel();
  }
}
