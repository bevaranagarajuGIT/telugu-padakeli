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
import 'package:telugu_padakeli/services/onboarding_store.dart';
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

  for (final finish in ['typing', 'hint', 'older saved board']) {
    testWidgets(
      'automatic $finish completion persists and never rewards replay twice',
      (tester) async {
        final progress = LearningProgress(
          MemoryLearningStore(),
          autoSave: false,
        );
        addTearDown(progress.dispose);
        final puzzle = puzzles.first;
        final cells = [
          for (
            var index = 0;
            index < puzzle.gridSize * puzzle.gridSize;
            index++
          )
            puzzle.isBlocked(index ~/ puzzle.gridSize, index % puzzle.gridSize)
                ? ''
                : puzzle.answerAt(
                    index ~/ puzzle.gridSize,
                    index % puzzle.gridSize,
                  ),
        ];
        final last = cells.lastIndexWhere((value) => value.isNotEmpty);
        if (finish != 'older saved board') cells[last] = '';
        progress.saveBoard('classic', {
          'id': puzzle.id,
          'signature': puzzle.progressSignature,
          'cells': cells,
          'direction': 'across',
          'clue': puzzle.acrossClues.last.number,
          'cell': last,
          'hints': 2,
          'complete': false,
        });
        var homeCount = 0;
        final screen = PadakeliScreen(
          repository: _Repository(puzzles),
          onBack: () => homeCount++,
        );
        await _mount(tester, progress, screen);
        if (finish == 'typing') {
          await _tap(
            tester,
            'akshara-${puzzle.answerAt(last ~/ puzzle.gridSize, last % puzzle.gridSize)}',
          );
        } else if (finish == 'hint') {
          await _tap(tester, 'open-hints');
          await _tap(tester, 'hint-reveal-cell');
        }
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
        expect(progress.board('classic')['complete'], true);
        expect(progress.board('classic')['hints'], finish == 'hint' ? 3 : 2);
        expect(progress.stars, 1);
        final snapshot = progress.board('classic');
        Future<void> review(LearningProgress current) async {
          final reviewAgain = tester
              .widget<OutlinedButton>(
                find.byKey(const ValueKey('classic-review-answers')),
              )
              .onPressed!;
          await _tap(tester, 'classic-review-answers');
          reviewAgain();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('classic-answer-review')),
            findsOneWidget,
          );
          final scrollable = find.descendant(
            of: find.byKey(const ValueKey('classic-answer-review-scroll')),
            matching: find.byType(Scrollable),
          );
          for (final (direction, clues) in [
            ('across', puzzle.acrossClues),
            ('down', puzzle.downClues),
          ]) {
            for (final clue in clues) {
              final row = find.byKey(
                ValueKey('review-clue-$direction-${clue.number}'),
              );
              await tester.scrollUntilVisible(row, 100, scrollable: scrollable);
              expect(
                find.descendant(of: row, matching: find.text(clue.answer)),
                findsOneWidget,
              );
              expect(
                find.descendant(
                  of: row,
                  matching: find.text(
                    '${clue.number}. ${clue.clue} (${clue.aksharaCount})',
                  ),
                ),
                findsOneWidget,
              );
            }
          }
          expect(find.byType(TextField), findsNothing);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('classic-review-done')),
            100,
            scrollable: scrollable,
          );
          await tester.pumpAndSettle();
          await _tap(tester, 'classic-review-done');
          await tester.pumpAndSettle();
          expect(current.board('classic'), snapshot);
          expect(current.stars, 1);
          expect(
            find.byKey(const ValueKey('classic-level-complete')),
            findsOneWidget,
          );
        }

        await review(progress);
        await tester.pump(const Duration(seconds: 5));
        expect(progress.board('classic'), snapshot);
        expect(find.byType(Dialog), findsNothing);
        await _tap(tester, 'classic-completion-home');
        await tester.pumpAndSettle();
        expect(homeCount, 1);
        expect(progress.board('classic'), snapshot);
        final restored = await _reopen(tester, progress);
        addTearDown(restored.dispose);
        await _mount(
          tester,
          restored,
          PadakeliScreen(repository: _Repository(puzzles)),
        );
        expect(find.byType(Dialog), findsNothing);
        expect(
          find.byKey(const ValueKey('classic-level-complete')),
          findsOneWidget,
        );
        expect(restored.board('classic'), snapshot);
        await review(restored);
        await _tap(tester, 'classic-replay');
        await tester.pumpAndSettle();
        expect(restored.board('classic')['complete'], false);
        for (var index = 0; index < cells.length; index++) {
          if (puzzle.isBlocked(
            index ~/ puzzle.gridSize,
            index % puzzle.gridSize,
          )) {
            continue;
          }
          await _tap(tester, 'crossword-cell-$index');
          await _tap(
            tester,
            'akshara-${puzzle.answerAt(index ~/ puzzle.gridSize, index % puzzle.gridSize)}',
          );
        }
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
        expect(restored.stars, 1);
        expect(restored.board('classic')['complete'], true);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'a hidden Classic tab never opens completion over another screen',
    (tester) async {
      final progress = LearningProgress(MemoryLearningStore(), autoSave: false);
      addTearDown(progress.dispose);
      final puzzle = puzzles.first;
      progress.saveBoard('classic', {
        'id': puzzle.id,
        'signature': puzzle.progressSignature,
        'cells': [
          for (
            var index = 0;
            index < puzzle.gridSize * puzzle.gridSize;
            index++
          )
            puzzle.isBlocked(index ~/ puzzle.gridSize, index % puzzle.gridSize)
                ? ''
                : puzzle.answerAt(
                    index ~/ puzzle.gridSize,
                    index % puzzle.gridSize,
                  ),
        ],
        'complete': false,
      });
      await _mount(
        tester,
        progress,
        TickerMode(
          enabled: false,
          child: PadakeliScreen(repository: _Repository(puzzles)),
        ),
      );
      expect(find.byType(Dialog), findsNothing);
      expect(progress.board('classic')['complete'], true);
      expect(
        find.byKey(const ValueKey('classic-level-complete')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
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
    'Classic difficulty re-selection retains the current puzzle, cells and hints',
    (tester) async {
      final saved = LearningProgress(MemoryLearningStore(), autoSave: false);
      addTearDown(saved.dispose);
      final puzzle = puzzles
          .where((item) => item.level == 'beginner')
          .skip(1)
          .first;
      final clue = puzzle.acrossClues.first;
      final selected = clue.row * puzzle.gridSize + clue.column;
      saved.saveBoard('classic', {
        'id': puzzle.id,
        'signature': puzzle.progressSignature,
        'cells': [
          for (
            var index = 0;
            index < puzzle.gridSize * puzzle.gridSize;
            index++
          )
            index == selected
                ? puzzle.answerAt(
                    index ~/ puzzle.gridSize,
                    index % puzzle.gridSize,
                  )
                : '',
        ],
        'direction': 'across',
        'clue': clue.number,
        'cell': selected,
        'hints': 2,
        'complete': false,
      });
      await _mount(
        tester,
        saved,
        PadakeliScreen(repository: _Repository(puzzles)),
      );
      final snapshot = saved.board('classic');
      await tester.tap(find.byTooltip('Change difficulty'));
      await tester.pumpAndSettle();
      await _tap(tester, 'difficulty-Beginner');
      await tester.pumpAndSettle();
      expect(saved.board('classic'), snapshot);
      final grid = tester.widget<CrosswordGrid>(find.byType(CrosswordGrid));
      expect(grid.puzzle.id, puzzle.id);
      expect(
        grid.controllers[clue.row][clue.column].text,
        puzzle.answerAt(clue.row, clue.column),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Classic difficulty switching and relaunch retain each unfinished level',
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
      final beginner = saved.board('classic');
      await tester.tap(find.byTooltip('Change difficulty'));
      await tester.pumpAndSettle();
      await _tap(tester, 'difficulty-Easy');
      await _tap(tester, 'akshara-క');
      final easy = saved.board('classic');
      await tester.tap(find.byTooltip('Change difficulty'));
      await tester.pumpAndSettle();
      await _tap(tester, 'difficulty-Beginner');
      await tester.pumpAndSettle();
      expect(saved.board('classic'), beginner);

      final restored = await _reopen(tester, saved);
      addTearDown(restored.dispose);
      await _mount(tester, restored, PadakeliScreen(repository: repository));
      expect(restored.board('classic'), beginner);
      await tester.tap(find.byTooltip('Change difficulty'));
      await tester.pumpAndSettle();
      await _tap(tester, 'difficulty-Easy');
      await tester.pumpAndSettle();
      expect(restored.board('classic'), easy);
      expect(
        tester
            .widget<CrosswordGrid>(find.byType(CrosswordGrid))
            .controllers[0][0]
            .text,
        'క',
      );
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
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
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
        PreferencesOnboardingStore.completionKey: true,
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
          PreferencesOnboardingStore.completionKey,
        ),
        true,
      );
      reopened.dispose();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
