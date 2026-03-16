import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService with WidgetsBindingObserver {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final notificationPlugin = FlutterLocalNotificationsPlugin();
  final firebaseMessaging = FirebaseMessaging.instance;
  StreamSubscription<QuerySnapshot>? _messageSubscription;
  StreamSubscription<User?>? _authSubscription;
  bool _hasLoadedInitialMessages = false;
  bool _isAppInForeground = true;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  //INITIALIZE
  Future<void> initNotification() async {
    if (_isInitialized) return;
    tz_data.initializeTimeZones();

    // Demander la permission POST_NOTIFICATIONS pour Android 13+
    await Permission.notification.request();

    // Demander la permission pour Firebase Messaging iOS
    await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    //Preparez les settings android
    const initAndroidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    //Preparez les settings iOS
    const initIosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    //Preparez les settings
    const initSettings = InitializationSettings(
      android: initAndroidSettings,
      iOS: initIosSettings,
    );
    await notificationPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    WidgetsBinding.instance.addObserver(this);

    // Configurer les handlers Firebase Cloud Messaging
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);

    // Récupérer le FCM token
    final token = await firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Sauvegarder le token si l'utilisateur est connecté
    if (FirebaseAuth.instance.currentUser != null) {
      await _saveTokenToFirestore(token);
      await startMessageListener();
    }

    _isInitialized = true;

    _authSubscription ??=
        FirebaseAuth.instance.authStateChanges().listen(_handleAuthStateChange);
    await _handleAuthStateChange(FirebaseAuth.instance.currentUser);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
  }

  // Sauvegarder le token FCM dans Firestore après la connexion
  Future<void> saveUserFcmToken() async {
    if (!_isInitialized) {
      await initNotification();
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await firebaseMessaging.getToken();
    await _saveTokenToFirestore(token);
    await startMessageListener();
  }

  Future<void> clearUserFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await firebaseMessaging.deleteToken();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': FieldValue.delete()});
    } catch (e) {
      print('Erreur suppression token: $e');
    } finally {
      await stopMessageListener();
    }
  }

  Future<void> _handleAuthStateChange(User? user) async {
    if (!_isInitialized) return;
    if (user == null) {
      await stopMessageListener();
      return;
    }

    final token = await firebaseMessaging.getToken();
    await _saveTokenToFirestore(token);
    await startMessageListener();
  }

  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'fcmToken': token});
    } catch (e) {
      print('Erreur sauvegarde token: $e');
    }
  }

  // Gérer les messages reçus au premier plan
  void _handleForegroundMessage(RemoteMessage message) {
    print('Message reçu en premier plan: ${message.notification?.title}');
  }

  Future<void> startMessageListener() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _messageSubscription != null) return;

    _hasLoadedInitialMessages = false;
    _messageSubscription = FirebaseFirestore.instance
        .collectionGroup('message')
        .where('receiverID', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!_hasLoadedInitialMessages) {
        _hasLoadedInitialMessages = true;
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;

        final senderId = data['senderID'] as String?;
        if (senderId == user.uid) continue;
        if (_isAppInForeground) continue;

        final senderName =
            (data['senderUsername'] as String?) ??
            (data['senderEmail'] as String?) ??
            'Nouveau message';
        final message = data['message'] as String? ?? 'Nouveau message';
        showMessageNotification(
          senderName: senderName,
          messagePreview: message,
        );
      }
    }, onError: (error) {
      print('Erreur listener messages: $error');
    });
  }

  Future<void> stopMessageListener() async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    _hasLoadedInitialMessages = false;
  }

  // Gérer l'ouverture d'une notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Notification ouverte: ${message.notification?.title}');
  }

  // Gérer le clic sur une notification locale
  void _handleNotificationResponse(NotificationResponse response) {
    print('Notification cliquée: ${response.payload}');
  }

  // Handler pour les messages en arrière-plan (doit être appelé avant initNotification)
  @pragma('vm:entry-point')
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    print('Message reçu en arrière-plan: ${message.notification?.title}');
    // Initialiser les notifications si nécessaire pour montrer une notification
    // en arrière-plan
  }

  //Détails notifications
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        "daily_channel_id",
        "daily_notifications",
        importance: Importance.max,
        priority: Priority.high,
        channelDescription: "daily notification channel",
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  //Show notifs
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    await notificationPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails(),
    );
  }

  //Notif des messages
  Future<void> showMessageNotification({
    required String senderName,
    required String messagePreview,
  }) {
    return showNotification(
      id: DateTime.now().millisecond,
      title: "Nouveau message de $senderName",
      body: messagePreview,
    );
  }
}
