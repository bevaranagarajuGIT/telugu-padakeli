import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/core/kids_learning_controller.dart';
import 'package:telugu_padakeli/core/learning_progress.dart';
import 'package:telugu_padakeli/models/kids_learning.dart';
import 'package:telugu_padakeli/models/telugu_akshara.dart';
import 'package:telugu_padakeli/services/kids_learning_service.dart';
import 'package:telugu_padakeli/services/kids_question_service.dart';
import 'package:telugu_padakeli/services/kids_answer_order.dart';
import 'package:telugu_padakeli/services/learning_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final activities = const KidsLearningService().getActivities();

  test(
    'choice presentation balances correct positions without mutating content',
    () {
      for (final count in [3, 4]) {
        final source = List.generate(count, (index) => '$index');
        for (var seed = 0; seed < 100; seed++) {
          final positions = <int>[];
          for (var index = 0; index < count * 2; index++) {
            final order = orderedKidsChoices(
              source,
              isAnswer: (choice) => choice == '0',
              seed: seed,
              questionIndex: index,
            );
            expect(order.toSet(), source.toSet());
            positions.add(order.indexOf('0'));
            expect(
              orderedKidsChoices(
                source,
                isAnswer: (choice) => choice == '0',
                seed: seed,
                questionIndex: index,
              ),
              order,
            );
          }
          expect(positions.take(count).toSet().length, count);
          expect(positions.skip(count).toSet().length, count);
        }
        expect(source, List.generate(count, (index) => '$index'));
      }
    },
  );

  test(
    'choice order survives retry and session restoration with old saves supported',
    () {
      final activity = activities.firstWhere(
        (item) => item.id == 'completion-0',
      );
      final session = KidsActivitySession(activity, () {});
      addTearDown(session.dispose);
      final order = session.choices;
      expect(order.toSet(), session.question.choices.toSet());
      session.selectChoice(
        session.choices
            .firstWhere((choice) => choice.telugu != session.question.answer)
            .telugu,
      );
      expect(session.check(), false);
      expect(session.choices, order);
      session.selectChoice(session.question.answer);
      session.check();
      session.next();
      final saved = session.snapshot();
      final nextOrder = session.choices;
      final storage = LearningProgress(MemoryLearningStore(), autoSave: false);
      addTearDown(storage.dispose);
      storage.saveSession(activity.id, saved);
      final restored = KidsActivitySession(activity, () {}, storage: storage);
      addTearDown(restored.dispose);
      expect(restored.choices, nextOrder);
      expect(restored.score, 1);
      expect(restored.index, 1);
      for (final seed in [null, -1, 'invalid']) {
        storage.saveSession(activity.id, {...saved, 'answerOrderSeed': seed});
        final older = KidsActivitySession(activity, () {}, storage: storage);
        addTearDown(older.dispose);
        expect(older.index, 1);
        expect(older.score, 1);
        expect(older.choices.toSet(), older.question.choices.toSet());
      }
      restored.restart();
      expect(restored.score, 0);
      expect(restored.choices.toSet(), restored.question.choices.toSet());
    },
  );

  test(
    'English Helper defaults off and notifies immediately without duplicates',
    () {
      final settings = AppSettingsController();
      addTearDown(settings.dispose);
      var notifications = 0;
      settings.addListener(() => notifications++);
      expect(settings.englishHelper, isFalse);
      settings.setEnglishHelper(true);
      settings.setEnglishHelper(true);
      expect(settings.englishHelper, isTrue);
      expect(notifications, 1);
      settings.setEnglishHelper(false);
      expect(notifications, 2);
      expect(AppSettingsController().englishHelper, isFalse);
    },
  );

  test('three freely selectable categories have playable content', () {
    final learning = KidsLearningController();
    addTearDown(learning.dispose);
    expect(learning.category, LearningCategory.early);
    for (final category in LearningCategory.values) {
      learning.selectCategory(category);
      expect(learning.category, category);
      expect(
        activities.any((activity) => activity.categories.contains(category)),
        isTrue,
      );
    }
  });

  test(
    'all five activity types and 74 reviewed-pending questions validate',
    () {
      expect(
        activities.map((a) => a.type).toSet(),
        KidsActivityType.values.toSet(),
      );
      expect(activities, hasLength(12));
      expect(activities.expand((a) => a.questions).length, 74);
      expect(() => KidsLearningService.validate(activities), returnsNormally);
      for (final question in activities.expand((a) => a.questions)) {
        expect(question.reviewStatus, 'pending-human-review');
        expect(question.audioAsset, isNull);
        expect(question.englishPrompt, isNotEmpty);
        expect(question.englishExplanation, isNotEmpty);
      }
    },
  );

  test('completion questions reuse original prompts, answers and hints', () {
    final old = const KidsQuestionService().getLevels();
    for (final level in [0, 1, 2, 5]) {
      final activity = activities.firstWhere(
        (a) => a.id == 'completion-$level',
      );
      for (var i = 0; i < old[level].questions.length; i++) {
        expect(activity.questions[i].display, old[level].questions[i].prompt);
        expect(activity.questions[i].answer, old[level].questions[i].answer);
        expect(activity.questions[i].explanation, old[level].questions[i].hint);
        expect(
          activity.questions[i].englishExplanation,
          old[level].questions[i].englishHint,
        );
        expect(activity.questions[i].difficulty, old[level].difficulty);
      }
    }
  });

  test('age paths grow gradually without lengthening preschool rounds', () {
    for (final (category, sizes) in [
      (LearningCategory.early, [5, 5, 5, 5]),
      (LearningCategory.explorers, [5, 5, 5, 5, 7]),
      (LearningCategory.champions, [5, 5, 7, 7, 10, 10]),
    ]) {
      expect(
        activities
            .where((a) => a.categories.contains(category))
            .map((a) => a.questions.length),
        sizes,
      );
    }
  });

  test(
    'every expanded round completes once; replay and category changes cannot duplicate rewards',
    () {
      final learning = KidsLearningController();
      addTearDown(learning.dispose);
      for (final (index, activity) in activities.indexed) {
        final session = learning.sessionFor(activity);
        for (var replay = 0; replay < 2; replay++) {
          expect(session.complete, isFalse);
          session.next();
          expect(session.index, 0);
          for (final question in activity.questions) {
            expect(learning.stars, index + (replay == 0 ? 0 : 1));
            if (activity.type == KidsActivityType.builder) {
              final used = <int>{};
              for (final cell in TeluguAkshara.split(question.answer)) {
                final available = List.generate(question.tiles.length, (i) => i)
                    .firstWhere(
                      (i) =>
                          !used.contains(i) &&
                          TeluguAkshara.equivalent(question.tiles[i], cell),
                    );
                used.add(available);
                session.selectTile(available);
              }
            } else {
              session.selectChoice(question.answer);
            }
            expect(session.check(), isTrue);
            session.check();
            session.next();
          }
          expect(session.complete, isTrue);
          expect(session.score, activity.questions.length);
          expect(learning.stars, index + 1);
          for (final category in LearningCategory.values) {
            learning.selectCategory(category);
            expect(learning.sessionFor(activity), same(session));
            expect(learning.stars, index + 1);
          }
          session.restart();
        }
      }
    },
  );

  test('duplicate activities are rejected', () {
    expect(
      () => KidsLearningService.validate([activities.first, activities.first]),
      throwsFormatException,
    );
  });

  test('choice validation rejects empty, ambiguous and non-Telugu choices', () {
    for (final choices in [
      [
        const KidsChoice('మామిడి'),
        const KidsChoice('మామిడి'),
        const KidsChoice('జామ'),
      ],
      [
        const KidsChoice('మామిడి'),
        const KidsChoice(''),
        const KidsChoice('జామ'),
      ],
      [
        const KidsChoice('మామిడి'),
        const KidsChoice('apple'),
        const KidsChoice('జామ'),
      ],
    ]) {
      final question = KidsLearningQuestion(
        id: 'invalid',
        prompt: 'ఇది ఏమిటి?',
        englishPrompt: 'What is this?',
        answer: 'మామిడి',
        explanation: 'పండు',
        englishExplanation: 'Fruit',
        choices: choices,
      );
      expect(
        () => question.validate(KidsActivityType.meaning),
        throwsFormatException,
      );
    }
  });

  test('builder rejects mismatched tiles and incomplete answers', () {
    const question = KidsLearningQuestion(
      id: 'invalid-builder',
      prompt: 'పదం',
      englishPrompt: 'Word',
      answer: 'అమ్మ',
      tiles: ['అ', 'మ', 'మ'],
      explanation: 'అమ్మ',
      englishExplanation: 'Mother',
    );
    expect(
      () => question.validate(KidsActivityType.builder),
      throwsFormatException,
    );
  });

  test('broken completion boundaries cannot hide behind joined equality', () {
    const question = KidsLearningQuestion(
      id: 'broken',
      prompt: 'పదం',
      englishPrompt: 'Word',
      display: 'అమ్_',
      answer: 'మ',
      completedWord: 'అమ్మ',
      explanation: 'అమ్మ',
      englishExplanation: 'Mother',
      choices: [KidsChoice('మ'), KidsChoice('క'), KidsChoice('ల')],
    );
    expect(
      () => question.validate(KidsActivityType.completion),
      throwsFormatException,
    );
  });

  test('wrong answers retry, correct scoring locks until explicit Next', () {
    final session = KidsActivitySession(activities.first, () {});
    addTearDown(session.dispose);
    session.selectChoice('జామ');
    expect(session.check(), isFalse);
    expect(session.score, 0);
    session.next();
    expect(session.index, 0);
    session.selectChoice('మామిడి');
    expect(session.check(), isTrue);
    session.check();
    session.selectChoice('జామ');
    expect(session.score, 1);
    expect(session.choice, 'మామిడి');
    expect(session.index, 0);
    session.next();
    expect(session.index, 1);
    expect(session.choice, isNull);
  });

  test('builder rejects partial and wrong order; tiles have identity', () {
    final activity = activities.firstWhere(
      (a) => a.type == KidsActivityType.builder,
    );
    final session = KidsActivitySession(activity, () {});
    addTearDown(session.dispose);
    session.selectTile(2);
    session.selectTile(2);
    expect(session.selectedTiles, [2]);
    expect(session.check(), isFalse);
    session.selectTile(1);
    session.selectTile(0);
    expect(session.check(), isFalse);
    session.undoTile();
    expect(session.selectedTiles, [2, 1]);
    session.removeTile(1);
    session.selectTile(0);
    session.selectTile(1);
    expect(session.check(), isTrue);
    expect(session.score, 1);
  });

  test('repeated aksharas use both distinct tile instances exactly once', () {
    final source = activities.firstWhere((a) => a.id == 'builder');
    final repeated = source.questions.last;
    final activity = KidsLearningActivity(
      id: 'repeated',
      type: KidsActivityType.builder,
      categories: source.categories,
      title: source.title,
      englishTitle: source.englishTitle,
      questions: [repeated],
    );
    activity.validate();
    final session = KidsActivitySession(activity, () {});
    addTearDown(session.dispose);
    for (final i in [1, 0, 3, 2]) {
      session.selectTile(i);
    }
    expect(session.selectedTiles.toSet().length, 4);
    expect(session.check(), isTrue);
  });

  test('shared parser keeps conjunct and guninthalu tiles intact', () {
    expect(TeluguAkshara.split('అమ్మ'), ['అ', 'మ్మ']);
    final source = activities.firstWhere((a) => a.id == 'builder');
    expect(source.questions[1].tiles, ['మ్మ', 'అ']);
    expect(source.questions.first.tiles, ['మి', 'డి', 'మా']);
  });

  test(
    'completion, restart and replay award one star per activity per session',
    () {
      final learning = KidsLearningController();
      addTearDown(learning.dispose);
      final activity = activities.first;
      final session = learning.sessionFor(activity);
      expect(learning.sessionFor(activity), same(session));
      for (var replay = 0; replay < 2; replay++) {
        for (final question in activity.questions) {
          session.selectChoice(question.answer);
          session.check();
          session.check();
          session.next();
        }
        expect(session.complete, isTrue);
        expect(session.score, activity.questions.length);
        expect(learning.stars, 1);
        expect(session.earnedStarOnCompletion, replay == 0);
        session.next();
        expect(learning.stars, 1);
        session.restart();
        expect(session.earnedStarOnCompletion, isFalse);
        expect(session.index, 0);
        expect(session.score, 0);
        expect(session.complete, isFalse);
        expect(session.answerState, KidsAnswerState.ready);
      }
      expect(KidsLearningController().stars, 0);
    },
  );

  test('clear attempt and restart do not earn rewards', () {
    final learning = KidsLearningController();
    addTearDown(learning.dispose);
    final session = learning.sessionFor(
      activities.firstWhere((a) => a.id == 'builder'),
    );
    session.selectTile(0);
    session.clearAttempt();
    expect(session.selectedTiles, isEmpty);
    session.restart();
    expect(learning.stars, 0);
  });

  test(
    'all educational pictures load offline and have image descriptions',
    () async {
      for (final question in activities.expand((a) => a.questions)) {
        if (question.imageAsset != null) {
          final data = await rootBundle.load(question.imageAsset!);
          expect(data.lengthInBytes, greaterThan(0));
          expect(question.imageDescription, isNotEmpty);
        }
      }
    },
  );
}
