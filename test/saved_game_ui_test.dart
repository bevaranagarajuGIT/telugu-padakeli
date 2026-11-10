import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telugu_padakeli/app/navigation/app_shell.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/core/learning_progress.dart';
import 'package:telugu_padakeli/models/puzzle.dart';
import 'package:telugu_padakeli/screens/kids_game_screen.dart';
import 'package:telugu_padakeli/screens/padakeli_screen.dart';
import 'package:telugu_padakeli/services/learning_store.dart';
import 'package:telugu_padakeli/services/local_puzzle_repository.dart';
import 'package:telugu_padakeli/services/puzzle_repository.dart';
import 'package:telugu_padakeli/widgets/crossword_grid.dart';

class _Repository implements PuzzleRepository {
  const _Repository(this.puzzles);
  final List<Puzzle> puzzles;
  @override
  Future<List<Puzzle>> getPuzzles() async => puzzles;
  @override
  Future<Puzzle> getBeginnerPuzzle() async => puzzles.first;
}

Future<void> _mount(
  WidgetTester tester,
  LearningProgress progress,
  Widget screen,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: progress),
        ChangeNotifierProvider(
          create: (_) => AppSettingsController(progress: progress),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(1),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Future<LearningProgress> _reopen(
  WidgetTester tester,
  LearningProgress old,
) async {
  await old.flush();
  await tester.pumpWidget(const SizedBox.shrink());
  final restored = LearningProgress(
    old.store,
    autoSave: false,
    clock: old.clock,
  );
  await restored.load();
  return restored;
}

void main() {
  late List<Puzzle> puzzles;
  setUpAll(
    () async => puzzles = await const LocalPuzzleRepository().getPuzzles(),
  );

  testWidgets(
    'Classic reopens actual cells, clue, direction, selection and hints; changed content is not reused',
    (tester) async {
      final saved = LearningProgress(MemoryLearningStore(), autoSave: false);
      addTearDown(saved.dispose);
      final repository = _Repository(puzzles);
      await _mount(tester, saved, PadakeliScreen(repository: repository));
      await _tap(tester, 'difficulty-Beginner');
      await _tap(tester, 'akshara-ఆ');
      await _tap(tester, 'open-hints');
      await _tap(tester, 'hint-reveal-first');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('నిలువు (Down)'));
      await tester.tap(find.text('నిలువు (Down)'));
      await tester.pumpAndSettle();
      await _tap(tester, 'clue-down-1');
      await _tap(tester, 'crossword-cell-3');
      final snapshot = saved.board('classic');
      expect(snapshot['direction'], 'down');
      expect(snapshot['cell'], 3);
      expect(snapshot['hints'], 1);
      final restored = await _reopen(tester, saved);
      addTearDown(restored.dispose);
      await _mount(tester, restored, PadakeliScreen(repository: repository));
      expect(restored.board('classic'), snapshot);
      final grid = tester.widget<CrosswordGrid>(find.byType(CrosswordGrid));
      expect(grid.controllers[0][0].text, 'ఆ');
      expect(grid.controllers[0][1].text, 'ట');
      final first = puzzles.first;
      final changed = Puzzle(
        id: first.id,
        level: first.level,
        gridSize: first.gridSize,
        rows: first.rows,
        acrossClues: [
          PuzzleClue(
            number: first.acrossClues.first.number,
            clue: 'కొత్త సూచన',
            answer: first.acrossClues.first.answer,
            row: first.acrossClues.first.row,
            column: first.acrossClues.first.column,
          ),
          ...first.acrossClues.skip(1),
        ],
        downClues: first.downClues,
      );
      final changedSave = await _reopen(tester, restored);
      addTearDown(changedSave.dispose);
      await _mount(
        tester,
        changedSave,
        PadakeliScreen(repository: _Repository([changed])),
      );
      expect(find.textContaining('Saved content changed'), findsOneWidget);
      expect(
        tester
            .widget<CrosswordGrid>(find.byType(CrosswordGrid))
            .controllers[0][0]
            .text,
        '',
      );
      expect(changedSave.board('classic')['hints'], 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'original practice restores a scored attempt without double credit or automatic celebration',
    (tester) async {
      final saved = LearningProgress(MemoryLearningStore(), autoSave: false);
      addTearDown(saved.dispose);
      await _mount(tester, saved, const KidsGameScreen());
      await _tap(tester, 'kids-answer-లం');
      await tester.ensureVisible(find.text('సరిచూడు'));
      await tester.tap(find.text('సరిచూడు'));
      await tester.pump();
      expect(saved.practice['score'], 1);
      final restored = await _reopen(tester, saved);
      addTearDown(restored.dispose);
      await _mount(tester, restored, const KidsGameScreen());
      expect(find.bySemanticsLabel('స్కోరు: 1'), findsOneWidget);
      expect(find.text('కమ_'), findsOneWidget);
      expect(find.byKey(const ValueKey('kids-feedback-success')), findsNothing);
      expect(restored.attempts, 1);
      await tester.ensureVisible(find.text('సరిచూడు'));
      await tester.tap(find.text('సరిచూడు'));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('అ_'), findsOneWidget);
      expect(find.bySemanticsLabel('స్కోరు: 1'), findsOneWidget);
      expect(restored.attempts, 1);
      expect(restored.stars, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Daily completion reopens without replaying and rewards once per date',
    (tester) async {
      var now = DateTime(2026, 11, 10, 23, 59);
      final saved = LearningProgress(
        MemoryLearningStore(),
        autoSave: false,
        clock: () => now,
      );
      addTearDown(saved.dispose);
      const repository = _Repository([
        Puzzle(
          id: 101,
          level: 'beginner',
          gridSize: 1,
          rows: [
            ['క'],
          ],
          acrossClues: [
            PuzzleClue(
              number: 1,
              clue: 'అక్షరం',
              answer: 'క',
              row: 0,
              column: 0,
            ),
          ],
          downClues: [],
        ),
      ]);
      await _mount(
        tester,
        saved,
        PadakeliScreen(repository: repository, dailyDate: saved.today),
      );
      await _tap(tester, 'akshara-క');
      await _tap(tester, 'classic-check');
      await tester.pump(const Duration(milliseconds: 1100));
      expect(
        find.byKey(const ValueKey('daily-puzzle-complete')),
        findsOneWidget,
      );
      expect(saved.stars, 1);
      final restored = await _reopen(tester, saved);
      addTearDown(restored.dispose);
      await _mount(
        tester,
        restored,
        PadakeliScreen(repository: repository, dailyDate: restored.today),
      );
      expect(
        find.byKey(const ValueKey('daily-puzzle-complete')),
        findsOneWidget,
      );
      expect(restored.stars, 1);
      await _tap(tester, 'daily-replay');
      await _tap(tester, 'akshara-క');
      await _tap(tester, 'classic-check');
      await tester.pump(const Duration(milliseconds: 1100));
      expect(restored.stars, 1);
      now = DateTime(2026, 11, 11);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.textContaining('saved past date'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await _mount(
        tester,
        restored,
        PadakeliScreen(repository: repository, dailyDate: restored.today),
      );
      await _tap(tester, 'akshara-క');
      await _tap(tester, 'classic-check');
      await tester.pump(const Duration(milliseconds: 1100));
      expect(restored.stars, 2);
      expect(restored.completedPuzzles, {'101'});
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'reset cancellation retains real data; confirmation removes Resume but preserves settings and Welcome',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'padakeli.onboarding.completed': true,
      });
      final saved = LearningProgress(
        PreferencesLearningStore(),
        autoSave: false,
      );
      saved.setSetting('englishHelper', true);
      saved.completeActivity('pictures');
      saved.savePractice({'level': 'Beginner'});
      addTearDown(saved.dispose);
      await _mount(tester, saved, const AppShell());
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await _tap(tester, 'reset-progress-setting');
      await _tap(tester, 'reset-progress-cancel');
      expect(saved.stars, 1);
      expect(saved.lastDestination, 'practice');
      await _tap(tester, 'reset-progress-setting');
      await _tap(tester, 'reset-progress-confirm');
      await tester.pumpAndSettle();
      expect(saved.stars, 0);
      expect(saved.lastDestination, isNull);
      expect(find.byKey(const ValueKey('home-resume')), findsNothing);
      expect(saved.settings['englishHelper'], true);
      final reopened = LearningProgress(saved.store, autoSave: false);
      await reopened.load();
      expect(reopened.stars, 0);
      expect(reopened.settings['englishHelper'], true);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'padakeli.onboarding.completed',
        ),
        true,
      );
      reopened.dispose();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
