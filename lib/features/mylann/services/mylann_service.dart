import 'package:dio/dio.dart';
import 'package:ivox/core/services/api_service.dart';

class MylannService {
  MylannService();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://ivox-ai.onrender.com',
      contentType: Headers.jsonContentType,
      connectTimeout: const Duration(seconds: 18),
      receiveTimeout: const Duration(seconds: 35),
      sendTimeout: const Duration(seconds: 18),
    ),
  );

  Future<String> ask({required String userId, required String text}) async {
    final api = ApiService();
    final headers = Map<String, dynamic>.from(api.dio.options.headers);
    _dio.options.headers = headers;

    Response response;
    try {
      response = await _dio.post(
        '/assistant',
        data: {'user_id': userId, 'text': text},
      );
    } on DioException catch (e) {
      // Render can briefly return 5xx during cold start; retry once.
      final status = e.response?.statusCode ?? 0;
      if (status >= 500 || status == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 550));
        response = await _dio.post(
          '/assistant',
          data: {'user_id': userId, 'text': text},
        );
      } else {
        rethrow;
      }
    }

    final data = response.data;
    if (data is Map && data['response'] is String) {
      return data['response'] as String;
    }

    return 'Mylann n\'a pas pu repondre pour le moment.';
  }
}
