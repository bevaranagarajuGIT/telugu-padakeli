import 'telugu_akshara.dart';

class KidsQuestion {
  const KidsQuestion({
    required this.prompt,
    required this.answer,
    required this.hint,
    required this.englishHint,
    required this.options,
  });

  final String prompt;
  final String answer;
  final String hint;
  final String englishHint;
  final List<String> options;

  String get completedWord => prompt.replaceFirst('_', answer);

  void validate() {
    if ('_'.allMatches(prompt).length != 1 ||
        hint.trim().isEmpty ||
        englishHint.trim().isEmpty ||
        TeluguAkshara.split(answer).length != 1 ||
        options.length < 3) {
      throw FormatException('Invalid original-practice question: $prompt');
    }
    final normalized = options.map(TeluguAkshara.normalize).toList();
    for (final option in options) {
      if (TeluguAkshara.split(option).length != 1) {
        throw FormatException('Invalid original-practice option: $prompt');
      }
    }
    if (normalized.toSet().length != options.length ||
        normalized
                .where((value) => value == TeluguAkshara.normalize(answer))
                .length !=
            1) {
      throw FormatException('Ambiguous original-practice answer: $prompt');
    }
    final parts = prompt.split('_');
    final cells = [
      ...TeluguAkshara.split(parts.first),
      answer,
      ...TeluguAkshara.split(parts.last),
    ];
    final word = TeluguAkshara.split(completedWord);
    if (cells.length != word.length ||
        Iterable<int>.generate(cells.length).any(
          (index) => !TeluguAkshara.equivalent(cells[index], word[index]),
        )) {
      throw FormatException('Broken original-practice akshara: $prompt');
    }
  }
}

class KidsQuestionLevel {
  const KidsQuestionLevel({
    required this.name,
    required this.title,
    required this.questions,
    this.difficulty = 1,
  });

  final String name;
  final String title;
  final List<KidsQuestion> questions;
  final int difficulty;
}
