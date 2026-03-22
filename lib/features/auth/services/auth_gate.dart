import 'package:flutter/material.dart';
import 'package:ivox/features/auth/services/api_auth_service.dart';
import 'package:ivox/features/onBoarding/on_boarding_page.dart';
import 'package:ivox/main_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _isUserConnected() async {
    return ApiAuthService().isAuthentificated();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isUserConnected(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final isLoggedIn = snapshot.data ?? false;
        if (isLoggedIn) {
          return const MainPage();
        }

        return const OnBoardingPage();
      },
    );
  }
}