import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/foundation.dart';
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
  anim.Animation? _activeAnimation;
  bool _isResolved = false;

  @override
  void initState() {
    super.initState();
    _animationService = anim.AnimationService(apiService: ApiService());
    if (kIsWeb) {
      _isResolved = true;
      _activeAnimation = null;
      return;
    }
    _resolveSplashAnimation();
  }

  Future<void> _resolveSplashAnimation() async {
    try {
      await ApiService().init();
      final active = await _animationService.getActiveSplashAnimation();
      if (!mounted) return;
      setState(() {
        _activeAnimation = active;
        _isResolved = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activeAnimation = null;
        _isResolved = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isResolved) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final splashSize = screenWidth < 380 ? 280.0 : 360.0;

    return AnimatedSplashScreen(
      curve: Curves.fastOutSlowIn,
      duration: kIsWeb ? 900 : 2500,
      splash: Center(
        child: SizedBox(
          width: splashSize,
          height: splashSize,
          child: _activeAnimation != null
              ? Lottie.network(
                  _activeAnimation!.assetUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      LottieBuilder.asset(_defaultSplashAsset),
                )
              : LottieBuilder.asset(_defaultSplashAsset),
        ),
      ),
      nextScreen: AuthGate(),
      splashIconSize: splashSize,
    );
  }
}
