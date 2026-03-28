import 'package:dio/dio.dart';
import 'package:ivox/core/services/api_service.dart';

class MylannService {
  Future<String> ask({required String userId, required String text}) async {
    final api = ApiService();
    final headers = Map<String, dynamic>.from(api.dio.options.headers);

    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://ivox-ai.onrender.com',
        headers: headers,
        contentType: Headers.jsonContentType,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 20),
      ),
    );

    final response = await dio.post(
      '/assistant',
      data: {'user_id': userId, 'text': text},
    );

    final data = response.data;
    if (data is Map && data['response'] is String) {
      return data['response'] as String;
    }

    return 'Mylann n\'a pas pu repondre pour le moment.';
  }
}
