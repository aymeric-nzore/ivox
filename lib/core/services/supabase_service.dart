import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://ctrttsuqewnkoounjcfe.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_prTCcMFFqUhlrv8uCXrvtg_uNKJtACo';

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String userId,
    required String fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanFileName = fileName.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\-\.]'), '');
      final path = 'profile_photos/$userId/${timestamp}_$cleanFileName';

      await client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = client.storage.from('avatars').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Erreur upload Supabase: $e');
    }
  }
}
