import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/core/learning_progress.dart';
import 'package:telugu_padakeli/models/riddle.dart';
import 'package:telugu_padakeli/screens/progress_screen.dart';
import 'package:telugu_padakeli/services/kids_learning_service.dart';
import 'package:telugu_padakeli/services/learning_store.dart';
import 'package:telugu_padakeli/services/riddle_repository.dart';

class _RiddleRepository implements RiddleRepository {
  _RiddleRepository(this.riddles);
  final List<Riddle> riddles;
  bool fail = true;

  @override
  Future<List<Riddle>> load() async {
    if (fail) throw const FormatException('Test riddle content unavailable');
    return riddles;
  }
}

LearningProgress _progress({bool populated = false}) {
  final saved = LearningProgress(
    MemoryLearningStore(),
    clock: () => DateTime(2026, 11, 10, 12),
    autoSave: false,
  );
  if (populated) {
    for (var index = 0; index < 21; index++) {
      saved.recordAnswer('question-$index', index != 0);
    }
    saved.recordAnswer('question-0', true);
    final activity = const KidsLearningService().getActivities().first;
    saved.saveSession(activity.id, {
      'complete': true,
      'solved': {
        for (final question in activity.questions)
          question.id: question.progressSignature,
      },
    });
    saved.completeActivity(activity.id);
    saved.completePuzzle('classic-one');
  }
  return saved;
}

Future<void> _open(
  WidgetTester tester,
  LearningProgress saved, {
  double width = 390,
  double height = 568,
  double appScale = 1,
  double systemScale = 1,
  bool dark = false,
  bool reducedMotion = true,
  VoidCallback? onResume,
  VoidCallback? onLearn,
  VoidCallback? onRiddles,
  RiddleRepository riddleRepository = const LocalRiddleRepository(),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: saved,
      child: MaterialApp(
        theme: dark ? AppTheme.dark(appScale) : AppTheme.light(appScale),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(systemScale),
            disableAnimations: reducedMotion,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: ProgressScreen(
            onResume: onResume,
            onLearn: onLearn,
            onRiddles: onRiddles,
            riddleRepository: riddleRepository,
          ),
          bottomNavigationBar: const SizedBox(height: 80),
        ),
      ),
    ),
  );
  await tester.runAsync(() => tester.pumpAndSettle());
}

Finder _within(String key, String text) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.text(text),
  matchRoot: true,
);

