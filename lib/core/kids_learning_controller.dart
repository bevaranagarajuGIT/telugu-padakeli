import 'package:flutter/foundation.dart';

import '../models/kids_learning.dart';
import '../models/telugu_akshara.dart';

enum KidsAnswerState { ready, incorrect, correct }

class KidsActivitySession extends ChangeNotifier {
  KidsActivitySession(this.activity, this.onCompleted);
  final KidsLearningActivity activity;
  final VoidCallback onCompleted;
  int _index = 0;
  int _score = 0;
  String? _choice;
  final _tiles = <int>[];
  KidsAnswerState _answerState = KidsAnswerState.ready;
  bool _complete = false;

  KidsLearningQuestion get question => activity.questions[_index];
  int get index => _index;
  int get score => _score;
  String? get choice => _choice;
  List<int> get selectedTiles => List.unmodifiable(_tiles);
  KidsAnswerState get answerState => _answerState;
  bool get complete => _complete;
  bool get locked => _complete || _answerState == KidsAnswerState.correct;
  double get progress => _complete ? 1 : _score / activity.questions.length;

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
    if (correct) _score++;
    notifyListeners();
    return correct;
  }

  void next() {
    if (_complete || _answerState != KidsAnswerState.correct) return;
    if (_index + 1 == activity.questions.length) {
      _complete = true;
      onCompleted();
    } else {
      _index++;
      _choice = null;
      _tiles.clear();
      _answerState = KidsAnswerState.ready;
    }
    notifyListeners();
  }

  void restart() {
    _index = 0;
    _score = 0;
    _choice = null;
    _tiles.clear();
    _complete = false;
    _answerState = KidsAnswerState.ready;
    notifyListeners();
  }
}

class KidsLearningController extends ChangeNotifier {
  LearningCategory _category = LearningCategory.early;
  final _sessions = <String, KidsActivitySession>{};
  final _completed = <String>{};

  LearningCategory get category => _category;
  int get stars => _completed.length;
  bool completed(String id) => _completed.contains(id);

  void selectCategory(LearningCategory value) {
    if (_category == value) return;
    _category = value;
    notifyListeners();
  }

  KidsActivitySession sessionFor(KidsLearningActivity activity) =>
      _sessions.putIfAbsent(
        activity.id,
        () => KidsActivitySession(activity, () {
          if (_completed.add(activity.id)) notifyListeners();
        }),
      );

  KidsActivitySession? existingSession(String id) => _sessions[id];

  @override
  void dispose() {
    for (final session in _sessions.values) {
      session.dispose();
    }
    super.dispose();
  }
}
