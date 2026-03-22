import 'package:dio/dio.dart';
import 'package:ivox/core/services/api_service.dart';

class ShopServices {
  final ApiService _apiService = ApiService();

  String _extractErrorMessage(dynamic data, [String fallback = "Erreur reseau"]) {
    if (data is Map<String, dynamic>) {
      final message = data["message"];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (data is Map) {
      final message = data["message"];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }

  Future<List<Map<String, dynamic>>> getItemsByType(String type) async {
    await _apiService.init();

    try {
      final response = await _apiService.dio.get(
        "/shopItem/",
        queryParameters: {"type": type},
      );

      final data = response.data;
      if (data is! List) {
        return <Map<String, dynamic>>[];
      }

      return data
          .whereType<Map>()
          .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getShopData() async {
    final results = await Future.wait([
      getItemsByType("song"),
      getItemsByType("animation"),
      getItemsByType("avatar"),
    ]);

    return {
      "song": results[0],
      "animation": results[1],
      "avatar": results[2],
    };
  }

  Future<List<Map<String, dynamic>>> getOwnedItems() async {
    await _apiService.init();

    try {
      final response = await _apiService.dio.get("/auth/me");
      final data = response.data;

      dynamic owned;
      if (data is Map<String, dynamic>) {
        owned = data["ownedItems"];
      } else if (data is Map) {
        owned = data["ownedItems"];
      }

      if (owned is! List) {
        return <Map<String, dynamic>>[];
      }

      return owned
          .whereType<Map>()
          .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> buyItem({required String itemId, required String type}) async {
    await _apiService.init();

    try {
      await _apiService.dio.post(
        "/shopItem/$itemId/buy",
        data: {"type": type},
      );
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error.response?.data));
    } catch (_) {
      throw Exception("Erreur lors de l'achat");
    }
  }
}
