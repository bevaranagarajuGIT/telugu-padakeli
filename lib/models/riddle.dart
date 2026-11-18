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
    'ఆలోచనకు పదును పెట్టండి. మరో గొప్ప సవాలు మొదలు!',
    'అద్భుతం! పొడుపుల యాత్రలో విజేతగా నిలిచారు!',
  ),
  garden(
    'తోటలో వింతలు',
    'Garden discoveries',
    'తోటలో దాగిన కొత్త పొడుపులను కనిపెడదాం!',
    'భలే! తోటలోని వింతలను చక్కగా గుర్తించారు!',
  ),
  workshop(
    'రోజుకో అద్భుతం',
    'Everyday wonders',
    'చిన్న వస్తువులు చేసే పెద్ద పనులను ఊహించండి!',
    'అద్భుతం! రోజూ చూసే వస్తువుల్లో కొత్తదనం కనుగొన్నారు!',
  ),
  sky(
    'ఆకాశ యాత్ర',
    'Sky explorer',
    'ఆకాశం వైపు చూసి ఆలోచనలను ఎగరనిద్దాం!',
    'శభాష్! మీ ఆలోచనలు ఆకాశమంత ఎత్తుకు చేరాయి!',
  ),
  home(
    'ఇంటింటి విశేషాలు',
    'Around the home',
    'చుట్టూ ఉన్న వస్తువుల్లో కొత్తదనం వెతుకుదాం!',
    'భలే! పరిచయమైన వాటిని కొత్తగా చూశారు!',
  ),
  school(
    'నేర్చుకునే లోకం',
    'Learning discoveries',
    'చదువుకు తోడయ్యే మిత్రులను గుర్తిద్దాం!',
    'అద్భుతం! నేర్చుకునే యాత్రలో మరో ముందడుగు!',
  ),
  kitchen(
    'వంటింటి కబుర్లు',
    'Kitchen discoveries',
    'రుచుల వెనుక ఉన్న విశేషాలను ఊహిద్దాం!',
    'భలే! వంటింటి కబుర్లను చక్కగా విప్పారు!',
  ),
  wildlife(
    'జీవుల జాడలు',
    'Wildlife clues',
    'జీవుల లక్షణాలు గమనించి జవాబు వెతుకుదాం!',
    'శభాష్! ప్రకృతిని శ్రద్ధగా గమనించారు!',
  ),
  journeys(
    'ప్రయాణ మిత్రులు',
    'Journey companions',
    'దారి చూపే పొడుపులతో ప్రయాణిద్దాం!',
    'భలే! ఆలోచనల ప్రయాణంలో కొత్త మలుపు!',
  ),
  celebrations(
    'సంబరాల సందడి',
    'Celebrations and traditions',
    'కళలు, పండుగలలోని విశేషాలు తెలుసుకుందాం!',
    'అద్భుతం! మన సంప్రదాయాల్లో కొత్త సంగతులు కనుగొన్నారు!',
  ),
  science(
    'విజ్ఞాన వెలుగులు',
    'Science discoveries',
    'ఎందుకు, ఎలా అని ఆలోచిస్తూ ముందుకు సాగుదాం!',
    'శభాష్! కారణాలను చక్కగా గుర్తించారు!',
  ),
  digital(
    'సాంకేతిక మిత్రులు',
    'Digital discoveries',
    'తెర వెనుక పనుల్ని తెలివిగా గుర్తిద్దాం!',
    'భలే! సాంకేతిక లోకంలో మరో ముందడుగు!',
  ),
  language(
    'మాటల మాయ',
    'Language discoveries',
    'మాటల్లోని భావాలను కనిపెడదాం!',
    'అద్భుతం! భాషలోని మెళకువలు గుర్తించారు!',
  ),
  reasoning(
    'తర్కపు మెట్లు',
    'Reasoning steps',
    'నెమ్మదిగా ఆలోచించండి; ప్రతి ఆధారం ఉపయోగపడుతుంది!',
    'శభాష్! కారణంతో జవాబులు కనుగొన్నారు!',
  ),
  horizons(
    'కొత్త దిశలు',
    'New horizons',
    'నేర్చుకున్న వాటితో కొత్త ప్రశ్నలను ఎదుర్కొందాం!',
    'అద్భుతం! ప్రశ్నించే మీ ఆసక్తి ఇలాగే కొనసాగాలి!',
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
