import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:telugu_padakeli/app/navigation/app_shell.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/core/learning_progress.dart';
import 'package:telugu_padakeli/models/riddle.dart';
import 'package:telugu_padakeli/screens/riddles_screen.dart';
import 'package:telugu_padakeli/services/learning_store.dart';
import 'package:telugu_padakeli/services/riddle_repository.dart';
import 'package:telugu_padakeli/widgets/premium_telugu_text.dart';

class _Repository implements RiddleRepository {
  _Repository(this.riddles, {this.fail = false});
  final List<Riddle> riddles;
  bool fail;

  @override
  Future<List<Riddle>> load() async {
    if (fail) throw const FormatException('Test content unavailable');
    return riddles;
  }
}

Future<void> _mount(
  WidgetTester tester,
  LearningProgress progress, {
  RiddleRepository? repository,
  bool shell = false,
  bool dark = false,
  double scale = 1,
  bool journey = false,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: progress,
      child: MaterialApp(
        theme: dark ? AppTheme.dark(1) : AppTheme.light(1),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: shell
            ? const AppShell()
            : RiddlesScreen(
                repository: repository ?? const LocalRiddleRepository(),
                resume: !journey,
              ),
      ),
    ),
  );
  await tester.runAsync(() => tester.pumpAndSettle());
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 50,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  final screen =
      Offset.zero & (tester.view.physicalSize / tester.view.devicePixelRatio);
  await tester.tapAt(tester.getRect(finder).intersect(screen).center);
  await tester.runAsync(() => tester.pumpAndSettle());
}

