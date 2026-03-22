import 'package:flutter/material.dart';
import 'package:ivox/core/theme/theme_provider.dart';
import 'package:ivox/splash_screen.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep startup safe while ensuring background media controls are available.
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ivox.app.audio',
      androidNotificationChannelName: 'Lecture audio Ivox',
      androidNotificationOngoing: true,
    ).timeout(const Duration(seconds: 3));
  } catch (_) {}

  runApp(const MyApp());
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
