import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../services/learning_store.dart';

Map<String, dynamic> savedMap(Object? value) =>
    value is Map<String, dynamic> ? Map.of(value) : {};

String calendarDay(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

// Exact canonical content, rather than a process-dependent hash or list index.
String contentSignature(Object value) => jsonEncode(value);

class LearningProgress extends ChangeNotifier {
  LearningProgress(
    this.store, {
    DateTime Function()? clock,
    this.autoSave = true,
  }) : clock = clock ?? DateTime.now;

  final LearningStore store;
  final bool autoSave;
  final DateTime Function() clock;
  Map<String, dynamic> _data = {'version': 1};
  Future<void> _writes = Future.value();
  Timer? _debounce;
  bool _dirty = false;
  bool _blocked = false;
  bool _disposed = false;
  String? storageError;
  String? recoveryNotice;
  int resetRevision = 0;

  Map<String, dynamic> _section(String name) =>
      _data.putIfAbsent(name, () => <String, dynamic>{})
          as Map<String, dynamic>;

  Future<void> load() async {
    try {
      final raw = await store.read();
      if (raw == null) return;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic> || decoded['version'] is! int) {
          throw const FormatException('Missing saved-data schema.');
        }
        if (decoded['version'] != 1) {
          _blocked = true;
          recoveryNotice =
              'This saved-data version is not supported. It has been kept '
              'unchanged. Update the app or explicitly reset progress.';
          return;
        }
        final damagedSections = <String>[];
        for (final section in [
          'settings',
          'sessions',
          'boards',
          'daily',
          'answers',
          'days',
          'activities',
          'puzzles',
          'rewards',
          'achievements',
          'practice',
        ]) {
          if (decoded.containsKey(section) &&
              decoded[section] is! Map<String, dynamic>) {
            damagedSections.add(section);
          }
        }
        if (!decoded.containsKey('rewards') &&
            (savedMap(decoded['activities']).isNotEmpty ||
                savedMap(decoded['puzzles']).isNotEmpty)) {
          damagedSections.add('rewards');
        }
        if (damagedSections.isNotEmpty) {
          await store.preserveRecoveryCopy(raw);
          for (final section in damagedSections) {
            decoded[section] = <String, dynamic>{};
          }
          if (damagedSections.contains('rewards')) {
            _blocked = true;
            recoveryNotice =
                'Saved reward identities are unreadable or missing. Readable '
                'progress is available, but play is temporary and no stars '
                'will be awarded. The original save and recovery copy have '
                'been kept unchanged. Recover the save or explicitly reset '
                'progress before saving again.';
          } else {
            recoveryNotice =
                'Unreadable saved sections (${damagedSections.join(', ')}) '
                'were recovered as empty. All other readable progress was '
                'kept. The original save is preserved in a recovery copy.';
          }
        }
        _data = decoded;
      } on FormatException {
        await store.preserveRecoveryCopy(raw);
        recoveryNotice =
            'Unreadable saved data was preserved in a recovery copy. '
            'You can start again; onboarding has not been reset.';
      }
    } on Exception catch (error) {
      _blocked = true;
      storageError =
          'Saved data could not be opened. Play is temporary; the original '
          'save has not been overwritten. Restart the app to retry.';
      debugPrint('Learning storage read failed: ${error.runtimeType}');
    }
  }

  Map<String, dynamic> get settings => savedMap(_data['settings']);
  Map<String, dynamic> get sessions => savedMap(_data['sessions']);
  Map<String, dynamic> get practice => savedMap(_data['practice']);
  Map<String, dynamic> board(String slot) => savedMap(_section('boards')[slot]);
  Map<String, dynamic> daily(String day) => savedMap(_section('daily')[day]);
  String? get lastDestination => _data['lastDestination'] is String
      ? _data['lastDestination'] as String
      : null;
  String? get lastActivity =>
      _data['lastActivity'] is String ? _data['lastActivity'] as String : null;
  String? get category =>
      _data['category'] is String ? _data['category'] as String : null;
  bool get hasClassic => board('classic').isNotEmpty;
  String? get lastDailyDate => _data['lastDailyDate'] is String
      ? _data['lastDailyDate'] as String
      : null;
  int get dailyGoal {
    final goal = settings['dailyGoal'];
    return goal is int && goal >= 1 && goal <= 10 ? goal : 3;
  }

  bool get canRetrySave => !_blocked && storageError != null;

  String get today => calendarDay(clock());
  int get stars => _section('rewards').length;
  Set<String> get completedActivities => _section('activities').keys.toSet();
  Set<String> get completedPuzzles => _section('puzzles').keys.toSet();
  Set<String> get achievements => _section('achievements').keys.toSet();
  int get checkedQuestions => _section('answers').length;
  int get firstAttemptCorrect => _section(
    'answers',
  ).values.where((value) => savedMap(value)['firstCorrect'] == true).length;
  int get attempts => _section(
    'answers',
  ).values.fold(0, (sum, value) => sum + _count(savedMap(value)['attempts']));
  int get eventuallyCorrect => _section(
    'answers',
  ).values.where((value) => savedMap(value)['correct'] == true).length;
  Map<String, dynamic> get todayRecord => savedMap(_section('days')[today]);
  int get todayQuestions => _items(todayRecord['questions']).length;
  int get todayActivities => _items(todayRecord['activities']).length;

  static int _count(Object? value) => value is int && value >= 0 ? value : 0;
  static Set<String> _items(Object? value) =>
      value is List ? value.whereType<String>().toSet() : {};

  void setSetting(String name, Object value) {
    _section('settings')[name] = value;
    _changed();
  }

  void selectCategory(String name) {
    _data['category'] = name;
    _changed();
  }

  void saveSession(String id, Map<String, dynamic> value) {
    _section('sessions')[id] = value;
    _data['lastActivity'] = id;
    _data['lastDestination'] = 'kids';
    _changed();
  }

  void savePractice(Map<String, dynamic> value) {
    _data['practice'] = value;
    _data['lastDestination'] = 'practice';
    _changed();
  }

  void saveBoard(
    String slot,
    Map<String, dynamic> value, {
    bool active = true,
  }) {
    if (contentSignature(board(slot)) == contentSignature(value)) return;
    _section('boards')[slot] = value;
    if (active) {
      _data['lastDestination'] = slot == 'classic' ? 'classic' : 'daily';
      if (slot.startsWith('daily:')) _data['lastDailyDate'] = slot.substring(6);
    }
    _changed();
  }

  void chooseDaily(String day, Map<String, dynamic> choice) {
    _section('daily')[day] = choice;
    _changed();
  }

  void recordAnswer(String questionVersion, bool correct) {
    final answers = _section('answers');
    final answer = savedMap(answers[questionVersion]);
    answer['firstCorrect'] ??= correct;
    answer['attempts'] = _count(answer['attempts']) + 1;
    answer['correct'] = answer['correct'] == true || correct;
    answers[questionVersion] = answer;
    if (correct) _recordDay('questions', questionVersion);
    _updateAchievements();
    _changed();
  }

  bool completeActivity(String id) {
    _section('activities')[id] = today;
    _recordDay('activities', id);
    final fresh = _reward('activity:$id');
    _updateAchievements();
    _changed();
    return fresh;
  }

  bool completePuzzle(String id, {String? dailyDate}) {
    _section('puzzles')[id] = today;
    _recordDay('puzzles', id);
    // Completing a saved past date never qualifies a different future date.
    final fresh = _reward(
      dailyDate == null ? 'classic:$id' : 'daily:$dailyDate',
    );
    _updateAchievements();
    _changed();
    return fresh;
  }

  bool _reward(String id) {
    if (_blocked) return false;
    final rewards = _section('rewards');
    if (rewards.containsKey(id)) return false;
    rewards[id] = today;
    return true;
  }

  void _recordDay(String kind, String id) {
    final days = _section('days');
    final record = savedMap(days[today]);
    record[kind] = (_items(record[kind])..add(id)).toList()..sort();
    days[today] = record;
  }

  List<int> get _qualifyingDays {
    final result = <int>[];
    for (final entry in _section('days').entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null ||
          calendarDay(date) != entry.key ||
          entry.key.compareTo(today) > 0) {
        continue;
      }
      final record = savedMap(entry.value);
      if ([
        'questions',
        'activities',
        'puzzles',
      ].any((key) => _items(record[key]).isNotEmpty)) {
        result.add(
          DateTime.utc(
                date.year,
                date.month,
                date.day,
              ).millisecondsSinceEpoch ~/
              Duration.millisecondsPerDay,
        );
      }
    }
    return result..sort();
  }

  int get bestStreak {
    final days = _qualifyingDays;
    var best = 0;
    var run = 0;
    int? previous;
    for (final day in days) {
      run = previous == day - 1 ? run + 1 : 1;
      if (run > best) best = run;
      previous = day;
    }
    return best;
  }

  int get currentStreak {
    final now = clock();
    var day =
        DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final days = _qualifyingDays.toSet();
    if (!days.contains(day)) day--;
    var result = 0;
    while (days.contains(day--)) {
      result++;
    }
    return result;
  }

  void _updateAchievements() {
    final earned = _section('achievements');
    if (completedActivities.isNotEmpty) {
      earned.putIfAbsent('first-activity', () => today);
    }
    if (completedPuzzles.isNotEmpty) {
      earned.putIfAbsent('first-puzzle', () => today);
    }
    if (firstAttemptCorrect >= 10) {
      earned.putIfAbsent('ten-first-answers', () => today);
    }
    if (bestStreak >= 3) earned.putIfAbsent('three-learning-days', () => today);
  }

  void resetProgress() {
    _data = {'version': 1, 'settings': settings};
    _blocked = false;
    recoveryNotice = null;
    storageError = null;
    resetRevision++;
    _changed();
  }

  void _changed() {
    if (_disposed) return;
    _dirty = true;
    _debounce?.cancel();
    if (autoSave) _debounce = Timer(const Duration(milliseconds: 250), flush);
    notifyListeners();
  }

  Future<void> flush() {
    _debounce?.cancel();
    if (_blocked || !_dirty) return _writes;
    final snapshot = jsonEncode(_data);
    _dirty = false;
    _writes = _writes.then((_) async {
      try {
        await store.write(snapshot);
        storageError = null;
      } on Exception catch (error) {
        _dirty = true;
        storageError = 'Changes are not saved yet. Retry saving in Settings.';
        debugPrint('Learning storage write failed: ${error.runtimeType}');
      }
      if (!_disposed) notifyListeners();
    });
    return _writes;
  }

  @override
  void dispose() {
    unawaited(flush());
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