void main() {
  late List<Riddle> riddles;
  setUpAll(() async {
    riddles = await const LocalRiddleRepository().load();
    final fonts = FontLoader(PremiumTeluguText.fontFamily);
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/NotoSansTelugu-$weight.ttf'));
    }
    await fonts.load();
  });

  test('riddles reject missing answers and duplicate options', () {
    final source = riddles.first;
    Map<String, dynamic> json(List<String> choices) => {
      'id': source.id,
      'question': source.question,
      'answer': source.answer,
      'hint': source.hint,
      'explanation': source.explanation,
      'choices': choices,
    };
    expect(
      () => Riddle.fromJson(json(List.filled(4, source.answer))),
      throwsFormatException,
    );
    expect(
      () => Riddle.fromJson(json(['a', 'b', 'c', 'd'])),
      throwsFormatException,
    );
  });

  testWidgets(
    'journey locks later levels and persists explicit level advancement',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryLearningStore();
      final saved = LearningProgress(store, autoSave: false);
      addTearDown(saved.dispose);
      await _mount(tester, saved, journey: true);
      ButtonStyleButton levelButton(RiddleLevel level) =>
          tester.widget<ButtonStyleButton>(
            find.byKey(ValueKey('riddle-level-${level.name}')),
          );
      expect(levelButton(RiddleLevel.spark).onPressed, isNotNull);
      expect(levelButton(RiddleLevel.trail).onPressed, isNull);
      expect(levelButton(RiddleLevel.hero).onPressed, isNull);
      await _tap(tester, 'riddle-level-spark');
      final firstLevel = riddles
          .where((riddle) => riddle.level == RiddleLevel.spark)
          .toList();
      for (final riddle in firstLevel) {
        await _tap(tester, 'riddle-choice-${riddle.answer}');
        if (riddle != firstLevel.last) await _tap(tester, 'riddle-next');
      }
      expect(
        find.byKey(const ValueKey('riddle-level-complete')).hitTestable(),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('riddle-next')), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      expect(saved.riddles['current'], firstLevel.last.id);
      final advance = tester
          .widget<FilledButton>(find.byKey(const ValueKey('riddle-next-level')))
          .onPressed!;
      advance();
      advance();
      await tester.pumpAndSettle();
      final next = riddles.firstWhere(
        (riddle) => riddle.level == RiddleLevel.trail,
      );
      expect(saved.riddles['current'], next.id);
      await saved.flush();
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = LearningProgress(store, autoSave: false);
      addTearDown(restored.dispose);
      await restored.load();
      await _mount(tester, restored, journey: true);
      expect(levelButton(RiddleLevel.trail).onPressed, isNotNull);
      expect(levelButton(RiddleLevel.hero).onPressed, isNull);
      await _tap(tester, 'riddle-level-trail');
      expect(
        find.byKey(ValueKey('riddle-question-${next.id}')),
        findsOneWidget,
      );
      expect(restored.stars, 0);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'level metadata preserves legacy signatures and rejects unknown levels',
    () {
      final source = riddles.first;
      final json = <String, dynamic>{
        'id': source.id,
        'question': source.question,
        'answer': source.answer,
        'choices': source.choices,
        'hint': source.hint,
        'explanation': source.explanation,
      };
      final legacy = Riddle.fromJson(json);
      final moved = Riddle.fromJson({...json, 'level': 'hero'});
      expect(moved.level, RiddleLevel.hero);
      expect(moved.signature, legacy.signature);
      expect(
        () => Riddle.fromJson({...json, 'level': 'missing'}),
        throwsFormatException,
      );
    },
  );

  testWidgets(
    'legacy eight-riddle progress keeps completed levels and unlocks the first expansion',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final saved = LearningProgress(MemoryLearningStore(), autoSave: false);
      addTearDown(saved.dispose);
      final legacy = riddles
          .where((riddle) => riddle.level.index <= RiddleLevel.hero.index)
          .toList();
      saved.saveRiddles({
        'current': legacy.last.id,
        'answers': {
          for (final riddle in legacy)
            riddle.id: {
              'signature': riddle.signature,
              'solved': true,
              'hint': false,
              'tried': [riddle.answer],
            },
        },
      });
      final snapshot = contentSignature(savedMap(saved.riddles['answers']));
      await _mount(tester, saved, journey: true);
      for (final level in RiddleLevel.values) {
        expect(
          tester
                  .widget<OutlinedButton>(
                    find.byKey(ValueKey('riddle-level-${level.name}')),
                  )
                  .onPressed !=
              null,
          level.index <= RiddleLevel.nature.index,
        );
      }
      String legacyAnswers() => contentSignature({
        for (final riddle in legacy)
          riddle.id: savedMap(saved.riddles['answers'])[riddle.id],
      });
      expect(legacyAnswers(), snapshot);
      expect(saved.riddles['current'], legacy.last.id);
      for (final level in [
        RiddleLevel.spark,
        RiddleLevel.trail,
        RiddleLevel.hero,
      ]) {
        expect(
          tester
              .getSize(find.byKey(ValueKey('riddle-level-${level.name}')))
              .height,
          lessThanOrEqualTo(160),
        );
      }
      expect(
        find.text('8 / ${riddles.length} · సాధించిన పొడుపులు'),
        findsOneWidget,
      );
      await _tap(tester, 'riddle-level-hero');
      expect(
        find.byKey(const ValueKey('riddle-level-complete')),
        findsOneWidget,
      );
      await _tap(tester, 'riddle-next-level');
      expect(
        find.byKey(const ValueKey('riddle-question-draft-river')),
        findsOneWidget,
      );
      expect(legacyAnswers(), snapshot);
      expect(
        riddles
            .skip(legacy.length)
            .every(
              (riddle) =>
                  savedMap(
                    savedMap(saved.riddles['answers'])[riddle.id],
                  )['solved'] ==
                  false,
            ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'replay retries, hints, review and exits preserve completed progress',
    (tester) async {
      final store = MemoryLearningStore();
      final saved = LearningProgress(store, autoSave: false);
      addTearDown(saved.dispose);
      final group = riddles
          .where((riddle) => riddle.level == RiddleLevel.spark)
          .toList();
      saved.saveBoard('classic', {
        'id': 10,
        'cells': ['క'],
        'hints': 2,
      });
      saved.completePuzzle('existing');
      saved.saveRiddles({
        'current': group.last.id,
        'answers': {
          for (final riddle in group)
            riddle.id: {
              'signature': riddle.signature,
              'solved': true,
              'hint': true,
              'tried': riddle.choices,
            },
        },
      });
      await _mount(tester, saved);
      final snapshot = contentSignature(saved.riddles);
      final board = contentSignature(saved.board('classic'));
      final stars = saved.stars;
      final oldNextLevel = tester
          .widget<FilledButton>(find.byKey(const ValueKey('riddle-next-level')))
          .onPressed!;
      final replay = tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('riddle-play-again')),
          )
          .onPressed!;
      replay();
      replay();
      oldNextLevel();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('riddle-replay-status')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('riddle-level-complete')), findsNothing);
      expect(find.byKey(const ValueKey('riddle-next-level')), findsNothing);
      expect(find.byKey(const ValueKey('riddle-hint-text')), findsNothing);
      expect(
        find.byKey(ValueKey('riddle-question-${group.first.id}')),
        findsOneWidget,
      );
      final wrong = group.first.choices.firstWhere(
        (choice) => choice != group.first.answer,
      );
      await _tap(tester, 'riddle-choice-$wrong');
      await _tap(tester, 'riddle-hint');
      expect(find.byKey(const ValueKey('riddle-try-again')), findsOneWidget);
      expect(find.byKey(const ValueKey('riddle-hint-text')), findsOneWidget);
      expect(contentSignature(saved.riddles), snapshot);
      await _tap(tester, 'riddle-review-answers');
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('riddle-review-${group.last.id}')),
        200,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('riddle-review-${group.last.id}')),
        findsOneWidget,
      );
      await _tap(tester, 'riddle-review-done');
      await _tap(tester, 'riddle-levels-back');
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('riddle-level-trail')),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('riddle-level-hero')),
            )
            .onPressed,
        isNull,
      );
      await _tap(tester, 'riddle-level-spark');
      expect(
        find.byKey(const ValueKey('riddle-level-complete')),
        findsOneWidget,
      );
      expect(contentSignature(saved.riddles), snapshot);
      await _tap(tester, 'riddle-play-again');
      expect(find.byKey(const ValueKey('riddle-hint-text')), findsNothing);
      await _tap(tester, 'riddle-choice-${group.first.answer}');
      await _tap(tester, 'riddle-next');
      expect(contentSignature(saved.riddles), snapshot);
      await saved.flush();
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = LearningProgress(store, autoSave: false);
      addTearDown(restored.dispose);
      await restored.load();
      await _mount(tester, restored);
      expect(find.byKey(const ValueKey('riddle-replay-status')), findsNothing);
      expect(
        find.byKey(const ValueKey('riddle-level-complete')),
        findsOneWidget,
      );
      expect(contentSignature(restored.riddles), snapshot);
      expect(contentSignature(restored.board('classic')), board);
      expect(restored.stars, stars);
      await _tap(tester, 'riddle-play-again');
      for (final riddle in group) {
        await _tap(tester, 'riddle-choice-${riddle.answer}');
        if (riddle != group.last) await _tap(tester, 'riddle-next');
      }
      expect(
        find.byKey(const ValueKey('riddle-replay-complete')),
        findsOneWidget,
      );
      expect(contentSignature(restored.riddles), snapshot);
      await _tap(tester, 'riddle-next-level');
      expect(find.byKey(const ValueKey('riddle-replay-status')), findsNothing);
      expect(restored.riddles['current'], riddles[group.length].id);
      expect(
        savedMap(restored.riddles['answers']),
        savedMap(saved.riddles['answers']),
      );
      expect(restored.stars, stars);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'retry, hints and explicit Next survive restart without changing other games',
    (tester) async {
      final store = MemoryLearningStore();
      final saved = LearningProgress(store, autoSave: false);
      addTearDown(saved.dispose);
      saved.saveBoard('classic', {
        'id': 10,
        'cells': ['క'],
        'hints': 2,
      });
      saved.saveSession('kids-example', {'index': 2});
      saved.setSetting('dailyGoal', 4);
      saved.completePuzzle('existing');
      final board = contentSignature(saved.board('classic'));
      final sessions = contentSignature(saved.sessions);
      final settings = contentSignature(saved.settings);
      final stars = saved.stars;
      final first = riddles.first;
      await _mount(tester, saved);
      await _tap(tester, 'riddle-hint');
      await _tap(
        tester,
        'riddle-choice-${first.choices.firstWhere((choice) => choice != first.answer)}',
      );
      expect(find.byKey(const ValueKey('riddle-try-again')), findsOneWidget);
      expect(find.byKey(const ValueKey('riddle-next')), findsNothing);
      await saved.flush();
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = LearningProgress(store, autoSave: false);
      addTearDown(restored.dispose);
      await restored.load();
      await _mount(tester, restored);
      expect(find.byKey(const ValueKey('riddle-hint-text')), findsOneWidget);
      expect(find.byKey(const ValueKey('riddle-try-again')), findsOneWidget);
      await _tap(tester, 'riddle-choice-${first.answer}');
      expect(
        find.byKey(ValueKey('riddle-question-${first.id}')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('riddle-explanation')), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(
        find.byKey(ValueKey('riddle-question-${riddles[1].id}')),
        findsNothing,
      );
      final snapshot = contentSignature(restored.riddles);
      final review = tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('riddle-review-answers')),
          )
          .onPressed!;
      review();
      review();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('riddle-review')), findsOneWidget);
      expect(find.byKey(ValueKey('riddle-review-${first.id}')), findsOneWidget);
      expect(
        find.byKey(ValueKey('riddle-review-${riddles[1].id}')),
        findsNothing,
      );
      await _tap(tester, 'riddle-review-done');
      expect(contentSignature(restored.riddles), snapshot);
      await _tap(tester, 'riddle-review-answers');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(contentSignature(restored.riddles), snapshot);
      final next = tester
          .widget<FilledButton>(find.byKey(const ValueKey('riddle-next')))
          .onPressed!;
      next();
      next();
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('riddle-question-${riddles[1].id}')),
        findsOneWidget,
      );
      expect(contentSignature(restored.board('classic')), board);
      expect(contentSignature(restored.sessions), sessions);
      expect(contentSignature(restored.settings), settings);
      expect(restored.stars, stars);
      expect(restored.lastDestination, 'riddles');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'every draft has four choices with balanced correct positions and explicit completion',
    (tester) async {
      final saved = LearningProgress(MemoryLearningStore(), autoSave: false);
      addTearDown(saved.dispose);
      await _mount(tester, saved);
      final positions = <int, int>{};
      for (final riddle in riddles) {
        final options = tester
            .widgetList<OutlinedButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is OutlinedButton &&
                    widget.key.toString().contains('riddle-choice-'),
              ),
            )
            .toList();
        expect(options.length, 4);
        final correct = options.indexWhere(
          (button) => button.key == ValueKey('riddle-choice-${riddle.answer}'),
        );
        positions.update(correct, (count) => count + 1, ifAbsent: () => 1);
        await _tap(tester, 'riddle-choice-${riddle.answer}');
        expect(
          find.byKey(const ValueKey('riddle-explanation')),
          findsOneWidget,
        );
        if (riddle != riddles.last) {
          final next = riddles[riddles.indexOf(riddle) + 1];
          await _tap(
            tester,
            next.level == riddle.level ? 'riddle-next' : 'riddle-next-level',
          );
        }
      }
      expect(positions.keys.toSet(), {0, 1, 2, 3});
      expect(positions.values.toSet(), {riddles.length ~/ 4});
      expect(find.byKey(const ValueKey('riddles-complete')), findsOneWidget);
      expect(find.byKey(const ValueKey('riddle-next')), findsNothing);
      await saved.flush();
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = LearningProgress(saved.store, autoSave: false);
      addTearDown(restored.dispose);
      await restored.load();
      await _mount(tester, restored);
      expect(find.byKey(const ValueKey('riddles-complete')), findsOneWidget);
      expect(restored.stars, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final (size, scale, dark) in [
    (const Size(320, 568), 1.0, false),
    (const Size(320, 568), 3.2, true),
    (const Size(900, 600), 1.0, false),
  ]) {
    testWidgets(
      'riddle actions and review remain reachable $size scale=$scale dark=$dark',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final saved = LearningProgress(MemoryLearningStore(), autoSave: false);
        addTearDown(saved.dispose);
        await _mount(tester, saved, dark: dark, scale: scale);
        await _tap(tester, 'riddle-hint');
        expect(find.byKey(const ValueKey('riddle-hint-text')), findsOneWidget);
        final answer = find.byKey(
          ValueKey('riddle-choice-${riddles.first.answer}'),
        );
        await tester.ensureVisible(answer);
        await tester.pumpAndSettle();
        expect(tester.getSize(answer).height, greaterThanOrEqualTo(48));
        await _tap(tester, 'riddle-choice-${riddles.first.answer}');
        await _tap(tester, 'riddle-review-answers');
        await _tap(tester, 'riddle-review-done');
        await _tap(tester, 'riddle-next');
        await _tap(tester, 'riddle-levels-back');
        expect(find.byKey(const ValueKey('riddle-journey')), findsOneWidget);
        await _tap(tester, 'riddle-level-spark');
        expect(
          find.byKey(ValueKey('riddle-question-${riddles[1].id}')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scale in [1.0, 3.2]) {
    testWidgets(
      'completed riddles promote review and keep Done visible scale=$scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final saved = LearningProgress(MemoryLearningStore(), autoSave: false);
        addTearDown(saved.dispose);
        saved.saveRiddles({
          'current': riddles.last.id,
          'answers': {
            for (final riddle in riddles)
              riddle.id: {'signature': riddle.signature, 'solved': true},
          },
        });
        await _mount(
          tester,
          saved,
          repository: _Repository(riddles),
          scale: scale,
          dark: scale > 1,
        );
        final snapshot = contentSignature(saved.riddles);
        if (scale == 1) {
          expect(
            find.byKey(const ValueKey('riddle-review-answers')).hitTestable(),
            findsOneWidget,
          );
        }
        await _tap(tester, 'riddle-review-answers');
        final done = find.byKey(const ValueKey('riddle-review-done'));
        expect(done.hitTestable(), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('riddle-review-${riddles.last.id}')),
          400,
          maxScrolls: riddles.length * 10,
        );
        await tester.pumpAndSettle();
        expect(done.hitTestable(), findsOneWidget);
        await _tap(tester, 'riddle-review-done');
        expect(contentSignature(saved.riddles), snapshot);
        expect(find.byKey(const ValueKey('riddles-complete')), findsOneWidget);
        final replayButton = find.byKey(const ValueKey('riddle-play-again'));
        await _tap(tester, 'riddle-play-again');
        expect(
          find.byKey(const ValueKey('riddle-replay-status')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('riddles-complete')), findsNothing);
        final group = riddles
            .where((riddle) => riddle.level == riddles.last.level)
            .toList();
        for (final riddle in group) {
          await _tap(tester, 'riddle-choice-${riddle.answer}');
          if (riddle != group.last) await _tap(tester, 'riddle-next');
        }
        expect(
          find.byKey(const ValueKey('riddle-replay-complete')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('riddle-next-level')), findsNothing);
        await tester.ensureVisible(replayButton);
        await tester.pumpAndSettle();
        expect(tester.getSize(replayButton).height, greaterThanOrEqualTo(48));
        await _tap(tester, 'riddle-play-again');
        expect(
          find.byKey(const ValueKey('riddle-replay-complete')),
          findsNothing,
        );
        expect(
          tester
              .widget<OutlinedButton>(
                find.byKey(ValueKey('riddle-choice-${group.first.answer}')),
              )
              .onPressed,
          isNotNull,
        );
        expect(contentSignature(saved.riddles), snapshot);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('edited draft invalidates only its own solved answer', (
    tester,
  ) async {
    final saved = LearningProgress(MemoryLearningStore(), autoSave: false);
    addTearDown(saved.dispose);
    saved.saveRiddles({
      'current': riddles.last.id,
      'answers': {
        for (final riddle in riddles)
          riddle.id: {'signature': riddle.signature, 'solved': true},
      },
    });
    final first = riddles.first;
    final edited = Riddle(
      id: first.id,
      question: '${first.question} కొత్త ముసాయిదా.',
      answer: first.answer,
      choices: first.choices,
      hint: first.hint,
      explanation: first.explanation,
    );
    await _mount(
      tester,
      saved,
      repository: _Repository([edited, ...riddles.skip(1)]),
    );
    final answers = savedMap(saved.riddles['answers']);
    expect(savedMap(answers[first.id])['solved'], false);
    expect(savedMap(answers[riddles[1].id])['solved'], true);
    expect(find.byKey(ValueKey('riddle-question-${first.id}')), findsOneWidget);
    await _tap(tester, 'riddle-levels-back');
    for (final level in RiddleLevel.values.skip(1)) {
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(ValueKey('riddle-level-${level.name}')),
            )
            .onPressed,
        isNull,
      );
    }
    expect(
      riddles
          .skip(1)
          .every((riddle) => savedMap(answers[riddle.id])['solved'] == true),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'load failure is visible and retry recovers without replacing saves',
    (tester) async {
      final saved = LearningProgress(MemoryLearningStore(), autoSave: false);
      addTearDown(saved.dispose);
      saved.saveRiddles({'current': 'keep-me'});
      final repository = _Repository(riddles, fail: true);
      await _mount(tester, saved, repository: repository);
      expect(tester.takeException(), isA<FormatException>());
      expect(saved.riddles['current'], 'keep-me');
      repository.fail = false;
      await _tap(tester, 'riddles-retry');
      expect(
        find.byKey(ValueKey('riddle-question-${riddles.first.id}')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home launches riddles and Resume returns to the saved riddle', (
    tester,
  ) async {
    final saved = LearningProgress(MemoryLearningStore(), autoSave: false);
    addTearDown(saved.dispose);
    await _mount(tester, saved, shell: true);
    await _tap(tester, 'home-riddles');
    expect(find.byKey(const ValueKey('riddle-journey')), findsOneWidget);
    expect(find.textContaining('Telugu review pending'), findsNothing);
    await _tap(tester, 'riddle-level-spark');
    expect(find.textContaining('Telugu review pending'), findsNothing);
    expect(find.byKey(const ValueKey('riddles-draft-notice')), findsNothing);
    await _tap(tester, 'riddle-choice-${riddles.first.answer}');
    await _tap(tester, 'riddle-next');
    await _tap(tester, 'riddle-levels-back');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tap(tester, 'home-resume');
    expect(
      find.byKey(ValueKey('riddle-question-${riddles[1].id}')),
      findsOneWidget,
    );
    await _tap(tester, 'riddle-levels-back');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await _tap(tester, 'home-progress');
    expect(find.text('1 / ${riddles.length}'), findsOneWidget);
    await _tap(tester, 'progress-riddles-open');
    expect(find.byKey(const ValueKey('riddle-journey')), findsOneWidget);
    expect(saved.riddles['current'], riddles[1].id);
    expect(tester.takeException(), isNull);
  });
}
