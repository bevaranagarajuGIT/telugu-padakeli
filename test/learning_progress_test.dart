import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/core/kids_learning_controller.dart';
import 'package:telugu_padakeli/core/learning_progress.dart';
import 'package:telugu_padakeli/models/kids_learning.dart';
import 'package:telugu_padakeli/models/puzzle.dart';
import 'package:telugu_padakeli/services/daily_puzzle_service.dart';
import 'package:telugu_padakeli/services/kids_learning_service.dart';
import 'package:telugu_padakeli/services/learning_store.dart';
import 'package:telugu_padakeli/services/onboarding_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DelayedStore extends MemoryLearningStore {
  final first = Completer<void>();
  int calls = 0;
  @override
  Future<void> write(String value) async {
    calls++;
    if (calls == 1) await first.future;
    await super.write(value);
  }
}

class _FailingStore extends MemoryLearningStore {
  bool fail = true;
  @override
  Future<void> write(String value) async {
    if (fail) throw const LearningStorageException('Test disk unavailable');
    await super.write(value);
  }
}

LearningProgress _progress(LearningStore store, {DateTime Function()? clock}) =>
    LearningProgress(store, clock: clock, autoSave: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final activities = const KidsLearningService().getActivities();
  final pictures = activities.first;

  test(
    'real preferences round-trip settings without touching onboarding',
    () async {
      SharedPreferences.setMockInitialValues({
        PreferencesOnboardingStore.completionKey: true,
      });
      final saved = _progress(PreferencesLearningStore());
      await saved.load();
      final settings = AppSettingsController(progress: saved)
        ..setFontSize(TeluguFontSize.extraLarge)
        ..setDarkMode(true)
        ..setEnglishHelper(true)
        ..setSoundEnabled(true);
      saved.setSetting('dailyGoal', 5);
      await saved.flush();
      final reopened = _progress(PreferencesLearningStore());
      await reopened.load();
      final restored = AppSettingsController(progress: reopened);
      expect(restored.fontSize, TeluguFontSize.extraLarge);
      expect(
        restored.darkMode && restored.englishHelper && restored.soundEnabled,
        isTrue,
      );
      expect(reopened.dailyGoal, 5);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          PreferencesOnboardingStore.completionKey,
        ),
        isTrue,
      );
      settings.dispose();
      restored.dispose();
      saved.dispose();
      reopened.dispose();
    },
  );

  test(
    'corrupt save preserved; unsupported schema cannot be overwritten',
    () async {
      for (final raw in [
        'not json',
        '{"version":1,"sessions":[]}',
        '{"version":1,"settings":null}',
      ]) {
        final store = MemoryLearningStore()..value = raw;
        final saved = _progress(store);
        await saved.load();
        expect(saved.recoveryNotice, isNotNull);
        expect(store.recovery, raw);
        saved.recordAnswer('question', true);
        await saved.flush();
        expect(jsonDecode(store.value!)['version'], 1);
        saved.dispose();
      }
      final store = MemoryLearningStore()
        ..value = '{"version":99,"future":"kept"}';
      final saved = _progress(store);
      await saved.load();
      saved.recordAnswer('question', true);
      await saved.flush();
      expect(store.value, '{"version":99,"future":"kept"}');
      saved.resetProgress();
      await saved.flush();
      expect(jsonDecode(store.value!)['version'], 1);
      saved.dispose();
    },
  );

  test('serialized writes cannot let the older snapshot win', () async {
    final store = _DelayedStore();
    final saved = _progress(store);
    saved.setSetting('dailyGoal', 2);
    final first = saved.flush();
    await Future<void>.delayed(Duration.zero);
    saved.setSetting('dailyGoal', 4);
    final second = saved.flush();
    expect(store.calls, 1);
    store.first.complete();
    await Future.wait([first, second]);
    expect(jsonDecode(store.value!)['settings']['dailyGoal'], 4);
    saved.dispose();
  });

  test('failed save is explicit and retry writes latest progress', () async {
    final store = _FailingStore();
    final saved = _progress(store);
    saved.recordAnswer('one', true);
    await saved.flush();
    expect(saved.storageError, isNotNull);
    store.fail = false;
    saved.recordAnswer('two', false);
    await saved.flush();
    expect(saved.storageError, isNull);
    final restored = _progress(store);
    await restored.load();
    expect(restored.checkedQuestions, 2);
    saved.dispose();
    restored.dispose();
  });

  test(
    'Kids restores selected attempt and correct state without new rewards',
    () async {
      final store = MemoryLearningStore();
      final saved = _progress(store);
      final learning = KidsLearningController(storage: saved);
      final session = learning.sessionFor(pictures);
      final wrong = session.question.choices.firstWhere(
        (item) => item.telugu != session.question.answer,
      );
      session.selectChoice(wrong.telugu);
      session.check();
      await saved.flush();
      final reopened = _progress(store);
      await reopened.load();
      final other = KidsLearningController(storage: reopened);
      final attempt = other.sessionFor(pictures);
      expect(attempt.choice, wrong.telugu);
      expect(attempt.answerState, KidsAnswerState.incorrect);
      attempt.selectChoice(attempt.question.answer);
      attempt.check();
      await reopened.flush();
      final third = _progress(store);
      await third.load();
      final finalLearning = KidsLearningController(storage: third);
      final restored = finalLearning.sessionFor(pictures);
      expect(restored.answerState, KidsAnswerState.correct);
      expect(restored.score, 1);
      expect(restored.earnedStarOnCompletion, isFalse);
      expect(third.firstAttemptCorrect, 0);
      expect(third.attempts, 2);
      expect(third.todayQuestions, 1);
      learning.dispose();
      other.dispose();
      finalLearning.dispose();
      saved.dispose();
      reopened.dispose();
      third.dispose();
    },
  );

  test(
    'completion, stars and achievements stay duplicate-safe after reopening and replay',
    () async {
      final store = MemoryLearningStore();
      var saved = _progress(store);
      for (var round = 0; round < 2; round++) {
        final learning = KidsLearningController(storage: saved);
        final session = learning.sessionFor(pictures);
        session.restart();
        for (final question in pictures.questions) {
          session.selectChoice(question.answer);
          session.check();
          session.next();
        }
        expect(session.complete, isTrue);
        expect(session.earnedStarOnCompletion, round == 0);
        expect(saved.stars, 1);
        expect(saved.completedActivities, {'pictures'});
        expect(saved.achievements, contains('first-activity'));
        expect(saved.checkedQuestions, pictures.questions.length);
        await saved.flush();
        learning.dispose();
        saved.dispose();
        saved = _progress(store);
        await saved.load();
      }
      final learning = KidsLearningController(storage: saved);
      final restored = learning.sessionFor(pictures);
      expect(restored.complete, isTrue);
      expect(restored.earnedStarOnCompletion, isFalse);
      expect(saved.stars, 1);
      learning.dispose();
      saved.dispose();
    },
  );

  test(
    'changed question invalidates only its answers and resumes first changed item',
    () async {
      final store = MemoryLearningStore();
      final saved = _progress(store);
      final learning = KidsLearningController(storage: saved);
      final session = learning.sessionFor(pictures);
      session.selectChoice(session.question.answer);
      session.check();
      session.next();
      session.selectChoice(session.question.answer);
      session.check();
      session.next();
      await saved.flush();
      final changed = KidsLearningActivity(
        id: pictures.id,
        type: pictures.type,
        categories: pictures.categories,
        title: pictures.title,
        englishTitle: pictures.englishTitle,
        questions: [
          KidsLearningQuestion(
            id: pictures.questions.first.id,
            prompt: 'Changed clue',
            englishPrompt: 'Changed clue',
            answer: pictures.questions.first.answer,
            explanation: 'Changed',
            englishExplanation: 'Changed',
            choices: pictures.questions.first.choices,
          ),
          ...pictures.questions.skip(1),
        ],
      );
      final reopened = _progress(store);
      await reopened.load();
      final second = KidsLearningController(storage: reopened);
      final restored = second.sessionFor(changed);
      expect(restored.index, 0);
      expect(restored.score, 1);
      expect(restored.answerState, KidsAnswerState.ready);
      restored.selectChoice(restored.question.answer);
      restored.check();
      restored.next();
      expect(restored.index, 1);
      expect(restored.answerState, KidsAnswerState.correct);
      learning.dispose();
      second.dispose();
      saved.dispose();
      reopened.dispose();
    },
  );

  test(
    'builder tile attempt, category and original practice survive reopening',
    () async {
      final store = MemoryLearningStore();
      final saved = _progress(store);
      final learning = KidsLearningController(storage: saved);
      final activity = activities.firstWhere(
        (item) => item.type == KidsActivityType.builder,
      );
      learning.selectCategory(LearningCategory.champions);
      learning.sessionFor(activity).selectTile(0);
      saved.savePractice({
        'level': 'Beginner',
        'question': 'కమ_',
        'choice': 'లం',
      });
      await saved.flush();
      final reopened = _progress(store);
      await reopened.load();
      final second = KidsLearningController(storage: reopened);
      expect(second.category, LearningCategory.champions);
      expect(second.sessionFor(activity).selectedTiles, [0]);
      expect(reopened.practice['choice'], 'లం');
      expect(reopened.lastDestination, 'practice');
      learning.dispose();
      second.dispose();
      saved.dispose();
      reopened.dispose();
    },
  );

  test(
    'calendar days use UTC ordinal arithmetic, tolerate gaps and backward clocks',
    () {
      var now = DateTime(2026, 3, 7, 23, 59);
      final saved = _progress(MemoryLearningStore(), clock: () => now);
      saved.recordAnswer('one', true);
      saved.recordAnswer('one', true);
      expect(saved.todayQuestions, 1);
      expect(saved.currentStreak, 1);
      now = DateTime(2026, 3, 8, 0, 1);
      expect(saved.currentStreak, 1);
      saved.recordAnswer('two', true);
      now = DateTime(2026, 3, 9);
      saved.recordAnswer('three', true);
      expect(saved.currentStreak, 3);
      expect(saved.bestStreak, 3);
      expect(saved.achievements, contains('three-learning-days'));
      now = DateTime(2026, 3, 12);
      expect(saved.currentStreak, 0);
      expect(saved.bestStreak, 3);
      now = DateTime(2026, 3, 7);
      expect(saved.currentStreak, 1);
      expect(saved.bestStreak, 1);
      saved.recordAnswer('one', false);
      expect(saved.firstAttemptCorrect, 3);
      now = DateTime(2026, 3, 9);
      expect(saved.bestStreak, 3);
      saved.dispose();
    },
  );

  test(
    'daily puzzle is stable across reordering, reopening, rollover and pool changes',
    () async {
      final puzzles = (jsonDecode(await _puzzleJson()) as List)
          .map(
            (item) => Puzzle.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      final store = MemoryLearningStore();
      final saved = _progress(store);
      const daily = DailyPuzzleService();
      final selected = daily.choose(puzzles, '2026-11-10', saved);
      saved.saveBoard('daily:2026-11-10', {
        'id': selected.id,
        'cells': ['ఆ'],
      });
      expect(
        saved.completePuzzle('${selected.id}', dailyDate: '2026-11-10'),
        isTrue,
      );
      expect(
        saved.completePuzzle('${selected.id}', dailyDate: '2026-11-10'),
        isFalse,
      );
      await saved.flush();
      final restored = _progress(store);
      await restored.load();
      expect(
        daily.choose(puzzles.reversed.toList(), '2026-11-10', restored).id,
        selected.id,
      );
      expect(restored.board('daily:2026-11-10')['cells'], ['ఆ']);
      expect(restored.stars, 1);
      daily.choose(puzzles, '2026-11-11', restored);
      expect(restored.daily('2026-11-10')['id'], selected.id);
      expect(restored.daily('2026-11-11').isNotEmpty, isTrue);
      expect(
        restored.completePuzzle('${selected.id}', dailyDate: '2026-11-11'),
        isTrue,
      );
      expect(restored.stars, 2);
      expect(
        () => daily.choose(
          puzzles.where((p) => p.id != selected.id).toList(),
          '2026-11-10',
          restored,
        ),
        throwsFormatException,
      );
      expect(
        () => daily.choose([], '2026-11-11', restored),
        throwsFormatException,
      );
      expect(
        () => daily.choose(puzzles, '2026-02-31', restored),
        throwsFormatException,
      );
      saved.dispose();
      restored.dispose();
    },
  );

  test(
    'confirmed reset preserves preferences but clears attempts, boards and rewards',
    () {
      final saved = _progress(MemoryLearningStore());
      saved.setSetting('darkMode', true);
      saved.recordAnswer('q', false);
      saved.completeActivity('pictures');
      saved.completePuzzle('1', dailyDate: '2026-11-10');
      saved.saveBoard('classic', {'id': 1});
      saved.resetProgress();
      expect(saved.settings['darkMode'], isTrue);
      expect(saved.stars, 0);
      expect(saved.checkedQuestions, 0);
      expect(saved.hasClassic, isFalse);
      expect(saved.lastDestination, isNull);
      expect(saved.resetRevision, 1);
      saved.dispose();
    },
  );
}

Future<String> _puzzleJson() async {
  final data = await rootBundle.loadString('assets/data/sample_puzzles.json');
  final decoded = jsonDecode(data);
  return jsonEncode(decoded is Map ? decoded['puzzles'] : decoded);
}
