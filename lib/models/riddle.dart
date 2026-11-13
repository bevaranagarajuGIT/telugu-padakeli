import '../core/learning_progress.dart';

enum RiddleLevel {
  spark(
    'మొదటి మెరుపు',
    'First spark',
    'ఒక చిన్న పొడుపుతో మొదలుపెడదాం!',
    'భలే! మీ ఆలోచనలకు మంచి ఆరంభం.',
  ),
  trail(
    'ఆలోచనల ఆట',
    'Brainwave trail',
    'కొత్త కోణంలో ఆలోచిద్దాం!',
    'చక్కగా ఆలోచించారు! కొత్త సవాళ్లకు ముందుకు!',
  ),
  hero(
    'పొడుపుల వీరుడు',
    'Riddle hero',
    'మరో సవాలుకు సిద్ధమేనా?',
    'భలే! పొడుపుల వీరుడిగా ముందడుగు వేశారు!',
  ),
  nature(
    'ప్రకృతి పలుకులు',
    'Nature whispers',
    'మన చుట్టూ ప్రకృతి చెప్పే పొడుపులు వినండి!',
    'అద్భుతం! ప్రకృతి రహస్యాలను కనుగొన్నారు!',
  ),
  mysteries(
    'చిట్టి రహస్యాలు',
    'Little mysteries',
    'రోజూ చూసే వస్తువుల్లో రహస్యాలను వెతుకుదాం!',
    'భలే! చిన్న విషయాల్లో గొప్ప తెలివి చూపించారు!',
  ),
  champion(
    'పొడుపుల విజేత',
    'Riddle champion',
    'ఆలోచనకు పదును పెట్టండి. చివరి సవాలు మొదలు!',
    'అద్భుతం! పొడుపుల యాత్రలో విజేతగా నిలిచారు!',
  );

  const RiddleLevel(
    this.title,
    this.englishTitle,
    this.invitation,
    this.celebration,
  );

  final String title;
  final String englishTitle;
  final String invitation;
  final String celebration;
}

class RiddleProgress {
  RiddleProgress(this.riddles, this._answers);

  final List<Riddle> riddles;
  final Map<String, dynamic> _answers;

  List<RiddleLevel> get levels => RiddleLevel.values
      .where((level) => riddles.any((riddle) => riddle.level == level))
      .toList();

  List<Riddle> riddlesIn(RiddleLevel level) =>
      riddles.where((riddle) => riddle.level == level).toList();

  bool isSolved(Riddle riddle) {
    final record = savedMap(_answers[riddle.id]);
    return record['signature'] == riddle.signature && record['solved'] == true;
  }

  int get solvedCount => riddles.where(isSolved).length;
  int solvedIn(RiddleLevel level) => riddlesIn(level).where(isSolved).length;
  bool isLevelComplete(RiddleLevel level) {
    final group = riddlesIn(level);
    return group.isNotEmpty && group.every(isSolved);
  }

  int get completedLevelCount => levels.where(isLevelComplete).length;
  RiddleLevel? get nextLevel =>
      levels.where((level) => !isLevelComplete(level)).firstOrNull;
  bool isUnlocked(RiddleLevel level) =>
      levels.contains(level) &&
      levels.takeWhile((item) => item != level).every(isLevelComplete);
}

class Riddle {
  const Riddle({
    required this.id,
    required this.question,
    required this.answer,
    required this.choices,
    required this.hint,
    required this.explanation,
    this.level = RiddleLevel.spark,
  });

  final String id;
  final String question;
  final String answer;
  final List<String> choices;
  final String hint;
  final String explanation;
  final RiddleLevel level;

  // Level placement must not invalidate previously saved answer signatures.
  String get signature =>
      contentSignature([id, question, answer, choices, hint, explanation]);

  factory Riddle.fromJson(Map<String, dynamic> json) {
    String text(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Riddle $key must be non-empty text.');
      }
      return value;
    }

    final choices = json['choices'];
    if (choices is! List || choices.any((value) => value is! String)) {
      throw const FormatException('Riddle choices must be text.');
    }
    final levelId = json['level'] ?? RiddleLevel.spark.name;
    final level = RiddleLevel.values
        .where((level) => level.name == levelId)
        .firstOrNull;
    if (level == null) {
      throw FormatException('Unknown riddle level: $levelId.');
    }
    final riddle = Riddle(
      id: text('id'),
      question: text('question'),
      answer: text('answer'),
      choices: List.unmodifiable(choices.cast<String>()),
      hint: text('hint'),
      explanation: text('explanation'),
      level: level,
    );
    riddle.validate();
    return riddle;
  }

  void validate() {
    if ([
          id,
          question,
          answer,
          hint,
          explanation,
        ].any((value) => value.trim().isEmpty) ||
        choices.length != 4 ||
        choices.toSet().length != 4 ||
        choices.any((value) => value.trim().isEmpty) ||
        !choices.contains(answer)) {
      throw FormatException('Invalid riddle: $id.');
    }
  }
}