void main() {
  late List<Riddle> riddles;
  setUpAll(() async {
    riddles = await const LocalRiddleRepository().load();
  });

  testWidgets(
    'riddle progress counts valid saved content without changing other metrics',
    (tester) async {
      final saved = _progress();
      addTearDown(saved.dispose);
      saved.saveRiddles({
        'current': riddles[8].id,
        'answers': {
          for (final riddle in riddles.take(8))
            riddle.id: {
              'signature': riddle.signature,
              'solved': true,
              'hint': true,
              'tried': riddle.choices,
            },
          riddles[8].id: {'signature': 'old content', 'solved': true},
          'removed-riddle': {'signature': 'removed content', 'solved': true},
        },
      });
      final snapshot = contentSignature(saved.riddles);
      var opened = 0;
      await _open(tester, saved, onRiddles: () => opened++);
      expect(_within('progress-riddles-solved', '8 / 20'), findsOneWidget);
      expect(_within('progress-riddles-levels', '3 / 6'), findsOneWidget);
      expect(find.text('Next level: Nature whispers'), findsOneWidget);
      expect(find.textContaining('No recorded learning yet.'), findsNothing);
      expect(_within('progress-today-count', '0'), findsOneWidget);
      expect(_within('progress-first-percentage', '—'), findsOneWidget);
      expect(_within('progress-stat-stars', '0'), findsOneWidget);
      final open = find.byKey(const ValueKey('progress-riddles-open'));
      await tester.ensureVisible(open);
      await tester.pumpAndSettle();
      await tester.tap(open);
      expect(opened, 1);
      expect(contentSignature(saved.riddles), snapshot);

      saved.saveRiddles({
        'current': riddles.last.id,
        'answers': {
          for (final riddle in riddles)
            riddle.id: {'signature': riddle.signature, 'solved': true},
        },
      });
      await tester.pumpAndSettle();
      expect(_within('progress-riddles-solved', '20 / 20'), findsOneWidget);
      expect(_within('progress-riddles-levels', '6 / 6'), findsOneWidget);
      expect(find.text('Collection complete!'), findsOneWidget);
      expect(saved.stars, 0);
      expect(saved.currentStreak, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('riddle progress load errors are visible and retryable', (
    tester,
  ) async {
    final saved = _progress();
    addTearDown(saved.dispose);
    final repository = _RiddleRepository(riddles);
    final snapshot = contentSignature(saved.riddles);
    await _open(tester, saved, riddleRepository: repository);
    expect(tester.takeException(), isA<FormatException>());
    expect(find.text('Could not load riddle progress.'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-riddles-solved')), findsNothing);
    repository.fail = false;
    final retry = find.byKey(const ValueKey('progress-riddles-retry'));
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.runAsync(() => tester.pumpAndSettle());
    expect(_within('progress-riddles-solved', '0 / 20'), findsOneWidget);
    expect(contentSignature(saved.riddles), snapshot);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'daily summary preserves over-goal counts without inflating the bar',
    (tester) async {
      final saved = _progress(populated: true);
      addTearDown(saved.dispose);
      await _open(tester, saved);

      expect(_within('progress-today-count', '21'), findsOneWidget);
      expect(
        find.text('Daily goal reached · Goal: 3 questions'),
        findsOneWidget,
      );
      expect(find.text('1 activity completed today'), findsOneWidget);
      final dailyBar = find.descendant(
        of: find.byKey(const ValueKey('progress-daily-goal')),
        matching: find.byType(LinearProgressIndicator),
      );
      expect(tester.widget<LinearProgressIndicator>(dailyBar).value, 1);
      expect(
        tester.widget<LinearProgressIndicator>(dailyBar).semanticsLabel,
        '21 correct questions today. Daily goal: 3.',
      );
      expect(_within('progress-stat-activities', '1'), findsOneWidget);
      expect(_within('progress-stat-puzzles', '1'), findsOneWidget);
      expect(_within('progress-stat-stars', '2'), findsOneWidget);
      expect(_within('progress-stat-streak', '1'), findsOneWidget);
      expect(find.text('అత్యధికం: 1 · Best: 1 day'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('20 / 21 correct on the first check.'), findsOneWidget);
      expect(
        find.text('22 submitted checks · 21 questions eventually correct.'),
        findsOneWidget,
      );
      expect(saved.stars, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty progress offers learning without invented accuracy or rewards',
    (tester) async {
      final saved = _progress();
      addTearDown(saved.dispose);
      var started = 0;
      await _open(tester, saved, onLearn: () => started++);

      expect(find.text('Daily goal: 3 questions'), findsOneWidget);
      expect(find.textContaining('No recorded learning yet.'), findsOneWidget);
      expect(_within('progress-first-percentage', '—'), findsOneWidget);
      expect(find.text('No checked questions yet.'), findsOneWidget);
      expect(find.byKey(const ValueKey('progress-resume')), findsNothing);
      expect(find.byKey(const ValueKey('progress-explore')), findsNothing);
      final start = find.byKey(const ValueKey('progress-start'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      expect(started, 1);
      expect(saved.stars, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'paths count content-valid sessions and achievements stay truthful',
    (tester) async {
      final saved = _progress(populated: true);
      addTearDown(saved.dispose);
      await _open(tester, saved);
      final activity = const KidsLearningService().getActivities().first;
      final path = find.byKey(
        ValueKey('progress-path-${activity.categories.first.name}'),
      );
      final bar = find.descendant(
        of: path,
        matching: find.byType(LinearProgressIndicator),
      );
      expect(tester.widget<LinearProgressIndicator>(bar).value, greaterThan(0));
      expect(
        _within('progress-achievement-first-activity', 'సాధించారు · Earned'),
        findsOneWidget,
      );
      expect(
        _within(
          'progress-achievement-three-learning-days',
          'ఇంకా సాధించలేదు · Not yet earned',
        ),
        findsOneWidget,
      );
      saved.saveSession(activity.id, {'complete': true, 'solved': {}});
      await tester.pumpAndSettle();
      expect(tester.widget<LinearProgressIndicator>(bar).value, 0);
      expect(saved.stars, 2);
    },
  );

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.4]) {
      for (final dark in [false, true]) {
        for (final reducedMotion in [false, true]) {
          testWidgets(
            'progress reachable at $width, scale $scale, dark $dark, reduced $reducedMotion',
            (tester) async {
              final saved = _progress(populated: true);
              addTearDown(saved.dispose);
              var resumed = 0;
              var explored = 0;
              var riddlesOpened = 0;
              await _open(
                tester,
                saved,
                width: width,
                height: 480,
                appScale: scale,
                systemScale: scale == 1 ? 1 : 1.2,
                dark: dark,
                reducedMotion: reducedMotion,
                onResume: () => resumed++,
                onLearn: () => explored++,
                onRiddles: () => riddlesOpened++,
              );
              expect(tester.takeException(), isNull);
              final resume = find.byKey(const ValueKey('progress-resume'));
              await tester.ensureVisible(resume);
              await tester.pumpAndSettle();
              expect(resume.hitTestable(), findsOneWidget);
              expect(tester.getSize(resume).height, greaterThanOrEqualTo(48));
              expect(tester.getRect(resume).bottom, lessThanOrEqualTo(400));
              await tester.tap(resume);
              expect(resumed, 1);

              final first = find.byKey(
                const ValueKey('progress-stat-activities'),
              );
              final second = find.byKey(
                const ValueKey('progress-stat-puzzles'),
              );
              final firstRect = tester.getRect(first);
              final secondRect = tester.getRect(second);
              if (scale == 1) {
                expect(firstRect.top, closeTo(secondRect.top, 0.01));
                expect(secondRect.left, greaterThan(firstRect.left));
                expect(firstRect.height, closeTo(secondRect.height, 0.01));
              } else {
                expect(secondRect.top, greaterThanOrEqualTo(firstRect.bottom));
                expect(firstRect.left, closeTo(secondRect.left, 0.01));
              }
              for (final key in [
                'progress-stat-streak',
                'progress-riddles-solved',
                'progress-first-percentage',
                'progress-path-champions',
                'progress-achievement-three-learning-days',
              ]) {
                await tester.ensureVisible(find.byKey(ValueKey(key)));
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
              }

              final riddleJourney = find.byKey(
                const ValueKey('progress-riddles-open'),
              );
              await tester.ensureVisible(riddleJourney);
              await tester.pumpAndSettle();
              expect(riddleJourney.hitTestable(), findsOneWidget);
              expect(
                tester.getSize(riddleJourney).height,
                greaterThanOrEqualTo(48),
              );
              await tester.tap(riddleJourney);
              expect(riddlesOpened, 1);

              final details = find.byKey(const ValueKey('progress-details'));
              final detailsTitle = find.text('How progress is counted');
              await tester.ensureVisible(detailsTitle);
              await tester.tap(detailsTitle);
              await tester.pumpAndSettle();
              final caveat = find.descendant(
                of: details,
                matching: find.text(
                  'This device’s data is not a mastery assessment or a cloud backup.',
                ),
              );
              await tester.ensureVisible(caveat);
              expect(caveat.hitTestable(), findsOneWidget);
              final explore = find.byKey(const ValueKey('progress-explore'));
              await tester.ensureVisible(explore);
              await tester.pumpAndSettle();
              expect(explore.hitTestable(), findsOneWidget);
              await tester.tap(explore);
              await tester.pumpAndSettle();
              expect(explored, 1);
              expect(saved.stars, 2);
              expect(tester.takeException(), isNull);
              expect(tester.binding.transientCallbackCount, 0);

              final scheme = dark
                  ? AppTheme.dark(scale).colorScheme
                  : AppTheme.light(scale).colorScheme;
              for (final (foreground, background) in [
                (scheme.onPrimaryContainer, scheme.primaryContainer),
                (scheme.onSurface, scheme.surface),
                (scheme.onSurfaceVariant, scheme.surface),
                (scheme.primary, scheme.surface),
                (scheme.secondary, scheme.surface),
              ]) {
                final light = foreground.computeLuminance();
                final dark = background.computeLuminance();
                final contrast = light > dark
                    ? (light + 0.05) / (dark + 0.05)
                    : (dark + 0.05) / (light + 0.05);
                expect(contrast, greaterThanOrEqualTo(4.5));
              }
              final backgrounds = <Color>{};
              for (final key in [
                'progress-stat-activities',
                'progress-stat-puzzles',
                'progress-stat-stars',
                'progress-stat-streak',
                'progress-first-surface',
                'progress-path-early',
                'progress-path-explorers',
                'progress-path-champions',
              ]) {
                final surface = find.byKey(ValueKey(key));
                final container = tester.widget<Container>(surface);
                final background =
                    (container.decoration! as BoxDecoration).color!;
                expect(background.a, 1);
                expect(background, isNot(scheme.surface));
                backgrounds.add(background);
                final texts = find.descendant(
                  of: surface,
                  matching: find.byType(Text),
                );
                for (final element in texts.evaluate()) {
                  final text = element.widget as Text;
                  final foreground = DefaultTextStyle.of(
                    element,
                  ).style.merge(text.style).color!;
                  expect(foreground.a, 1);
                  final first = foreground.computeLuminance();
                  final second = background.computeLuminance();
                  final contrast = first > second
                      ? (first + 0.05) / (second + 0.05)
                      : (second + 0.05) / (first + 0.05);
                  expect(
                    contrast,
                    greaterThanOrEqualTo(4.5),
                    reason: '$key: ${text.data}',
                  );
                }
              }
              expect(backgrounds, hasLength(5));
              final pathBackgrounds = <Color>{};
              for (final name in ['early', 'explorers', 'champions']) {
                final path = find.byKey(ValueKey('progress-path-$name'));
                final background =
                    (tester.widget<Container>(path).decoration!
                            as BoxDecoration)
                        .color!;
                pathBackgrounds.add(background);
                final bar = tester.widget<LinearProgressIndicator>(
                  find.descendant(
                    of: path,
                    matching: find.byType(LinearProgressIndicator),
                  ),
                );
                final track = Color.alphaBlend(
                  bar.backgroundColor!,
                  background,
                );
                final fill = bar.color!.computeLuminance();
                final behind = track.computeLuminance();
                final contrast = fill > behind
                    ? (fill + 0.05) / (behind + 0.05)
                    : (behind + 0.05) / (fill + 0.05);
                expect(contrast, greaterThanOrEqualTo(3));
              }
              expect(pathBackgrounds, hasLength(3));
            },
          );
        }
      }
    }
  }
}
