import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ivox/core/services/api_service.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
  });
}

class UserDocSnapshot {
  final Map<String, dynamic> _data;

  UserDocSnapshot(this._data);

  Map<String, dynamic> data() => _data;
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  AuthService._internal();
  factory AuthService() => _instance;

  final ApiService _apiService = ApiService();
  final StreamController<UserDocSnapshot> _userController =
      StreamController<UserDocSnapshot>.broadcast();

  AppUser? _currentUser;
  Map<String, dynamic> _currentProfile = {
    'username': 'Utilisateur',
    'email': '',
    'photoUrl': null,
    'level': 1,
    'xp': 0,
    'isPublicProfile': true,
  };

  AppUser? getUser() => _currentUser;

  Stream<UserDocSnapshot> userDocStream() {
    _bootstrap();
    return _userController.stream;
  }

  Future<void> _bootstrap() async {
    await _apiService.init();
    final token = await _apiService.getToken();
    if (token == null || token.isEmpty) {
      _currentUser = null;
      _pushProfile();
      return;
    }

    try {
      final response = await _apiService.dio.get('/auth/me');
      final data = _toMap(response.data);
      final id = (data['id'] ?? '').toString();
      final username = (data['username'] ?? 'Utilisateur').toString();
      final email = (data['email'] ?? '').toString();

      if (id.isEmpty) {
        return;
      }

      _currentUser = AppUser(uid: id, email: email, displayName: username);
      _currentProfile = {
        ..._currentProfile,
        'username': username,
        'email': email,
        'photoUrl': data['photoUrl'],
        'level': data['level'] ?? 1,
        'xp': data['xp'] ?? 0,
        'isPublicProfile': data['isPublicProfile'] ?? true,
      };
      _pushProfile();
    } catch (_) {
      // Keep previous cached user/profile when network is unavailable.
    }
  }

  Future<void> updateUsername(String username) async {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      throw Exception("Nom d'utilisateur invalide");
    }

    _currentProfile = {..._currentProfile, 'username': normalized};
    _currentUser = AppUser(
      uid: _currentUser?.uid ?? '',
      email: _currentUser?.email,
      displayName: normalized,
    );
    _pushProfile();
  }

  Future<void> updatePhotoUrl(String photoUrl) async {
    _currentProfile = {..._currentProfile, 'photoUrl': photoUrl};
    _pushProfile();
  }

  Future<void> updateProfilePrivacy(bool isPublicProfile) async {
    await _apiService.init();
    final token = await _apiService.getToken();
    print('DEBUG updateProfilePrivacy: token=$token');
    
    try {
      final response = await _apiService.dio.patch(
        '/auth/privacy',
        data: {'isPublicProfile': isPublicProfile},
      );
      print('DEBUG updateProfilePrivacy success: $response');
      _currentProfile = {
        ..._currentProfile,
        'isPublicProfile': isPublicProfile,
      };
      _pushProfile();
    } on DioException catch (e) {
      print('DEBUG updateProfilePrivacy DioException: ${e.message}');
      print('DEBUG statusCode: ${e.response?.statusCode}');
      print('DEBUG response: ${e.response?.data}');
      throw Exception('${e.response?.data?['message'] ?? e.message ?? "Erreur reseau"}');
    } catch (e) {
      print('DEBUG updateProfilePrivacy error: $e');
      throw Exception('$e');
    }
  }

  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = getUser();
    if (user == null || user.uid.isEmpty) {
      throw Exception('Utilisateur non connecté');
    }

    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await _apiService.dio.post(
      '/auth/profile-image',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = _toMap(response.data);
    final photoUrl = (data['photoUrl'] ?? '').toString();
    if (photoUrl.isEmpty) {
      throw Exception('URL image manquante');
    }

    return photoUrl;
  }

  Future<void> logout() async {
    _currentUser = null;
    _currentProfile = {
      'username': 'Utilisateur',
      'email': '',
      'photoUrl': null,
      'level': 1,
      'xp': 0,
      'isPublicProfile': true,
    };
    _pushProfile();
  }

  void _pushProfile() {
    if (!_userController.isClosed) {
      _userController.add(UserDocSnapshot(Map<String, dynamic>.from(_currentProfile)));
    }
  }

  Map<String, dynamic> _toMap(dynamic input) {
    if (input is Map<String, dynamic>) {
      return input;
    }
    if (input is Map) {
      return input.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
