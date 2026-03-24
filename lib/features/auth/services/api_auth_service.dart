import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ivox/core/services/fcm_token_service.dart';
import 'package:ivox/features/chat/services/chat_services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ivox/core/services/api_service.dart';

class ApiAuthService {
  static final ApiAuthService _instance = ApiAuthService._internal();
  ApiAuthService._internal();
  factory ApiAuthService() => _instance;

  final ApiService _apiService = ApiService();
  static const String _googleServerClientId =
      '647081602209-1buqnm1m66bg3ebjrbia9tcvfvf73l0p.apps.googleusercontent.com';
    static const String _googleWebClientId =
      '647081602209-fj5lobp0nr2mg6vslf9bd0c220f42r4b.apps.googleusercontent.com';

  String _extractToken(dynamic data) {
    if (data is Map<String, dynamic>) {
      final token = data['token'];
      if (token is String && token.isNotEmpty) {
        return token;
      }
    }
    throw Exception("Token manquant dans la reponse serveur");
  }

  Exception _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      final detail = responseData['detail'];
      if (message is String && message.isNotEmpty) {
        if (detail is String && detail.isNotEmpty) {
          return Exception('$message ($detail)');
        }
        return Exception(message);
      }
    }

    if (statusCode != null) {
      return Exception("Erreur reseau ($statusCode)");
    }

    return Exception("Impossible de contacter le serveur");
  }

  //Register
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.dio.post(
        "/auth/register",
        data: {"username": username, "email": email, "password": password},
      );
      final token = _extractToken(response.data);
      //Sauvegarder le token
      await _apiService.saveToken(token);
      if (!kIsWeb) {
        unawaited(FcmTokenService().syncCurrentToken());
      }
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  //Login
  Future<void> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await _apiService.dio.post(
        "/auth/login",
        data: {"usernameOrEmail": usernameOrEmail, "password": password},
      );
      final token = _extractToken(response.data);
      //Sauvegarder le token
      await _apiService.saveToken(token);
      if (!kIsWeb) {
        unawaited(FcmTokenService().syncCurrentToken());
      }
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  //Google Auth
  Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? _googleWebClientId : null,
        serverClientId: kIsWeb ? null : _googleServerClientId,
      );

      // Avoid stale cached sessions when previous sign-in state is corrupted.
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Connexion Google annulee');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('idToken Google manquant');
      }

      final response = await _apiService.dio.post(
        '/auth/google/mobile',
        data: {'idToken': idToken},
      );

      final token = _extractToken(response.data);

      if (token.isEmpty) {
        throw Exception('Token backend manquant');
      }

      await _apiService.saveToken(token);
      if (!kIsWeb) {
        unawaited(FcmTokenService().syncCurrentToken());
      }
    } catch (error) {
      if (error is DioException) {
        throw _mapDioError(error);
      }
      if (error is Exception) {
        rethrow;
      }
      throw Exception('Connexion Google echouee: $error');
    }
  }

  //logout
  Future<void> logout() async {
    try {
      await FcmTokenService().removeCurrentToken();
      await _apiService.dio.post("/auth/logout");
    } on DioException {
      // On nettoie le token local meme si l'appel API echoue.
    } finally {
      ChatServices().reset();
      await _apiService.logout();
    }
  }

  //Auth gate => vérifier si l'user est connecté ou pas
  Future<bool> isAuthentificated() async {
    await _apiService.init();
    final token = await _apiService.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/forgot-password',
        data: {'email': email.trim()},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return (data['message'] ?? 'Code OTP envoye').toString();
      }
      if (data is String && data.trim().isNotEmpty) {
        return data;
      }
      return 'Code OTP envoye';
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/auth/reset-password',
        data: {
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword.trim(),
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return (data['message'] ?? 'Mot de passe reinitialise').toString();
      }
      if (data is String && data.trim().isNotEmpty) {
        return data;
      }
      return 'Mot de passe reinitialise';
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }
}
