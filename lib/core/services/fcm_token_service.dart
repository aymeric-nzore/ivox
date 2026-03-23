import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ivox/core/services/api_service.dart';
import 'package:ivox/firebase_options.dart';

class FcmTokenService {
  static final FcmTokenService _instance = FcmTokenService._internal();
  factory FcmTokenService() => _instance;
  FcmTokenService._internal();

  final ApiService _apiService = ApiService();
  StreamSubscription<String>? _tokenRefreshSub;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerToken(token);
    }

    _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) {
      _registerToken(newToken);
    });

    _initialized = true;
  }

  Future<void> syncCurrentToken() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerToken(token);
    }
  }

  Future<void> _registerToken(String token) async {
    await _apiService.init();
    final authToken = await _apiService.getToken();
    if (authToken == null || authToken.isEmpty) {
      return;
    }

    try {
      await _apiService.dio.post(
        '/auth/fcm-token',
        data: {'fcmToken': token},
      );
    } catch (_) {
      // Ignore transient errors; next app start / token refresh will retry.
    }
  }

  Future<void> removeCurrentToken() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;

    try {
      await _apiService.dio.delete(
        '/auth/fcm-token',
        data: {'fcmToken': token},
      );
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
  }
}
