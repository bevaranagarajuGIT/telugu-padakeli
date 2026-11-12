import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/core/kids_learning_controller.dart';
import 'package:telugu_padakeli/core/learning_progress.dart';
import 'package:telugu_padakeli/models/puzzle.dart';
import 'package:telugu_padakeli/screens/kids_activity_screen.dart';
import 'package:telugu_padakeli/screens/kids_game_screen.dart';
import 'package:telugu_padakeli/screens/padakeli_screen.dart';
import 'package:telugu_padakeli/services/kids_learning_service.dart';
import 'package:telugu_padakeli/services/kids_question_service.dart';
import 'package:telugu_padakeli/services/learning_store.dart';
import 'package:telugu_padakeli/services/puzzle_repository.dart';
import 'package:telugu_padakeli/widgets/crossword_grid.dart';

const _puzzle = Puzzle(
  id: 901,
  level: 'beginner',
  gridSize: 2,
  rows: [
    ['క', 'ల'],
    ['ల', 'క'],
  ],
  acrossClues: [
    PuzzleClue(number: 1, clue: 'కల', answer: 'కల', row: 0, column: 0),
    PuzzleClue(number: 3, clue: 'లక', answer: 'లక', row: 1, column: 0),
  ],
  downClues: [
    PuzzleClue(number: 1, clue: 'కల', answer: 'కల', row: 0, column: 0),
    PuzzleClue(number: 2, clue: 'లక', answer: 'లక', row: 0, column: 1),
  ],
);

class _Repository implements PuzzleRepository {
  @override
  Future<List<Puzzle>> getPuzzles() async => [_puzzle];
  @override
  Future<Puzzle> getBeginnerPuzzle() async => _puzzle;
}

Future<void> _mount(
  WidgetTester tester,
  LearningProgress progress,
  Widget home, {
  double scale = 1,
  double systemScale = 1,
  bool dark = false,
}) async {
  progress.setSetting('englishHelper', true);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: progress),
        ChangeNotifierProvider(
          create: (_) => AppSettingsController(progress: progress),
        ),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark(scale) : AppTheme.light(scale),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(systemScale),
            padding: const EdgeInsets.only(top: 28, bottom: 24),
          ),
          child: child!,
        ),
        home: home,
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

Future<void> _reachFooterAction(WidgetTester tester, Finder action) async {
  if (action.hitTestable().evaluate().isEmpty) {
    final footer = find.byKey(const ValueKey('learning-action-footer'));
    await tester.drag(
      footer,
      Offset(0, tester.getCenter(footer).dy - tester.getCenter(action).dy),
    );
    await tester.pumpAndSettle();
  }
  expect(action.hitTestable(), findsOneWidget);
}

List<String> _optionKeys(WidgetTester tester, String prefix) => tester
    .widgetList<OutlinedButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is OutlinedButton &&
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(prefix),
      ),
    )
    .map((button) => (button.key! as ValueKey<String>).value)
    .toList();

