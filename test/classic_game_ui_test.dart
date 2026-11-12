import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/app/theme/app_colors.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/models/puzzle.dart';
import 'package:telugu_padakeli/models/telugu_akshara.dart';
import 'package:telugu_padakeli/screens/padakeli_screen.dart';
import 'package:telugu_padakeli/services/local_puzzle_repository.dart';
import 'package:telugu_padakeli/services/puzzle_repository.dart';
import 'package:telugu_padakeli/widgets/premium_telugu_text.dart';
import 'package:telugu_padakeli/widgets/crossword_grid.dart';
import 'package:telugu_padakeli/widgets/engagement_motion.dart';

class _Repository implements PuzzleRepository {
  const _Repository(this.puzzles);
  final List<Puzzle> puzzles;

  @override
  Future<List<Puzzle>> getPuzzles() async => puzzles;

  @override
  Future<Puzzle> getBeginnerPuzzle() async => puzzles.first;
}

late List<Puzzle> _puzzles;

Puzzle _singleCellPuzzle(String level) => Puzzle(
  id: 101 + Puzzle.levels.indexOf(level),
  level: level,
  gridSize: 1,
  rows: const [
    ['క'],
  ],
  acrossClues: const [
    PuzzleClue(number: 1, clue: 'ఒక అక్షరం', answer: 'క', row: 0, column: 0),
  ],
  downClues: const [],
);

Puzzle _withBlockedMargins(Puzzle puzzle, int padding) {
  PuzzleClue moveClue(PuzzleClue clue) => PuzzleClue(
    number: clue.number,
    clue: clue.clue,
    hint: clue.hint,
    answer: clue.answer,
    row: clue.row + padding,
    column: clue.column + padding,
  );
  return Puzzle(
    id: puzzle.id,
    level: puzzle.level,
    gridSize: puzzle.gridSize + padding * 2,
    rows: List.generate(
      puzzle.gridSize + padding * 2,
      (row) => List.generate(
        puzzle.gridSize + padding * 2,
        (column) =>
            row >= padding &&
                row < puzzle.gridSize + padding &&
                column >= padding &&
                column < puzzle.gridSize + padding
            ? puzzle.rows[row - padding][column - padding]
            : '#',
      ),
    ),
    acrossClues: puzzle.acrossClues.map(moveClue).toList(),
    downClues: puzzle.downClues.map(moveClue).toList(),
  );
}

