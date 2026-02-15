import 'package:ivox/features/dictionnaire/models/word.dart';

class Dictionnaire {
  final Map<String, List<Word>> data;

  Dictionnaire({required this.data});

  factory Dictionnaire.fromJson(Map<String, dynamic> json) {
    Map<String, List<Word>> data = {};

    json.forEach((key, value) {
      if (value is List) {
        data[key] = (value)
            .map((word) => Word.fromJson(word as Map<String, dynamic>))
            .toList();
      }
    });

    return Dictionnaire(data: data);
  }
}
