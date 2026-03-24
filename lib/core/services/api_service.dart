import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  //Initialisation de DIO
  static final ApiService _instance = ApiService._internal();
  ApiService._internal();
  factory ApiService() => _instance;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://backend-q1iu.onrender.com/api",
      headers: {"Content-Type": "application/json"},
      connectTimeout: Duration(seconds: 20),
      receiveTimeout: Duration(seconds: 20),
      sendTimeout: Duration(seconds: 20),
    ),
  );
  Dio get dio => _dio;

  //Token
  static const String _tokenKey = "token";
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  //Recup le token au lancement de lapp
  Future<void> init() async {
    String? token = await _storage.read(key: _tokenKey);
    if (token != null) {
      _dio.options.headers["Authorization"] = "Bearer $token";
    }
  }

  //Get le token
  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  //Save le token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    _dio.options.headers["Authorization"] = "Bearer $token";
  }

  //Supprimer le token du storage
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    _dio.options.headers.remove("Authorization");
  }
}
