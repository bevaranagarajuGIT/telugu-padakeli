import 'package:flutter/foundation.dart';

import '../models/kids_learning.dart';
import '../models/telugu_akshara.dart';
import '../services/kids_answer_order.dart';
import 'learning_progress.dart';

enum KidsAnswerState { ready, incorrect, correct }

class KidsActivitySession extends ChangeNotifier {
  KidsActivitySession(this.activity, this.onCompleted, {this.storage}) {
    _restore(savedMap(storage?.sessions[activity.id]));
  }
  final KidsLearningActivity activity;
  final VoidCallback onCompleted;
  final LearningProgress? storage;
  final _solved = <String, String>{};
  int _index = 0;
  int _score = 0;
  String? _choice;
  final _tiles = <int>[];
  KidsAnswerState _answerState = KidsAnswerState.ready;
  bool _complete = false;
  bool _earnedStarOnCompletion = false;
  int _answerOrderSeed = newAnswerOrderSeed();

  KidsLearningQuestion get question => activity.questions[_index];
  List<KidsChoice> get choices => orderedKidsChoices(
    question.choices,
    isAnswer: (choice) =>
        TeluguAkshara.equivalent(choice.telugu, question.answer),
    seed: _answerOrderSeed,
    questionIndex: _index,
  );
  int get index => _index;
  int get score => _score;
  String? get choice => _choice;
  List<int> get selectedTiles => List.unmodifiable(_tiles);
  KidsAnswerState get answerState => _answerState;
  bool get complete => _complete;
  bool get earnedStarOnCompletion => _earnedStarOnCompletion;
  bool get locked => _complete || _answerState == KidsAnswerState.correct;
  double get progress => _complete ? 1 : _score / activity.questions.length;

  static bool hasSavedCompletion(
    KidsLearningActivity activity,
    Map<String, dynamic> saved,
  ) {
    final solved = savedMap(saved['solved']);
    return saved['complete'] == true &&
        activity.questions.every(
          (item) => solved[item.id] == item.progressSignature,
        );
  }

  void _restore(Map<String, dynamic> saved) {
    final seed = saved['answerOrderSeed'];
    if (seed is int && seed >= 0 && seed <= 0x7fffffff) {
      _answerOrderSeed = seed;
    }
    final solved = savedMap(saved['solved']);
    for (final item in activity.questions) {
      if (solved[item.id] == item.progressSignature) {
        _solved[item.id] = item.progressSignature;
      }
    }
    _score = _solved.length;
    final position = activity.questions.indexWhere(
      (item) => item.id == saved['questionId'],
    );
    final firstUnsolved = activity.questions.indexWhere(
      (item) => !_solved.containsKey(item.id),
    );
    _index = firstUnsolved >= 0 && position > firstUnsolved
        ? firstUnsolved
        : position >= 0
        ? position
        : firstUnsolved >= 0
        ? firstUnsolved
        : 0;
    _complete = hasSavedCompletion(activity, saved);
    if (saved['signature'] == question.progressSignature) {
      final choice = saved['choice'];
      if (choice is String &&
          question.choices.any((item) => item.telugu == choice)) {
        _choice = choice;
      }
      final tiles = saved['tiles'];
      if (tiles is List &&
          tiles.every(
            (item) => item is int && item >= 0 && item < question.tiles.length,
          ) &&
          tiles.toSet().length == tiles.length) {
        _tiles.addAll(tiles.cast<int>());
      }
      if (saved['answerState'] == KidsAnswerState.incorrect.name) {
        _answerState = KidsAnswerState.incorrect;
      }
    }
    if (_solved.containsKey(question.id)) {
      _answerState = KidsAnswerState.correct;
    }
  }

  Map<String, dynamic> snapshot() => {
    'questionId': question.id,
    'signature': question.progressSignature,
    'solved': Map<String, String>.of(_solved),
    'choice': _choice,
    'tiles': List<int>.of(_tiles),
    'answerState': _answerState.name,
    'complete': _complete,
    'answerOrderSeed': _answerOrderSeed,
  };

