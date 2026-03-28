import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ivox/core/services/audio_background_state.dart';
import 'package:ivox/core/services/fcm_token_service.dart';
import 'package:ivox/core/services/notification_service.dart';
import 'package:ivox/core/theme/theme_provider.dart';
import 'package:ivox/firebase_options.dart';
import 'package:ivox/splash_screen.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  runApp(const MyApp());

  unawaited(_initializeAppServices());
}

Future<void> _initializeAppServices() async {
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ivox.app.audio',
      androidNotificationChannelName: 'Lecture audio Ivox',
      androidNotificationOngoing: true,
    );
    AudioBackgroundState.isInitialized = true;
  } catch (_) {}

  // Keep web startup robust when mobile-only plugins are unavailable.
  if (!kIsWeb) {
    try {
      await FcmTokenService().initialize();
    } catch (_) {}
  }

  if (!kIsWeb) {
    try {
      await NotificationService().initialize();
    } catch (_) {}
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _buildWebResponsiveShell(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        if (!isWide) {
          return child;
        }

        return Container(
          color: const Color(0xFF0B1020),
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Ivox',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: SplashScreen(),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              final appChild = child ?? const SizedBox.shrink();
              if (!kIsWeb) {
                return appChild;
              }
              return _buildWebResponsiveShell(appChild);
            },
          );
        },
      ),
    );
  }
}