void main() {
  testWidgets(
    'Classic saved completion Play again opens a fresh playable board',
    (tester) async {
      final progress = LearningProgress(MemoryLearningStore(), autoSave: false);
      addTearDown(progress.dispose);
      progress.completePuzzle('${_puzzle.id}');
      progress.saveBoard('classic', {
        'id': _puzzle.id,
        'signature': _puzzle.progressSignature,
        'cells': ['క', 'ల', 'ల', 'క'],
        'direction': 'across',
        'clue': 1,
        'cell': 0,
        'hints': 2,
        'complete': true,
      });
      await _mount(tester, progress, PadakeliScreen(repository: _Repository()));
      await _tap(tester, 'classic-replay');
      await tester.pumpAndSettle();
      expect(find.byType(CrosswordGrid), findsOneWidget);
      final grid = tester.widget<CrosswordGrid>(find.byType(CrosswordGrid));
      expect(
        grid.controllers.expand((row) => row).every((c) => c.text.isEmpty),
        isTrue,
      );
      expect(progress.board('classic')['complete'], false);
      expect(progress.board('classic')['hints'], 0);
      await _tap(tester, 'akshara-క');
      expect(grid.controllers[0][0].text, 'క');
      expect(progress.stars, 1);
      await progress.flush();
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = LearningProgress(progress.store, autoSave: false);
      addTearDown(restored.dispose);
      await restored.load();
      await _mount(tester, restored, PadakeliScreen(repository: _Repository()));
      expect(
        tester
            .widget<CrosswordGrid>(find.byType(CrosswordGrid))
            .controllers[0][0]
            .text,
        'క',
      );
      expect(restored.board('classic')['complete'], false);
      expect(restored.stars, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Across to Down skips correct shared cells, but direct editing remains possible',
    (tester) async {
      final progress = LearningProgress(MemoryLearningStore(), autoSave: false);
      addTearDown(progress.dispose);
      await _mount(tester, progress, PadakeliScreen(repository: _Repository()));
      await _tap(tester, 'difficulty-Beginner');
      await _tap(tester, 'akshara-క');
      await _tap(tester, 'akshara-ల');
      await tester.tap(find.text('నిలువు (Down)'));
      await tester.pumpAndSettle();
      CrosswordGrid grid() =>
          tester.widget<CrosswordGrid>(find.byType(CrosswordGrid));
      expect(grid().selectedCellIndex, 3);
      await _tap(tester, 'clue-down-1');
      expect(grid().selectedCellIndex, 2);
      await _tap(tester, 'akshara-ల');
      expect(grid().controllers[0][0].text, 'క');
      expect(grid().controllers[1][0].text, 'ల');
      await _tap(tester, 'crossword-cell-0');
      expect(grid().selectedCellIndex, 0);
      await _tap(tester, 'classic-clear-cell');
      expect(grid().controllers[0][0].text, '');
      expect(grid().correctCells.contains(0), false);
      await _tap(tester, 'akshara-క');
      expect(grid().selectedCellIndex, 0);
      expect(grid().controllers[1][0].text, 'ల');
      await _tap(tester, 'crossword-cell-0');
      expect(grid().selectedCellIndex, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final legacy in [true, false]) {
    testWidgets(
      '${legacy ? 'Original practice' : 'Kids completion'} cannot be solved by always choosing first',
      (tester) async {
        final progress = LearningProgress(
          MemoryLearningStore(),
          autoSave: false,
        );
        final learning = KidsLearningController(storage: progress);
        addTearDown(progress.dispose);
        addTearDown(learning.dispose);
        final activity = const KidsLearningService().getActivities().firstWhere(
          (item) => item.id == 'completion-0',
        );
        final session = learning.sessionFor(activity);
        await _mount(
          tester,
          progress,
          legacy
              ? const KidsGameScreen()
              : KidsActivityScreen(session: session, learning: learning),
        );
        final positions = <int>{};
        for (final question in activity.questions) {
          final prefix = legacy ? 'kids-answer-' : 'learning-choice-';
          final keys = _optionKeys(tester, prefix);
          positions.add(keys.indexOf('$prefix${question.answer}'));
          if (legacy) {
            await _tap(tester, '$prefix${question.answer}');
            await tester.ensureVisible(find.text('సరిచూడు'));
            await tester.tap(find.text('సరిచూడు'));
            await tester.pump(const Duration(milliseconds: 1100));
            await tester.pumpAndSettle();
          } else {
            session.selectChoice(question.answer);
            session.check();
            session.next();
            await tester.pumpAndSettle();
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
        expect(positions.length, greaterThan(1));
      },
    );
  }

  for (final (width, scale, dark, systemScale) in [
    (320.0, 1.4, true, 1.0),
    (390.0, 1.0, false, 1.0),
    (320.0, 1.4, true, 3.2),
  ]) {
    testWidgets(
      'Original practice level change waits with visible heading and action $width/$systemScale',
      (tester) async {
        tester.view.physicalSize = Size(width, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final progress = LearningProgress(
          MemoryLearningStore(),
          autoSave: false,
        );
        addTearDown(progress.dispose);
        await _mount(
          tester,
          progress,
          const KidsGameScreen(),
          scale: scale,
          systemScale: systemScale,
          dark: dark,
        );
        for (final question
            in const KidsQuestionService().getLevels().first.questions) {
          await _tap(tester, 'kids-answer-${question.answer}');
          await tester.ensureVisible(find.text('సరిచూడు'));
          await tester.tap(find.text('సరిచూడు'));
          await tester.pump(const Duration(milliseconds: 1100));
          await tester.pumpAndSettle();
        }
        await tester.pump(const Duration(seconds: 5));
        final heading = find.byKey(
          const ValueKey('legacy-level-complete-heading'),
        );
        expect(heading, findsOneWidget);
        expect(tester.getRect(heading).top, greaterThanOrEqualTo(28));
        if (systemScale == 1) {
          expect(tester.getRect(heading).bottom, lessThan(568 - 24));
        }
        final next = find.byKey(const ValueKey('legacy-next-level'));
        await _reachFooterAction(tester, next);
        expect(progress.practice['level'], 'Beginner');
        expect(progress.stars, 1);
        await progress.flush();
        await tester.pumpWidget(const SizedBox.shrink());
        final restored = LearningProgress(progress.store, autoSave: false);
        addTearDown(restored.dispose);
        await restored.load();
        await _mount(
          tester,
          restored,
          const KidsGameScreen(),
          scale: scale,
          systemScale: systemScale,
          dark: dark,
        );
        expect(heading, findsOneWidget);
        expect(restored.stars, 1);
        await _reachFooterAction(tester, next);
        await tester.tap(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(restored.practice['level'], 'Easy');
        expect(find.text('ఆ_'), findsOneWidget);
        final status = find.byKey(const ValueKey('kids-level-status-1'));
        expect(tester.getRect(status).top, greaterThanOrEqualTo(28));
        final scroll = find.byKey(const ValueKey('kids-scroll'));
        expect(
          tester.getRect(status).top,
          lessThan(tester.getRect(scroll).top + 40),
        );
        expect(restored.stars, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'Original practice retry and reopen preserve displayed choice order and question position',
    (tester) async {
      final progress = LearningProgress(MemoryLearningStore(), autoSave: false);
      addTearDown(progress.dispose);
      await _mount(tester, progress, const KidsGameScreen());
      final order = _optionKeys(tester, 'kids-answer-');
      await _tap(tester, 'kids-answer-రం');
      await tester.ensureVisible(find.text('సరిచూడు'));
      await tester.tap(find.text('సరిచూడు'));
      await tester.pumpAndSettle();
      expect(_optionKeys(tester, 'kids-answer-'), order);
      await progress.flush();
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = LearningProgress(progress.store, autoSave: false);
      addTearDown(restored.dispose);
      await restored.load();
      await _mount(tester, restored, const KidsGameScreen());
      expect(_optionKeys(tester, 'kids-answer-'), order);
      expect(find.text('కమ_'), findsOneWidget);
      await _tap(tester, 'kids-answer-లం');
      await tester.ensureVisible(find.text('సరిచూడు'));
      await tester.tap(find.text('సరిచూడు'));
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
      expect(find.text('అ_'), findsOneWidget);
      final status = find.byKey(const ValueKey('kids-level-status-0'));
      expect(tester.getRect(status).top, lessThan(200));
      expect(restored.practice['score'], 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