  void selectChoice(String value) {
    if (locked || !question.choices.any((choice) => choice.telugu == value)) {
      return;
    }
    _choice = value;
    _answerState = KidsAnswerState.ready;
    notifyListeners();
  }

  void selectTile(int index) {
    if (locked ||
        index < 0 ||
        index >= question.tiles.length ||
        _tiles.contains(index)) {
      return;
    }
    _tiles.add(index);
    _answerState = KidsAnswerState.ready;
    notifyListeners();
  }

  void undoTile() {
    if (locked || _tiles.isEmpty) return;
    _tiles.removeLast();
    _answerState = KidsAnswerState.ready;
    notifyListeners();
  }

  void removeTile(int index) {
    if (locked || !_tiles.remove(index)) return;
    _answerState = KidsAnswerState.ready;
    notifyListeners();
  }

  void clearAttempt() {
    if (locked) return;
    _tiles.clear();
    _choice = null;
    _answerState = KidsAnswerState.ready;
    notifyListeners();
  }

  bool check() {
    if (locked) return _answerState == KidsAnswerState.correct;
    final building = activity.type == KidsActivityType.builder;
    final input = building
        ? _tiles.map((index) => question.tiles[index]).join()
        : _choice;
    final correct =
        input != null &&
        (!building || _tiles.length == question.tiles.length) &&
        TeluguAkshara.equivalent(input, question.answer);
    _answerState = correct
        ? KidsAnswerState.correct
        : KidsAnswerState.incorrect;
    if (input != null && (!building || _tiles.isNotEmpty)) {
      storage?.recordAnswer(
        'kids:${activity.id}:${question.id}:${question.progressSignature}',
        correct,
      );
    }
    if (correct) {
      _solved[question.id] = question.progressSignature;
      _score = _solved.length;
    }
    notifyListeners();
    return correct;
  }

  void next() {
    if (_complete || _answerState != KidsAnswerState.correct) return;
    if (_index + 1 == activity.questions.length) {
      _complete = true;
      _earnedStarOnCompletion = false;
      onCompleted();
    } else {
      _index++;
      _choice = null;
      _tiles.clear();
      _answerState = _solved.containsKey(question.id)
          ? KidsAnswerState.correct
          : KidsAnswerState.ready;
    }
    notifyListeners();
  }

  void restart() {
    _answerOrderSeed = newAnswerOrderSeed();
    _index = 0;
    _solved.clear();
    _score = 0;
    _choice = null;
    _tiles.clear();
    _complete = false;
    _earnedStarOnCompletion = false;
    _answerState = KidsAnswerState.ready;
    notifyListeners();
  }
}

class KidsLearningController extends ChangeNotifier {
  KidsLearningController({this.storage}) {
    _category =
        LearningCategory.values
            .where((category) => category.name == storage?.category)
            .firstOrNull ??
        LearningCategory.early;
    _completed.addAll(storage?.completedActivities ?? {});
  }
  final LearningProgress? storage;
  LearningCategory _category = LearningCategory.early;
  final _sessions = <String, KidsActivitySession>{};
  final _completed = <String>{};

  LearningCategory get category => _category;
  int get stars => storage?.stars ?? _completed.length;
  bool completed(String id) => _completed.contains(id);

  void selectCategory(LearningCategory value) {
    if (_category == value) return;
    _category = value;
    storage?.selectCategory(value.name);
    notifyListeners();
  }

  KidsActivitySession sessionFor(KidsLearningActivity activity) =>
      _sessions.putIfAbsent(activity.id, () {
        late final KidsActivitySession session;
        session = KidsActivitySession(activity, () {
          final fresh = _completed.add(activity.id);
          session._earnedStarOnCompletion =
              storage?.completeActivity(activity.id) ?? fresh;
          if (session.earnedStarOnCompletion) notifyListeners();
        }, storage: storage);
        session.addListener(() {
          storage?.saveSession(activity.id, session.snapshot());
          notifyListeners();
        });
        return session;
      });

  KidsActivitySession? existingSession(String id) => _sessions[id];

  @override
  void dispose() {
    for (final session in _sessions.values) {
      session.dispose();
    }
    super.dispose();
  }
}
