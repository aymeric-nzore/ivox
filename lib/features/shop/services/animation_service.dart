import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';

class Animation {
  final String id;
  final String title;
  final String assetUrl;
  final int duration;
  final String format;
  final int price;
  final bool isActive;

  Animation({
    required this.id,
    required this.title,
    required this.assetUrl,
    required this.duration,
    required this.format,
    required this.price,
    this.isActive = false,
  });

  factory Animation.fromJson(Map<String, dynamic> json) {
    return Animation(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      assetUrl: json['assetUrl'] ?? '',
      duration: json['duration'] ?? 0,
      format: json['format'] ?? 'lottie',
      price: json['price'] ?? 0,
      isActive: json['isActive'] ?? false,
    );
  }
}

class AnimationService {
  final Dio _dio;

  AnimationService({required ApiService apiService})
      : _dio = apiService.dio;

  // Récupérer toutes les animations (splash screen)
  Future<List<Animation>> getSplashAnimations() async {
    try {
      final response = await _dio.get(
        '/shopItem',
        queryParameters: {'itemType': 'animation'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : response.data['animations'] ?? [];
        return data
            .map((json) => Animation.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Erreur récupération animations');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Erreur réseau');
    }
  }

  // Récupérer les animations possédées
  Future<List<Animation>> getOwnedAnimations() async {
    try {
      final response = await _dio.get(
        '/shopItem/animation/owned',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['animations'] ?? [];
        return data
            .map((json) => Animation.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Erreur récupération animations possédées');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Erreur réseau');
    }
  }

  // Récupérer l'animation équipée
  Future<Animation?> getActiveSplashAnimation() async {
    try {
      final response = await _dio.get(
        '/shopItem/animation/active',
      );

      if (response.statusCode == 200) {
        final payload = response.data;
        if (payload is! Map<String, dynamic>) {
          return null;
        }

        final nested = payload['animation'];
        if (nested is Map<String, dynamic>) {
          return Animation.fromJson(nested);
        }

        if (payload['id'] != null || payload['_id'] != null) {
          return Animation.fromJson(payload);
        }
      }
      return null;
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Erreur réseau');
    }
  }

  // Acheter une animation
  Future<String> buyAnimation(String animationId) async {
    try {
      final response = await _dio.post(
        '/shopItem/$animationId/buy',
        data: {'type': 'animation'},
      );

      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Animation achetée';
      }
      throw Exception(response.data['message'] ?? 'Erreur achat');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message ?? 'Erreur achat');
    }
  }

  // Équiper une animation
  Future<String> equipAnimation(String animationId) async {
    try {
      final response = await _dio.post(
        '/shopItem/animation/equip',
        data: {'animationId': animationId},
      );

      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Animation équipée';
      }
      throw Exception(response.data['message'] ?? 'Erreur équipement');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? e.message ?? 'Erreur équipement');
    }
  }

  // Déséquiper l'animation (retour défaut)
  Future<String> unequipAnimation() async {
    try {
      final response = await _dio.post('/shopItem/animation/unequip');

      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Animation déséquipée';
      }
      throw Exception(response.data['message'] ?? 'Erreur déséquipement');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? e.message ?? 'Erreur déséquipement');
    }
  }
}