Future<void> _open(
  WidgetTester tester, {
  String level = 'Beginner',
  double appScale = 1,
  double systemScale = 1,
  bool dark = false,
  bool disableAnimations = true,
  double navigationHeight = 0,
  List<Puzzle>? puzzles,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark(appScale) : AppTheme.light(appScale),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(systemScale),
          disableAnimations: disableAnimations,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: PadakeliScreen(repository: _Repository(puzzles ?? _puzzles)),
        bottomNavigationBar: navigationHeight == 0
            ? null
            : SizedBox(height: navigationHeight),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(level));
  await tester.tap(find.text(level));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _menu(WidgetTester tester, String key) async {
  await _tap(tester, find.byKey(const ValueKey('classic-more')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('classic-actions-sheet')), findsOneWidget);
  await _tap(tester, find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, Puzzle puzzle) async {
  for (var row = 0; row < puzzle.gridSize; row++) {
    for (var column = 0; column < puzzle.gridSize; column++) {
      if (puzzle.isBlocked(row, column)) continue;
      await _tap(
        tester,
        find.byKey(
          ValueKey('crossword-cell-${row * puzzle.gridSize + column}'),
        ),
      );
      await _tap(
        tester,
        find.byKey(ValueKey('akshara-${puzzle.answerAt(row, column)}')),
      );
    }
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(() async {
    _puzzles = await const LocalPuzzleRepository().getPuzzles();
    for (final (family, file) in [
      (PremiumTeluguText.fontFamily, 'NotoSansTelugu'),
      ('Roboto', 'Roboto'),
    ]) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'Bold']) {
        loader.addFont(rootBundle.load('assets/fonts/$file-$weight.ttf'));
      }
      await loader.load();
    }
  });

  testWidgets('Normal phone shows clues once and actions above navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _open(tester, navigationHeight: 88);
    expect(
      find.text('1. ${_puzzles.first.acrossClues.first.clue} (2)'),
      findsOneWidget,
    );
    for (final (key, telugu, english) in [
      ('classic-clear-cell', 'అక్షరం తీసేయి', 'Clear letter'),
      ('classic-backspace', 'వెనక్కి', 'Backspace'),
    ]) {
      final button = find.byKey(ValueKey(key));
      expect(
        find.descendant(of: button, matching: find.text(telugu)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: button, matching: find.text(english)),
        findsOneWidget,
      );
      final rect = tester.getRect(button);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(844 - 88));
      expect(rect.height, greaterThanOrEqualTo(48));
    }
    expect(find.byKey(const ValueKey('classic-check')), findsNothing);
    expect(find.byTooltip('Hints').hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey('classic-reset-word')), findsNothing);
    await _tap(tester, find.byKey(const ValueKey('classic-more')));
    await tester.pumpAndSettle();
    expect(find.text('Clear word').hitTestable(), findsOneWidget);
    expect(find.text('Restart').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'whole words confirm automatically and crossing edits recompute dark=$dark',
      (tester) async {
        await _open(tester, dark: dark);
        CrosswordGrid grid() =>
            tester.widget<CrosswordGrid>(find.byType(CrosswordGrid));
        expect(grid().correctCells, isEmpty);
        await _tap(tester, find.byKey(const ValueKey('akshara-ఆ')));
        expect(grid().correctCells, isEmpty);
        await _tap(tester, find.byKey(const ValueKey('akshara-ఖం')));
        expect(grid().correctCells, isEmpty);
        expect(grid().incorrectCells, {1});
        await _tap(tester, find.byKey(const ValueKey('akshara-ట')));
        expect(grid().correctCells, {0, 1});
        final marker = find.byKey(const ValueKey('clue-correct-across-1'));
        expect(marker, findsOneWidget);
        expect(
          tester.widget<Icon>(marker).semanticLabel,
          contains('Correct answer'),
        );
        final background = dark
            ? AppColors.darkSuccessBackground
            : AppColors.successBackground;
        final foreground = dark
            ? AppColors.darkSuccessForeground
            : AppColors.successForeground;
        final decoration =
            tester
                    .widget<Container>(
                      find.byKey(const ValueKey('selected-cell')),
                    )
                    .decoration!
                as BoxDecoration;
        expect(decoration.color, background);
        final outline = (decoration.border! as Border).top.color;
        expect(outline, dark ? AppColors.orange : AppColors.deepOrange);
        final outlineLuminances = [
          outline.computeLuminance(),
          background.computeLuminance(),
        ]..sort();
        expect(
          (outlineLuminances.last + 0.05) / (outlineLuminances.first + 0.05),
          greaterThanOrEqualTo(3),
        );
        final text = tester.widget<Text>(
          find.byKey(const ValueKey('crossword-cell-value-1')),
        );
        expect(text.style!.color, foreground);
        expect(
          (background.computeLuminance() + 0.05) /
              (foreground.computeLuminance() + 0.05),
          dark ? lessThanOrEqualTo(1 / 4.5) : greaterThanOrEqualTo(4.5),
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                (widget.properties.label?.contains('Correct word') ?? false),
          ),
          findsNWidgets(2),
        );
        for (final action in ['classic-clear-cell', 'classic-backspace']) {
          await _tap(tester, find.byKey(ValueKey(action)));
          expect(grid().correctCells, isEmpty);
          expect(marker, findsNothing);
          await _tap(tester, find.byKey(const ValueKey('akshara-ట')));
          expect(grid().correctCells, {0, 1});
        }
        await _tap(tester, find.text('అడ్డం (Across)'));
        await _tap(tester, find.byKey(const ValueKey('clue-across-1')));
        await _tap(tester, find.byKey(const ValueKey('akshara-ఖం')));
        expect(grid().correctCells, isEmpty);
        expect(marker, findsNothing);
        expect(
          find.byKey(const ValueKey('clue-correct-across-2')),
          findsNothing,
        );
        await _tap(tester, find.text('నిలువు (Down)'));
        expect(find.byKey(const ValueKey('clue-correct-down-1')), findsNothing);
        await _tap(tester, find.byKey(const ValueKey('akshara-ఆ')));
        expect(grid().correctCells, {0, 1});
        expect(find.byKey(const ValueKey('clue-correct-down-1')), findsNothing);
        await _menu(tester, 'classic-reset-word');
        expect(grid().correctCells, isEmpty);
        await _menu(tester, 'classic-reset');
        await tester.pumpAndSettle();
        await _tap(tester, find.byKey(const ValueKey('classic-reset-confirm')));
        expect(grid().correctCells, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'hint completion keeps large-text grid answers editable dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final puzzle = _puzzles.firstWhere((puzzle) => puzzle.id == 11);
        final clue = puzzle.acrossClues.first;
        final path = puzzle.cellsForClue(clue, PuzzleDirection.across);
        await _open(
          tester,
          level: 'Expert',
          puzzles: [puzzle],
          dark: dark,
          systemScale: 3.2,
        );
        for (final index in path.take(path.length - 1)) {
          final answer = puzzle.answerAt(
            index ~/ puzzle.gridSize,
            index % puzzle.gridSize,
          );
          await _tap(tester, find.byKey(ValueKey('akshara-$answer')));
        }
        expect(
          tester.widget<CrosswordGrid>(find.byType(CrosswordGrid)).correctCells,
          isEmpty,
        );
        await _tap(tester, find.byKey(const ValueKey('open-hints')));
        await _tap(tester, find.byKey(const ValueKey('hint-reveal-cell')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<CrosswordGrid>(find.byType(CrosswordGrid)).correctCells,
          path.toSet(),
        );
        expect(
          find.byKey(ValueKey('clue-correct-across-${clue.number}')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('classic-answer-editor')),
          findsNothing,
        );
        for (final index in path) {
          expect(
            tester
                .widget<InkWell>(find.byKey(ValueKey('crossword-cell-$index')))
                .onTap,
            isNotNull,
          );
          expect(
            tester
                .widget<Text>(
                  find.byKey(ValueKey('crossword-cell-value-$index')),
                )
                .data,
            puzzle.answerAt(index ~/ puzzle.gridSize, index % puzzle.gridSize),
          );
        }
        await _tap(
          tester,
          find.byKey(ValueKey('crossword-cell-${path.first}')),
        );
        await _tap(tester, find.byKey(const ValueKey('classic-clear-cell')));
        expect(
          tester.widget<CrosswordGrid>(find.byType(CrosswordGrid)).correctCells,
          isEmpty,
        );
        expect(
          find.byKey(ValueKey('clue-correct-across-${clue.number}')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'vibrant edit buttons retain contrast and lock on success dark=$dark',
      (tester) async {
        await _open(tester, dark: dark);
        final toolbar = find.byKey(const ValueKey('classic-edit-toolbar'));
        final material = tester.widget<Material>(toolbar);
        expect(material.elevation, 0);
        expect(
          find.descendant(of: toolbar, matching: find.byType(FilledButton)),
          findsNWidgets(2),
        );
        expect(
          tester.widget(find.byKey(const ValueKey('open-hints'))),
          isA<FilledButton>(),
        );
        expect(find.byKey(const ValueKey('classic-check')), findsNothing);
        for (final key in ['classic-clear-cell', 'classic-backspace']) {
          final finder = find.byKey(ValueKey(key));
          final button = tester.widget<FilledButton>(finder);
          final background = button.style!.backgroundColor!.resolve({})!;
          final foreground = button.style!.foregroundColor!.resolve({})!;
          final luminances = [
            foreground.computeLuminance(),
            background.computeLuminance(),
          ]..sort();
          expect(
            (luminances.last + 0.05) / (luminances.first + 0.05),
            greaterThanOrEqualTo(4.5),
          );
          expect(tester.getSize(finder).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
          expect(
            find.descendant(of: finder, matching: find.byType(Icon)),
            findsOneWidget,
          );
        }
        await _fill(tester, _puzzles.first);
        for (final key in ['classic-clear-cell', 'classic-backspace']) {
          expect(
            tester.widget<FilledButton>(find.byKey(ValueKey(key))).onPressed,
            isNull,
          );
        }
        await tester.pump(const Duration(milliseconds: 1100));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'all Expert clues remain visible with tight padding dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final puzzle = _puzzles.firstWhere((puzzle) => puzzle.id == 11);
        await _open(tester, level: 'Expert', puzzles: [puzzle], dark: dark);
        var tilesHeight = 0.0;
        for (final clue in puzzle.acrossClues) {
          expect(
            find.text('${clue.number}. ${clue.clue} (${clue.aksharaCount})'),
            findsOneWidget,
          );
          final tile = find.byKey(ValueKey('clue-across-${clue.number}'));
          final height = tester.getSize(tile).height;
          expect(height, greaterThanOrEqualTo(48));
          tilesHeight += height;
        }
        final list = find.byKey(const ValueKey('classic-clue-list'));
        expect(tester.getSize(list).height, closeTo(tilesHeight, 0.1));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final dark in [false, true]) {
    testWidgets(
      'compact Classic identifies direction beside input dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final puzzle = _puzzles.firstWhere((puzzle) => puzzle.id == 11);
        await _open(tester, level: 'Expert', puzzles: [puzzle], dark: dark);
        expect(
          find.byKey(const ValueKey('classic-answer-editor')),
          findsNothing,
        );
        expect(
          tester
              .getSize(find.byKey(const ValueKey('crossword-visible-board')))
              .height,
          lessThanOrEqualTo(300),
        );
        final gridScroll = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('crossword-grid-scroll')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.right,
            ),
          ),
        );
        expect(gridScroll.position.maxScrollExtent, 0);
        for (final direction in PuzzleDirection.values) {
          final chip = find.byKey(
            ValueKey('classic-direction-${direction.name}'),
          );
          await _tap(tester, chip);
          final selected = tester.widget<ChoiceChip>(chip);
          expect(selected.selected, isTrue);
          expect(
            (selected.avatar! as Icon).icon,
            direction == PuzzleDirection.across
                ? Icons.arrow_forward_rounded
                : Icons.arrow_downward_rounded,
          );
          final textColor = (selected.label as PremiumTeluguText).style!.color!;
          final luminances = [
            textColor.computeLuminance(),
            selected.selectedColor!.computeLuminance(),
          ]..sort();
          expect(
            (luminances.last + 0.05) / (luminances.first + 0.05),
            greaterThanOrEqualTo(4.5),
          );
          final label = tester
              .widget<Text>(
                find.byKey(const ValueKey('classic-input-direction')),
              )
              .data!;
          expect(
            label,
            contains(
              direction == PuzzleDirection.across
                  ? '→ అడ్డం / Across'
                  : '↓ నిలువు / Down',
            ),
          );
          final grid = tester.widget<CrosswordGrid>(find.byType(CrosswordGrid));
          final cells = grid.selectedCells;
          expect(cells, isNotEmpty);
          expect(
            cells
                .map(
                  (cell) => direction == PuzzleDirection.across
                      ? cell ~/ puzzle.gridSize
                      : cell % puzzle.gridSize,
                )
                .toSet()
                .length,
            1,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Across, Down and hints show the answer akshara count', (
    tester,
  ) async {
    await _open(tester);
    final puzzle = _puzzles.first;
    for (final direction in PuzzleDirection.values) {
      await _tap(
        tester,
        find.text(
          direction == PuzzleDirection.across
              ? 'అడ్డం (Across)'
              : 'నిలువు (Down)',
        ),
      );
      final clues = direction == PuzzleDirection.across
          ? puzzle.acrossClues
          : puzzle.downClues;
      for (final clue in clues) {
        final count = puzzle.cellsForClue(clue, direction).length;
        expect(
          find.text('${clue.number}. ${clue.clue} ($count)'),
          findsOneWidget,
        );
      }
      final clue = clues.first;
      final count = puzzle.cellsForClue(clue, direction).length;
      final label = '${clue.number}. ${clue.clue} ($count)';
      await _tap(tester, find.byKey(const ValueKey('open-hints')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('classic-hints-scroll')),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
      await _tap(tester, find.byTooltip('Close hints'));
      await tester.pumpAndSettle();
    }
    await _tap(tester, find.byKey(const ValueKey('akshara-ఆ')));
    expect(find.text('1. మన పైన నీలంగా కనిపించేది (3)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'all boards crop only empty margins and preserve logical indices',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final puzzle in [
        ..._puzzles,
        _withBlockedMargins(_puzzles.last, 2),
      ]) {
        puzzle.validate();
        final occupiedRows = [
          for (var row = 0; row < puzzle.gridSize; row++)
            if (puzzle.rows[row].any((cell) => cell != '#')) row,
        ];
        final occupiedColumns = [
          for (var column = 0; column < puzzle.gridSize; column++)
            if (puzzle.rows.any((row) => row[column] != '#')) column,
        ];
        final controllers = [
          for (final row in puzzle.rows)
            [for (final _ in row) TextEditingController()],
        ];
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(1),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 280,
                  child: CrosswordGrid(
                    puzzle: puzzle,
                    controllers: controllers,
                    selectedCellIndex: null,
                    selectedCells: const [],
                    onCellSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final visibleRows = occupiedRows.last - occupiedRows.first + 1;
        final visibleColumns = occupiedColumns.last - occupiedColumns.first + 1;
        final board = tester.getSize(
          find.byKey(const ValueKey('crossword-visible-board')),
        );
        final cellExtent = board.width / visibleColumns;
        expect(cellExtent, greaterThanOrEqualTo(48));
        expect(board.height, closeTo(visibleRows * cellExtent, 0.01));
        for (var row = 0; row < puzzle.gridSize; row++) {
          for (var column = 0; column < puzzle.gridSize; column++) {
            final index = row * puzzle.gridSize + column;
            final blocked = puzzle.isBlocked(row, column);
            final key = blocked
                ? 'crossword-blocked-cell-$index'
                : 'crossword-cell-$index';
            final cropped =
                row < occupiedRows.first ||
                row > occupiedRows.last ||
                column < occupiedColumns.first ||
                column > occupiedColumns.last;
            expect(
              find.byKey(ValueKey(key)),
              cropped ? findsNothing : findsOneWidget,
            );
            expect(
              find.byKey(ValueKey('blocked-cell-motif-$index')),
              blocked && !cropped ? findsOneWidget : findsNothing,
            );
          }
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        for (final controller in controllers.expand((row) => row)) {
          controller.dispose();
        }
      }
    },
  );

  for (final (level, id) in [
    ('Medium', 7),
    ('Medium', 8),
    ('Hard', 9),
    ('Hard', 10),
    ('Expert', 11),
    ('Expert', 12),
  ]) {
    testWidgets('$level board $id fits a small phone and accepts all answers', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final puzzle = _puzzles.firstWhere((p) => p.id == id);
      await _open(tester, level: level, puzzles: [puzzle], systemScale: 1.5);
      expect(tester.takeException(), isNull);
      await _fill(tester, puzzle);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(
        find.byKey(const ValueKey('classic-level-complete')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final (level, id, padding) in [
    ('Hard', 9, 0),
    ('Expert', 12, 0),
    ('Expert', 12, 2),
  ]) {
    testWidgets(
      '$level palette input keeps the active cell visible with margin $padding',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final source = _puzzles.firstWhere((p) => p.id == id);
        final puzzle = padding == 0
            ? source
            : _withBlockedMargins(source, padding);
        puzzle.validate();
        await _open(tester, level: level, puzzles: [puzzle], systemScale: 1.5);
        final clue = puzzle.acrossClues.reduce(
          (a, b) =>
              a.column + TeluguAkshara.split(a.answer).length >
                  b.column + TeluguAkshara.split(b.answer).length
              ? a
              : b,
        );
        await _tap(tester, find.byKey(ValueKey('clue-across-${clue.number}')));
        final viewport = find.descendant(
          of: find.byType(CrosswordGrid),
          matching: find.byType(SingleChildScrollView),
        );
        for (final akshara in TeluguAkshara.split(clue.answer)) {
          await _tap(tester, find.byKey(ValueKey('akshara-$akshara')));
          final active = tester.getRect(
            find.byKey(const ValueKey('selected-cell')),
          );
          final visible = tester.getRect(viewport);
          expect(active.left, greaterThanOrEqualTo(visible.left - 0.1));
          expect(active.right, lessThanOrEqualTo(visible.right + 0.1));
        }
        final path = puzzle.cellsForClue(clue, PuzzleDirection.across);
        for (final cell in path.reversed) {
          await _tap(tester, find.byKey(const ValueKey('classic-backspace')));
          final active = tester.getRect(
            find.byKey(const ValueKey('selected-cell')),
          );
          final visible = tester.getRect(viewport);
          expect(active.left, greaterThanOrEqualTo(visible.left - 0.1));
          expect(active.right, lessThanOrEqualTo(visible.right + 0.1));
          expect(
            tester
                .widget<Text>(
                  find.byKey(ValueKey('crossword-cell-value-$cell')),
                )
                .data,
            '',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'grid alone updates, corrects earlier answers and shares crossings',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final puzzle = _puzzles.firstWhere((p) => p.id == 9);
      await _open(tester, level: 'Hard', puzzles: [puzzle]);
      final clue = puzzle.acrossClues.firstWhere((c) => c.aksharaCount >= 4);
      final path = puzzle.cellsForClue(clue, PuzzleDirection.across);
      final answer = TeluguAkshara.split(clue.answer);
      await _tap(tester, find.byKey(ValueKey('clue-across-${clue.number}')));
      for (final akshara in answer) {
        await _tap(tester, find.byKey(ValueKey('akshara-$akshara')));
      }
      for (final (position, cell) in path.indexed) {
        expect(
          tester
              .widget<Text>(find.byKey(ValueKey('crossword-cell-value-$cell')))
              .data,
          answer[position],
        );
      }
      expect(
        tester
            .widget<ListTile>(
              find.byKey(ValueKey('clue-across-${clue.number}')),
            )
            .selected,
        isTrue,
      );
      await _tap(tester, find.byKey(ValueKey('crossword-cell-${path.first}')));
      final wrongAnswer = puzzle.rows
          .expand((row) => row)
          .firstWhere((value) => value != '#' && value != answer.first);
      await _tap(tester, find.byKey(ValueKey('akshara-$wrongAnswer')));
      expect(
        tester
            .widget<Text>(
              find.byKey(ValueKey('crossword-cell-value-${path.first}')),
            )
            .data,
        wrongAnswer,
      );
      await _tap(tester, find.byKey(ValueKey('crossword-cell-${path.first}')));
      await _tap(tester, find.byKey(ValueKey('akshara-${answer.first}')));
      final down = puzzle.downClues.firstWhere(
        (c) => puzzle.cellsForClue(c, PuzzleDirection.down).any(path.contains),
      );
      final shared = puzzle
          .cellsForClue(down, PuzzleDirection.down)
          .firstWhere(path.contains);
      await _tap(tester, find.byKey(ValueKey('crossword-cell-$shared')));
      await _tap(tester, find.text('నిలువు (Down)'));
      expect(
        tester
            .widget<Text>(find.byKey(ValueKey('crossword-cell-value-$shared')))
            .data,
        puzzle.answerAt(shared ~/ puzzle.gridSize, shared % puzzle.gridSize),
      );
      await _tap(tester, find.byKey(ValueKey('crossword-cell-$shared')));
      await _tap(tester, find.byKey(const ValueKey('classic-clear-cell')));
      expect(
        tester
            .widget<Text>(find.byKey(ValueKey('crossword-cell-value-$shared')))
            .data,
        '',
      );
      expect(
        tester
            .widget<Text>(find.byKey(ValueKey('crossword-cell-value-$shared')))
            .data,
        '',
      );
      await _tap(tester, find.byKey(const ValueKey('open-hints')));
      await _tap(tester, find.byKey(const ValueKey('hint-reveal-cell')));
      expect(
        tester
            .widget<Text>(find.byKey(ValueKey('crossword-cell-value-$shared')))
            .data,
        puzzle.answerAt(shared ~/ puzzle.gridSize, shared % puzzle.gridSize),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('large-text grid remains editable without a duplicate preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final puzzle = _puzzles.firstWhere((p) => p.id == 9);
    await _open(
      tester,
      level: 'Hard',
      puzzles: [puzzle],
      systemScale: 3.2,
      dark: true,
    );
    final cell = puzzle
        .cellsForClue(puzzle.acrossClues.first, PuzzleDirection.across)
        .first;
    final button = find.byKey(ValueKey('crossword-cell-$cell'));
    await _tap(tester, button);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
    await _tap(
      tester,
      find.byKey(
        ValueKey(
          'akshara-${puzzle.answerAt(cell ~/ puzzle.gridSize, cell % puzzle.gridSize)}',
        ),
      ),
    );
    expect(
      tester
          .widget<Text>(find.byKey(ValueKey('crossword-cell-value-$cell')))
          .data,
      puzzle.answerAt(cell ~/ puzzle.gridSize, cell % puzzle.gridSize),
    );
    expect(tester.takeException(), isNull);
  });

  for (final (width, scale) in [
    (320.0, 1.0),
    (390.0, 1.0),
    (320.0, 1.4),
    (390.0, 1.4),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('edit controls fit $width at app scale $scale, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _open(tester, appScale: scale, dark: dark, navigationHeight: 88);
        final sizes = <Size>[];
        for (final (key, english) in [
          ('classic-clear-cell', 'Clear letter'),
          ('classic-backspace', 'Backspace'),
        ]) {
          final finder = find.byKey(ValueKey(key));
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          expect(finder.hitTestable(), findsOneWidget);
          final rect = tester.getRect(finder);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(568 - 88));
          expect(rect.height, greaterThanOrEqualTo(48));
          final label = tester.getRect(
            find.descendant(of: finder, matching: find.text(english)),
          );
          expect(label.left, greaterThanOrEqualTo(rect.left));
          expect(label.right, lessThanOrEqualTo(rect.right));
          sizes.add(rect.size);
        }
        for (final size in sizes.skip(1)) {
          expect(size.width, closeTo(sizes.first.width, 0.01));
          if (scale == 1) {
            expect(size.height, closeTo(sizes.first.height, 0.01));
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final reducedMotion in [false, true]) {
    testWidgets('edit press feedback respects reduced motion=$reducedMotion', (
      tester,
    ) async {
      await _open(tester, disableAnimations: reducedMotion);
      final button = find.byKey(const ValueKey('classic-backspace'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      final feedback = find.ancestor(
        of: button,
        matching: find.byType(TapFeedback),
      );
      final transform = find
          .descendant(of: feedback, matching: find.byType(Transform))
          .first;
      double scale() =>
          tester.widget<Transform>(transform).transform.storage.first;
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(scale(), reducedMotion ? equals(1) : lessThan(1));
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(scale(), 1);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('short 320x568 phone keeps input and reset reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _open(tester, navigationHeight: 88);
    await _tap(tester, find.byKey(const ValueKey('akshara-ఆ')));
    await _tap(tester, find.byKey(const ValueKey('classic-backspace')));
    await _menu(tester, 'classic-reset');
    await tester.pumpAndSettle();
    expect(find.text('మళ్లీ ఆడాలా?\nRestart this puzzle?'), findsOneWidget);
    expect(
      find.textContaining('Your answers and hint count will be cleared.'),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('classic-reset-confirm')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('నింపిన గడులు: 0%'), findsOneWidget);
  });

  for (final (width, appScale, systemScale) in [
    (320.0, 1.0, 1.0),
    (390.0, 1.0, 1.0),
    (800.0, 1.0, 1.0),
    (1280.0, 1.0, 1.0),
    (390.0, 1.2, 1.0),
    (320.0, 1.4, 3.2),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'Classic and hints fit $width app=$appScale system=$systemScale dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await _open(
            tester,
            appScale: appScale,
            systemScale: systemScale,
            dark: dark,
          );
          for (final (key, label) in [
            ('open-hints', 'సహాయం\nHints'),
            ('classic-more', 'చర్యలు\nActions'),
          ]) {
            final finder = find.byKey(ValueKey(key));
            expect(finder.hitTestable(), findsOneWidget);
            final bounds = tester.getRect(finder);
            expect(bounds.width, greaterThanOrEqualTo(48));
            expect(bounds.height, greaterThanOrEqualTo(48));
            expect(bounds.left, greaterThanOrEqualTo(0));
            expect(bounds.right, lessThanOrEqualTo(width));
            final textFinder = find.descendant(
              of: finder,
              matching: find.text(label),
            );
            final textBounds = tester.getRect(textFinder);
            expect(textBounds.left, greaterThanOrEqualTo(bounds.left));
            expect(textBounds.right, lessThanOrEqualTo(bounds.right));
            expect(textBounds.top, greaterThanOrEqualTo(bounds.top));
            expect(textBounds.bottom, lessThanOrEqualTo(bounds.bottom));
            final button = tester.widget<FilledButton>(finder);
            final background = button.style!.backgroundColor!.resolve({})!;
            final foreground = tester.widget<Text>(textFinder).style!.color!;
            final luminances = [
              background.computeLuminance(),
              foreground.computeLuminance(),
            ]..sort();
            expect(
              (luminances.last + 0.05) / (luminances.first + 0.05),
              greaterThanOrEqualTo(4.5),
            );
          }
          expect(
            find.byKey(const ValueKey('classic-puzzle-1')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Hints'));
          await tester.pumpAndSettle();
          expect(find.text('సహాయం (Hints)'), findsOneWidget);
          expect(
            find.textContaining('Reveal next missing letter'),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('hint-basic')), findsOneWidget);
          expect(tester.takeException(), isNull);
          await _tap(tester, find.text('మొదటి అక్షరం చూపించు'));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('classic-hints-scroll')),
            findsNothing,
          );
          expect(
            tester
                .widget<Text>(
                  find.byKey(const ValueKey('crossword-cell-value-0')),
                )
                .data,
            'ఆ',
          );
          await tester.pump(const Duration(milliseconds: 1500));
          expect(
            find.byKey(const ValueKey('classic-puzzle-1')),
            findsOneWidget,
          );
          expect(find.byType(Dialog), findsNothing);
          await _menu(tester, 'classic-reset');
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('classic-reset-confirm')),
            findsOneWidget,
          );
          for (final key in ['classic-reset-cancel', 'classic-reset-confirm']) {
            final action = find.byKey(ValueKey(key));
            await tester.ensureVisible(action);
            await tester.pumpAndSettle();
            expect(action.hitTestable(), findsOneWidget);
            final bounds = tester.getRect(action);
            expect(bounds.width, greaterThanOrEqualTo(48));
            expect(bounds.height, greaterThanOrEqualTo(48));
            for (final label in tester.widgetList<Text>(
              find.descendant(of: action, matching: find.byType(Text)),
            )) {
              final labelBounds = tester.getRect(find.byWidget(label));
              expect(labelBounds.left, greaterThanOrEqualTo(bounds.left));
              expect(labelBounds.right, lessThanOrEqualTo(bounds.right));
              expect(labelBounds.top, greaterThanOrEqualTo(bounds.top));
              expect(labelBounds.bottom, lessThanOrEqualTo(bounds.bottom));
            }
          }
          expect(tester.takeException(), isNull);
          await _tap(
            tester,
            find.byKey(const ValueKey('classic-reset-cancel')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  for (final dark in [false, true]) {
    testWidgets(
      'blocked cells have subtle decorative stars and remain non-playable dark=$dark',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await _open(tester, dark: dark);
          final selected = tester.getTopLeft(
            find.byKey(const ValueKey('selected-cell')),
          );
          final puzzle = _puzzles.first;
          for (var row = 0; row < puzzle.gridSize; row++) {
            for (var column = 0; column < puzzle.gridSize; column++) {
              if (!puzzle.isBlocked(row, column)) continue;
              final index = row * puzzle.gridSize + column;
              final cell = find.byKey(
                ValueKey('crossword-blocked-cell-$index'),
              );
              if (column == 2) {
                expect(cell, findsNothing);
                continue;
              }
              final decoration =
                  tester.widget<Container>(cell).decoration! as BoxDecoration;
              expect(
                decoration.color,
                dark ? const Color(0xFF24243D) : const Color(0xFFEDE8F7),
              );
              final motif = find.byKey(ValueKey('blocked-cell-motif-$index'));
              expect(motif, findsOneWidget);
              final star = tester.widget<Icon>(motif);
              expect(star.icon, Icons.star_rounded);
              expect(star.size, lessThanOrEqualTo(24));
              expect(star.color!.a, lessThanOrEqualTo(0.5));
              expect(tester.getCenter(motif), tester.getCenter(cell));
              expect(
                tester.widget<Container>(cell).child,
                isA<ExcludeSemantics>(),
              );
              expect(
                find.bySemanticsLabel(
                  RegExp('వరుస ${row + 1}, నిలువు ${column + 1}'),
                ),
                findsNothing,
              );
              await tester.tapAt(tester.getCenter(cell));
              await tester.pump();
              expect(
                tester.getTopLeft(find.byKey(const ValueKey('selected-cell'))),
                selected,
              );
            }
          }
          expect(
            tester
                .widget<Text>(
                  find.byKey(const ValueKey('crossword-cell-value-0')),
                )
                .data,
            '',
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  for (final (index, level) in Puzzle.levels.indexed) {
    testWidgets(
      '$level completion offers explicit next, replay and level choice',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final enlarged = level == 'medium';
        final puzzles = Puzzle.levels.reversed.map(_singleCellPuzzle).toList();
        await _open(
          tester,
          level: '${level[0].toUpperCase()}${level.substring(1)}',
          puzzles: puzzles,
          systemScale: enlarged ? 3.2 : 1,
          appScale: enlarged ? 1.4 : 1,
          dark: enlarged,
        );
        await _fill(tester, puzzles.firstWhere((p) => p.level == level));
        await tester.pump(const Duration(milliseconds: 1100));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        expect(
          find.byKey(const ValueKey('classic-level-complete')),
          findsOneWidget,
        );
        expect(find.text('Play again'), findsOneWidget);
        expect(find.text('Choose level'), findsOneWidget);
        if (index + 1 < Puzzle.levels.length) {
          expect(find.text('Next level'), findsOneWidget);
          await _tap(tester, find.text('Next level'));
          expect(
            find.byKey(ValueKey('classic-puzzle-${102 + index}')),
            findsOneWidget,
          );
          expect(find.textContaining('నింపిన గడులు: 0%'), findsOneWidget);
          expect(find.textContaining('సూచనలు: 0'), findsOneWidget);
        } else {
          expect(
            find.byKey(const ValueKey('classic-next-level')),
            findsNothing,
          );
          await _tap(tester, find.text('Play again'));
          expect(
            find.byKey(const ValueKey('classic-puzzle-105')),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'completion skips unavailable levels and can return to level choice',
    (tester) async {
      final beginner = _singleCellPuzzle('beginner');
      final expert = _singleCellPuzzle('expert');
      await _open(tester, puzzles: [expert, beginner]);
      await _fill(tester, beginner);
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('Next level'));
      expect(find.byKey(const ValueKey('classic-puzzle-105')), findsOneWidget);
      await _fill(tester, expert);
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();
      expect(find.text('Next level'), findsNothing);
      await _tap(tester, find.text('Choose level'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('difficulty-Beginner')), findsOneWidget);
      expect(find.byKey(const ValueKey('difficulty-Expert')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('classic-level-complete')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final level in ['Beginner', 'Easy']) {
    testWidgets(
      '$level waits for Next through three puzzles, completes and replays',
      (tester) async {
        await _open(tester, level: level);
        final puzzles = _puzzles
            .where((p) => p.level == level.toLowerCase())
            .toList();
        for (var index = 0; index < puzzles.length; index++) {
          final puzzle = puzzles[index];
          expect(
            find.byKey(ValueKey('classic-puzzle-${puzzle.id}')),
            findsOneWidget,
          );
          await _fill(tester, puzzle);
          expect(find.byType(Dialog), findsOneWidget);
          await tester.pump(const Duration(milliseconds: 1100));
          await tester.pumpAndSettle();
          if (index + 1 < puzzles.length) {
            expect(
              find.byKey(ValueKey('classic-puzzle-${puzzle.id}')),
              findsOneWidget,
            );
            await _tap(
              tester,
              find.byKey(const ValueKey('classic-next-puzzle')),
            );
            await tester.pumpAndSettle();
            expect(
              find.byKey(ValueKey('classic-puzzle-${puzzles[index + 1].id}')),
              findsOneWidget,
            );
            expect(
              tester
                  .widget<Text>(
                    find.byKey(const ValueKey('classic-puzzle-progress')),
                  )
                  .data,
              'పదకేళి · ${index + 2} / 3',
            );
            expect(
              tester
                  .widget<Text>(
                    find.byKey(const ValueKey('crossword-cell-value-0')),
                  )
                  .data,
              '',
            );
            expect(
              tester
                  .widget<CrosswordGrid>(find.byType(CrosswordGrid))
                  .correctCells,
              isEmpty,
            );
            expect(find.text('అద్భుతం! సమాధానం సరైనది.'), findsNothing);
            await tester.pump(const Duration(seconds: 2));
            expect(
              find.byKey(ValueKey('classic-puzzle-${puzzles[index + 1].id}')),
              findsOneWidget,
            );
          }
        }
        expect(
          find.byKey(const ValueKey('classic-level-complete')),
          findsOneWidget,
        );
        await _tap(tester, find.byKey(const ValueKey('classic-replay')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('classic-puzzle-${puzzles.last.id}')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(
                  ValueKey(
                    'crossword-cell-value-${puzzles.last.cellsForClue(puzzles.last.acrossClues.first, PuzzleDirection.across).first}',
                  ),
                ),
              )
              .data,
          '',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final (width, height, appScale, systemScale) in [
    (320.0, 568.0, 1.0, 1.0),
    (800.0, 844.0, 1.0, 1.0),
    (320.0, 568.0, 1.4, 3.2),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'completion actions fit $width x $height app=$appScale system=$systemScale dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await _open(
            tester,
            appScale: appScale,
            systemScale: systemScale,
            dark: dark,
          );
          await _fill(tester, _puzzles.first);
          await tester.pumpAndSettle();
          for (final key in [
            'classic-next-puzzle',
            'classic-replay',
            'classic-choose-level',
            'classic-completion-home',
          ]) {
            final finder = find.byKey(ValueKey(key));
            await tester.ensureVisible(finder);
            await tester.pumpAndSettle();
            expect(finder.hitTestable(), findsOneWidget);
            final bounds = tester.getRect(finder);
            expect(bounds.width, greaterThanOrEqualTo(48));
            expect(bounds.height, greaterThanOrEqualTo(48));
            expect(bounds.left, greaterThanOrEqualTo(0));
            expect(bounds.right, lessThanOrEqualTo(width));
            for (final label in tester.widgetList<Text>(
              find.descendant(of: finder, matching: find.byType(Text)),
            )) {
              final labelBounds = tester.getRect(find.byWidget(label));
              expect(labelBounds.left, greaterThanOrEqualTo(bounds.left));
              expect(labelBounds.right, lessThanOrEqualTo(bounds.right));
              expect(labelBounds.top, greaterThanOrEqualTo(bounds.top));
              expect(labelBounds.bottom, lessThanOrEqualTo(bounds.bottom));
            }
            if (key != 'classic-completion-home') {
              final button = tester.widget<FilledButton>(finder);
              final luminances = [
                button.style!.foregroundColor!.resolve({})!.computeLuminance(),
                button.style!.backgroundColor!.resolve({})!.computeLuminance(),
              ]..sort();
              expect(
                (luminances.last + 0.05) / (luminances.first + 0.05),
                greaterThanOrEqualTo(4.5),
              );
            }
          }
          expect(tester.takeException(), isNull);
          await _tap(tester, find.byKey(const ValueKey('classic-replay')));
          await tester.pumpAndSettle();
          expect(find.byType(Dialog), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final action in ['Replay', 'Choose level', 'Dispose']) {
    testWidgets('$action after completion never advances automatically', (
      tester,
    ) async {
      await _open(tester);
      await _fill(tester, _puzzles.first);
      if (action == 'Replay') {
        await _tap(tester, find.byKey(const ValueKey('classic-replay')));
      } else if (action == 'Choose level') {
        await _tap(tester, find.byKey(const ValueKey('classic-choose-level')));
      } else {
        await tester.pumpWidget(const SizedBox.shrink());
      }
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      if (action == 'Replay') {
        expect(find.byKey(const ValueKey('classic-puzzle-1')), findsOneWidget);
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('crossword-cell-value-0')),
              )
              .data,
          '',
        );
      } else if (action == 'Choose level') {
        expect(
          find.byKey(const ValueKey('difficulty-Beginner')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('classic-puzzle-3')), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'canonical Telugu input checks correctly and absent/simple and solved hints stay disabled',
    (tester) async {
      const puzzle = Puzzle(
        id: 8,
        level: 'beginner',
        gridSize: 1,
        rows: [
          ['క\u0c46\u0c56'],
        ],
        acrossClues: [
          PuzzleClue(
            number: 1,
            clue: 'పరీక్ష',
            answer: 'కై',
            row: 0,
            column: 0,
          ),
        ],
        downClues: [],
      );
      await _open(tester, puzzles: [puzzle]);
      await _tap(tester, find.byKey(const ValueKey('open-hints')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ListTile>(find.byKey(const ValueKey('hint-basic'))).onTap,
        isNull,
      );
      await tester.tap(find.byTooltip('Close hints'));
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('akshara-కై')));
      expect(
        tester.widget<CrosswordGrid>(find.byType(CrosswordGrid)).correctCells,
        {0},
      );
      expect(
        find.byKey(const ValueKey('clue-correct-across-1')),
        findsOneWidget,
      );
      expect(find.textContaining('సూచనలు: 0'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(
        find.byKey(const ValueKey('classic-level-complete')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'intersection toggles direction, input advances, clear and backspace work',
    (tester) async {
      await _open(tester);
      await _tap(tester, find.byKey(const ValueKey('crossword-cell-0')));
      expect(
        tester
            .widget<ListTile>(find.byKey(const ValueKey('clue-down-1')))
            .selected,
        isTrue,
      );
      await _tap(tester, find.byKey(const ValueKey('akshara-ఆ')));
      expect(
        tester.getCenter(find.byKey(const ValueKey('selected-cell'))),
        tester.getCenter(find.byKey(const ValueKey('crossword-cell-3'))),
      );
      await _tap(tester, find.byKey(const ValueKey('classic-backspace')));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-0')))
            .data,
        '',
      );
      await _tap(tester, find.byKey(const ValueKey('akshara-ఆ')));
      await _tap(tester, find.byKey(const ValueKey('akshara-కా')));
      await _tap(tester, find.byKey(const ValueKey('classic-clear-cell')));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-3')))
            .data,
        'కా',
      );
      await _tap(tester, find.byKey(const ValueKey('classic-backspace')));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-3')))
            .data,
        '',
      );
    },
  );

  testWidgets(
    'hints reveal only unsolved cells, share intersections and count actual use',
    (tester) async {
      await _open(tester);
      Future<void> hint(String key) async {
        await _tap(tester, find.byKey(const ValueKey('open-hints')));
        await tester.pumpAndSettle();
        await _tap(tester, find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
      }

      await hint('hint-reveal-first');
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-0')))
            .data,
        'ఆ',
      );
      await hint('hint-reveal-first');
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-1')))
            .data,
        'ట',
      );
      await _tap(tester, find.text('నిలువు (Down)'));
      await hint('hint-reveal-cell');
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-3')))
            .data,
        'కా',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-6')))
            .data,
        '',
      );
      await hint('hint-basic');
      expect(find.text('మేఘాలు ఉండే చోటు'), findsOneWidget);
      expect(find.textContaining('సూచనలు: 4'), findsOneWidget);
      await _menu(tester, 'classic-reset-word');
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-0')))
            .data,
        '',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-1')))
            .data,
        'ట',
      );
    },
  );

  testWidgets(
    'wrong cells have explicit feedback and full reset needs confirmation',
    (tester) async {
      await _open(tester);
      await _tap(tester, find.byKey(const ValueKey('akshara-ట')));
      expect(find.byKey(const ValueKey('crossword-error-0')), findsNothing);
      await _tap(tester, find.byKey(const ValueKey('akshara-ట')));
      expect(find.byKey(const ValueKey('crossword-error-0')), findsOneWidget);
      expect(find.textContaining('40%'), findsOneWidget);
      await _menu(tester, 'classic-reset');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('classic-reset-cancel')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-0')))
            .data,
        'ట',
      );
      await _menu(tester, 'classic-reset');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('classic-reset-confirm')));
      await tester.pumpAndSettle();
      expect(find.textContaining('0%'), findsOneWidget);
      expect(find.byKey(const ValueKey('crossword-error-0')), findsNothing);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-0')))
            .data,
        '',
      );
    },
  );

  testWidgets('rapid Next after automatic completion does not skip a puzzle', (
    tester,
  ) async {
    final first = _singleCellPuzzle('beginner');
    final second = Puzzle(
      id: 501,
      level: first.level,
      gridSize: first.gridSize,
      rows: first.rows,
      acrossClues: first.acrossClues,
      downClues: first.downClues,
    );
    await _open(tester, puzzles: [first, second]);
    await _tap(tester, find.byKey(const ValueKey('akshara-క')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    final next = tester
        .widget<FilledButton>(find.byKey(const ValueKey('classic-next-puzzle')))
        .onPressed!;
    next();
    next();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('classic-puzzle-501')), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(find.textContaining('నింపిన గడులు: 0%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a filled incorrect board never succeeds until its wrong answer is corrected',
    (tester) async {
      final puzzle = _puzzles.first;
      await _open(tester);
      for (var index = 0; index < puzzle.gridSize * puzzle.gridSize; index++) {
        if (puzzle.isBlocked(
          index ~/ puzzle.gridSize,
          index % puzzle.gridSize,
        )) {
          continue;
        }
        await _tap(tester, find.byKey(ValueKey('crossword-cell-$index')));
        await _tap(
          tester,
          find.byKey(
            ValueKey(
              'akshara-${index == 0 ? 'ట' : puzzle.answerAt(index ~/ puzzle.gridSize, index % puzzle.gridSize)}',
            ),
          ),
        );
      }
      await tester.pumpAndSettle();
      expect(find.textContaining('నింపిన గడులు: 100%'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byKey(const ValueKey('crossword-error-0')), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(find.byKey(const ValueKey('classic-puzzle-1')), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('crossword-cell-0')));
      await _tap(tester, find.byKey(const ValueKey('akshara-ఆ')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byKey(const ValueKey('crossword-error-0')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'system Back dismisses success without losing completion or advancing',
    (tester) async {
      await _open(tester);
      await _fill(tester, _puzzles.first);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.byKey(const ValueKey('classic-level-complete')),
        findsOneWidget,
      );
      await _tap(tester, find.byKey(const ValueKey('classic-next-puzzle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('classic-puzzle-3')), findsOneWidget);
    },
  );
}
