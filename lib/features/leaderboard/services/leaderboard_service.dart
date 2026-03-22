import 'dart:async';

import 'package:ivox/core/services/api_service.dart';

class LeaderboardService {
  final ApiService _apiService = ApiService();

  Stream<List<Map<String, dynamic>>> getUserStream({
    Duration refreshEvery = const Duration(seconds: 10),
  }) async* {
    await _apiService.init();

    while (true) {
      try {
        final response = await _apiService.dio.get('/users/leaderboard');
        final data = response.data;

        if (data is List) {
          yield data
              .whereType<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
              .toList();
        } else {
          yield <Map<String, dynamic>>[];
        }
      } catch (_) {
        yield <Map<String, dynamic>>[];
      }

      await Future<void>.delayed(refreshEvery);
    }
  }
}
