import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:ivox/features/dictionnaire/models/dictionnaire.dart';

class DictionnaireService {
  static Future<Dictionnaire> loadDictionary() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/json/dictionnaire.json',
      );
      final jsonData = await jsonDecode(jsonString) as Map<String, dynamic>;
      return Dictionnaire.fromJson(jsonData);
    } catch (e) {
      print("Error $e");
      rethrow;
    }
  }
}
