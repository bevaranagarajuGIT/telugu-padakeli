import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/models/puzzle.dart';
import 'package:telugu_padakeli/screens/padakeli_screen.dart';
import 'package:telugu_padakeli/services/local_puzzle_repository.dart';
import 'package:telugu_padakeli/services/puzzle_repository.dart';
import 'package:telugu_padakeli/widgets/premium_telugu_text.dart';

class _Repository implements PuzzleRepository {
  const _Repository(this.puzzles);
  final List<Puzzle> puzzles;

  @override
  Future<List<Puzzle>> getPuzzles() async => puzzles;

  @override
  Future<Puzzle> getBeginnerPuzzle() async => puzzles.first;
}

late List<Puzzle> _puzzles;

Future<void> _open(
  WidgetTester tester, {
  String level = 'Beginner',
  double appScale = 1,
  double systemScale = 1,
  bool dark = false,
  double navigationHeight = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark(appScale) : AppTheme.light(appScale),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(systemScale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: PadakeliScreen(repository: _Repository(_puzzles)),
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
      find.text('1. ${_puzzles.first.acrossClues.first.clue}'),
      findsOneWidget,
    );
    for (final key in ['classic-check', 'open-hints']) {
      final rect = tester.getRect(find.byKey(ValueKey(key)));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(844 - 88));
    }
    expect(tester.takeException(), isNull);
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
          expect(
            find.byKey(const ValueKey('classic-puzzle-1')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Hints'));
          await tester.pumpAndSettle();
          expect(find.text('సూచనలు (Hints)'), findsOneWidget);
          expect(find.text('పిల్లలు కలిసి ఆడేది'), findsOneWidget);
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
          await _tap(tester, find.byKey(const ValueKey('classic-check')));
          await tester.pump(const Duration(milliseconds: 1500));
          expect(
            find.byKey(const ValueKey('classic-puzzle-1')),
            findsOneWidget,
          );
          expect(find.text('ఇంకొంచెం ప్రయత్నించండి.'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  for (final dark in [false, true]) {
    testWidgets('Rangoli cells stay decorative and non-playable dark=$dark', (
      tester,
    ) async {
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
            final cell = find.byKey(ValueKey('crossword-blocked-cell-$index'));
            final decoration =
                tester.widget<Container>(cell).decoration! as BoxDecoration;
            expect(
              decoration.color,
              dark ? const Color(0xFF24243D) : const Color(0xFFEDE8F7),
            );
            expect(
              find.byKey(ValueKey('blocked-cell-motif-$index')),
              findsOneWidget,
            );
            expect(
              find.bySemanticsLabel(
                RegExp('Row ${row + 1}, column ${column + 1}'),
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
    });
  }

  for (final level in ['Beginner', 'Easy']) {
    testWidgets(
      '$level advances exactly once through three puzzles, completes and replays',
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
          await _tap(tester, find.byKey(const ValueKey('classic-check')));
          expect(find.text('అద్భుతం! సమాధానం సరైనది.'), findsOneWidget);
          expect(
            tester
                .widget<FilledButton>(
                  find.byKey(const ValueKey('classic-check')),
                )
                .onPressed,
            isNull,
          );
          await tester.tap(find.byKey(const ValueKey('classic-check')));
          await tester.pump(const Duration(milliseconds: 1100));
          await tester.pumpAndSettle();
          if (index + 1 < puzzles.length) {
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
          find.byKey(ValueKey('classic-puzzle-${puzzles.first.id}')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('crossword-cell-value-0')),
              )
              .data,
          '',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final action in ['Reset', 'Change difficulty', 'Dispose']) {
    testWidgets('$action cancels pending automatic progression', (
      tester,
    ) async {
      await _open(tester);
      await _fill(tester, _puzzles.first);
      await _tap(tester, find.byKey(const ValueKey('classic-check')));
      if (action == 'Reset') {
        await tester.tap(find.text('Reset'));
      } else if (action == 'Change difficulty') {
        await tester.tap(find.byTooltip('Change difficulty'));
      } else {
        await tester.pumpWidget(const SizedBox.shrink());
      }
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      if (action == 'Reset') {
        expect(find.byKey(const ValueKey('classic-puzzle-1')), findsOneWidget);
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('crossword-cell-value-0')),
              )
              .data,
          '',
        );
      } else if (action == 'Change difficulty') {
        expect(
          find.byKey(const ValueKey('difficulty-Beginner')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('classic-puzzle-3')), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
