import 'package:flutter/material.dart';
import 'package:ivox/features/auth/services/api_auth_service.dart';
import 'package:ivox/features/onBoarding/on_boarding_page.dart';
import 'package:ivox/main_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _authFuture;

  Future<bool> _isUserConnected() async {
    return ApiAuthService().isAuthentificated();
  }

  @override
  void initState() {
    super.initState();
    _authFuture = _isUserConnected();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authFuture,
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else {
          final isLoggedIn = snapshot.data ?? false;
          child = isLoggedIn ? const MainPage() : const OnBoardingPage();
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (widget, animation) {
            return FadeTransition(opacity: animation, child: widget);
          },
          child: KeyedSubtree(
            key: ValueKey<String>(
              snapshot.connectionState == ConnectionState.waiting
                  ? 'auth-loading'
                  : ((snapshot.data ?? false) ? 'auth-main' : 'auth-onboarding'),
            ),
            child: child,
          ),
        );
      },
    );
  }
}