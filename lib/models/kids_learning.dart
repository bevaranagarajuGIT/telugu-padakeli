import 'telugu_akshara.dart';

enum LearningCategory {
  early('చిన్నారులు', '3–5', 'Early learners'),
  explorers('బాల మిత్రులు', '6–8', 'Young explorers'),
  champions('పద వీరులు', '9–12', 'Word champions');

  const LearningCategory(this.title, this.ages, this.english);
  final String title;
  final String ages;
  final String english;
}

enum KidsActivityType { picture, letter, completion, builder, meaning }

class KidsChoice {
  const KidsChoice(this.telugu, [this.english]);
  final String telugu;
  final String? english;
}

class KidsLearningQuestion {
  const KidsLearningQuestion({
    required this.id,
    required this.prompt,
    required this.englishPrompt,
    required this.answer,
    required this.explanation,
    required this.englishExplanation,
    this.choices = const [],
    this.display,
    this.imageAsset,
    this.imageDescription,
    this.tiles = const [],
    this.completedWord,
    this.difficulty = 1,
    this.reviewStatus = 'pending-human-review',
    this.audioAsset,
  });

  final String id;
  final String prompt;
  final String englishPrompt;
  final String answer;
  final List<KidsChoice> choices;
  final String explanation;
  final String englishExplanation;
  final String? display;
  final String? imageAsset;
  final String? imageDescription;
  final List<String> tiles;
  final String? completedWord;
  final int difficulty;
  final String reviewStatus;
  // A future player must use a reviewed bundled recording, never online speech.
  final String? audioAsset;

  void validate(KidsActivityType type) {
    if (id.trim().isEmpty ||
        answer.trim().isEmpty ||
        prompt.trim().isEmpty ||
        englishPrompt.trim().isEmpty ||
        explanation.trim().isEmpty ||
        englishExplanation.trim().isEmpty ||
        difficulty < 1 ||
        difficulty > 5 ||
        !{'pending-human-review', 'reviewed'}.contains(reviewStatus)) {
      throw FormatException('Incomplete Kids content: $id');
    }
    TeluguAkshara.split(answer);
    if (type == KidsActivityType.builder) {
      final expected = TeluguAkshara.split(
        answer,
      ).map(TeluguAkshara.normalize).toList()..sort();
      final actual = <String>[];
      for (final tile in tiles) {
        if (TeluguAkshara.split(tile).length != 1) {
          throw FormatException('Invalid Kids tile: $id');
        }
        actual.add(TeluguAkshara.normalize(tile));
      }
      actual.sort();
      if (expected.length != actual.length ||
          List.generate(
            expected.length,
            (i) => expected[i] == actual[i],
          ).contains(false)) {
        throw FormatException('Kids tiles do not match answer: $id');
      }
    } else {
      final normalized = choices
          .map((choice) => TeluguAkshara.normalize(choice.telugu))
          .toList();
      for (final choice in choices) {
        if (choice.telugu.trim().isEmpty) {
          throw FormatException('Empty Telugu choice: $id');
        }
        TeluguAkshara.split(choice.telugu);
        if (choice.english != null && choice.english!.trim().isEmpty) {
          throw FormatException('Empty English choice: $id');
        }
      }
      if (choices.length < 3 ||
          normalized.toSet().length != choices.length ||
          normalized
                  .where((value) => value == TeluguAkshara.normalize(answer))
                  .length !=
              1) {
        throw FormatException('Invalid Kids choices: $id');
      }
    }
    if (type == KidsActivityType.picture &&
        (imageAsset == null ||
            !imageAsset!.startsWith('assets/artwork/') ||
            imageDescription == null ||
            imageDescription!.trim().isEmpty)) {
      throw FormatException('Missing picture description or asset: $id');
    }
    if (type == KidsActivityType.letter &&
        (display == null ||
            TeluguAkshara.split(display!).length != 1 ||
            !TeluguAkshara.equivalent(
              TeluguAkshara.split(answer).first,
              display!,
            ))) {
      throw FormatException('Invalid recognition letter: $id');
    }
    if (type == KidsActivityType.completion &&
        (display == null ||
            '_'.allMatches(display!).length != 1 ||
            TeluguAkshara.split(answer).length != 1 ||
            completedWord == null ||
            !TeluguAkshara.equivalent(
              display!.replaceFirst('_', answer),
              completedWord!,
            ))) {
      throw FormatException('Invalid missing-akshara question: $id');
    }
    if (type == KidsActivityType.completion) {
      final completed = TeluguAkshara.split(completedWord!);
      final placeholder = display!.split('_');
      final prefix = TeluguAkshara.split(placeholder[0]);
      final suffix = TeluguAkshara.split(placeholder[1]);
      final cells = [...prefix, answer, ...suffix];
      if (completed.length != cells.length ||
          List.generate(
            completed.length,
            (i) => TeluguAkshara.equivalent(completed[i], cells[i]),
          ).contains(false)) {
        throw FormatException('Missing letter breaks akshara boundaries: $id');
      }
    }
  }
}

class KidsLearningActivity {
  const KidsLearningActivity({
    required this.id,
    required this.type,
    required this.categories,
    required this.title,
    required this.englishTitle,
    required this.questions,
  });
  final String id;
  final KidsActivityType type;
  final Set<LearningCategory> categories;
  final String title;
  final String englishTitle;
  final List<KidsLearningQuestion> questions;

  void validate() {
    if (id.isEmpty ||
        title.isEmpty ||
        englishTitle.isEmpty ||
        categories.isEmpty ||
        questions.isEmpty) {
      throw FormatException('Invalid Kids activity: $id');
    }
    final ids = <String>{};
    final prompts = <String>{};
    for (final question in questions) {
      question.validate(type);
      if (!ids.add(question.id) ||
          !prompts.add(
            '${question.prompt}|${question.display}|${question.imageAsset}',
          )) {
        throw FormatException('Duplicate Kids question: ${question.id}');
      }
    }
  }
}
