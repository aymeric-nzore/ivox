import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:ivox/features/auth/services/auth_gate.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      curve: Curves.fastOutSlowIn,
      duration: 3000,
      splash: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: LottieBuilder.asset("assets/lotties/Game asset.json")),
        ],
      ),
      nextScreen: AuthGate(),
      splashIconSize: 440,
    );
  }
}
