import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ivox/core/services/audio_background_state.dart';
import 'package:ivox/core/services/fcm_token_service.dart';
import 'package:ivox/core/services/notification_service.dart';
import 'package:ivox/core/theme/theme_provider.dart';
import 'package:ivox/splash_screen.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      await NotificationService().initialize();
    } catch (_) {}
  }

  if (!kIsWeb) {
    try {
      await FcmTokenService().initialize();
    } catch (_) {}
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          );
        },
      ),
    );
  }
}
