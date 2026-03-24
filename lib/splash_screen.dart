import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:ivox/core/services/api_service.dart';
import 'package:ivox/features/auth/services/auth_gate.dart';
import 'package:ivox/features/shop/services/animation_service.dart' as anim;
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _defaultSplashAsset = 'assets/lotties/Game asset.json';
  late final anim.AnimationService _animationService;
  Future<anim.Animation?>? _activeAnimationFuture;

  @override
  void initState() {
    super.initState();
    _animationService = anim.AnimationService(apiService: ApiService());
    _activeAnimationFuture = _loadActiveAnimation();
  }

  Future<anim.Animation?> _loadActiveAnimation() async {
    try {
      await ApiService().init();
      return await _animationService.getActiveSplashAnimation();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<anim.Animation?>(
      future: _activeAnimationFuture,
      builder: (context, snapshot) {
        final active = snapshot.data;

        return AnimatedSplashScreen(
          curve: Curves.fastOutSlowIn,
          duration: 2500,
          splash: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: active != null
                    ? Lottie.network(
                        active.assetUrl,
                        errorBuilder: (_, __, ___) =>
                            LottieBuilder.asset(_defaultSplashAsset),
                      )
                    : LottieBuilder.asset(_defaultSplashAsset),
              ),
            ],
          ),
          nextScreen: AuthGate(),
          splashIconSize: 440,
        );
      },
    );
  }
}
