class Word {
  final String mot;
  final String traduction;
  final List<String> alternative;
  final String exemple;
  final String traductionExemple;

  Word({
    required this.mot,
    required this.traduction,
    required this.alternative,
    required this.exemple,
    required this.traductionExemple,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      mot: json['mot'] ?? '',
      traduction: json['traduction'] ?? '',
      alternative: List<String>.from(json['alternative'] ?? []),
      exemple: json['exemple'] ?? '',
      traductionExemple: json['traduction_exemple'] ?? '',
    );
  }
}
