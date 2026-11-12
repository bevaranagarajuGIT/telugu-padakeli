import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as image;
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/data/puzzle_data_source.dart';
import 'package:telugu_padakeli/screens/kids_game_screen.dart';
import 'package:telugu_padakeli/screens/padakeli_screen.dart';
import 'package:telugu_padakeli/services/kids_question_service.dart';
import 'package:telugu_padakeli/services/kids_learning_service.dart';
import 'package:telugu_padakeli/services/local_puzzle_repository.dart';
import 'package:telugu_padakeli/models/telugu_akshara.dart';
import 'package:telugu_padakeli/models/kids_question.dart';

class _StringSource implements PuzzleDataSource {
  _StringSource(this.value);
  final String value;
  @override
  Future<String> loadPuzzlesJson() async => value;
}

class _RetrySource implements PuzzleDataSource {
  int attempts = 0;
  @override
  Future<String> loadPuzzlesJson() async {
    if (attempts++ == 0) throw StateError('Asset unavailable');
    return rootBundle.loadString('assets/data/sample_puzzles.json');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'editable content inventory covers the authored pack without claiming human review',
    () async {
      final inventory =
          jsonDecode(
                await rootBundle.loadString('assets/data/content_review.json'),
              )
              as Map<String, dynamic>;
      final rows = (inventory['items'] as List).cast<Map<String, dynamic>>();
      final indexed = {for (final row in rows) row['id']: row};
      var expected = 0;
      for (final activity in const KidsLearningService().getActivities()) {
        for (final question in activity.questions) {
          final row = indexed['kids:${activity.id}:${question.id}']!;
          expect(row['prompt'], question.prompt);
          expect(row['answer'], question.answer);
          expect(row['picture'], question.imageAsset);
          expect(row['pictureDescription'], question.imageDescription);
          expect(row['audio'], isNull);
          expect(
            row['englishHelper']['explanation'],
            question.englishExplanation,
          );
          expected++;
        }
      }
      for (final level in const KidsQuestionService().getLevels()) {
        for (final question in level.questions) {
          final row = indexed['practice:${level.name}:${question.prompt}']!;
          expect(row['answer'], question.answer);
          expect(row['recordingScript'], question.completedWord);
          expect(row['englishHelper'], question.englishHint);
          expected++;
        }
      }
      for (final puzzle in await const LocalPuzzleRepository().getPuzzles()) {
        for (final (direction, clues) in [
          ('across', puzzle.acrossClues),
          ('down', puzzle.downClues),
        ]) {
          for (final clue in clues) {
            final row =
                indexed['classic:${puzzle.id}:$direction:${clue.number}']!;
            expect(row['prompt'], clue.clue);
            expect(row['answer'], clue.answer);
            expect(row['explanation'], clue.hint);
            expected++;
          }
        }
      }
      expect(rows.length, expected);
      expect(indexed.length, expected);
      expect(
        rows.every((row) => row['reviewStatus'] == 'pending-human-review'),
        isTrue,
      );
      expect(inventory['repeatedVocabulary'], isNotEmpty);
    },
  );

  test(
    'original vocabulary art has consistent dimensions and transparent safe margins',
    () async {
      for (final name in [
        'mango',
        'parrot',
        'book',
        'banana',
        'lotus',
        'cat',
        'fish',
        'pencil',
        'elephant',
      ]) {
        final data = await rootBundle.load('assets/artwork/kids/$name.png');
        final decoded = image.decodePng(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        )!;
        expect((decoded.width, decoded.height), (512, 512), reason: name);
        var painted = 0;
        for (final pixel in decoded) {
          if (pixel.a == 0) continue;
          painted++;
          expect(
            pixel.x >= 36 && pixel.y >= 36 && pixel.x < 476 && pixel.y < 476,
            isTrue,
            reason: '$name safe margin',
          );
        }
        expect(
          painted,
          greaterThan(10000),
          reason: '$name identifiable object',
        );
      }
    },
  );

  test(
    'all bundled puzzles validate and every answer matches its cells',
    () async {
      final puzzles = await const LocalPuzzleRepository().getPuzzles();
      expect(puzzles.map((p) => p.id), List.generate(12, (i) => i + 1));
      expect(puzzles.where((p) => p.level == 'beginner'), hasLength(3));
      expect(puzzles.where((p) => p.level == 'easy'), hasLength(3));
      for (final (level, count) in [
        ('medium', 5),
        ('hard', 7),
        ('expert', 10),
      ]) {
        final boards = puzzles.where((p) => p.level == level);
        expect(boards, hasLength(2));
        for (final board in boards) {
          expect(board.acrossClues.length + board.downClues.length, count);
        }
      }
      for (final puzzle in puzzles) {
        expect(puzzle.validate, returnsNormally);
      }
    },
  );

  for (final invalid in ['[]', '{', '[{}]']) {
    test('invalid or empty puzzle JSON is rejected: $invalid', () async {
      final repository = LocalPuzzleRepository(
        dataSource: _StringSource(invalid),
      );
      await expectLater(repository.getPuzzles(), throwsA(isA<Exception>()));
    });
  }

  test(
    'larger crosswords reduce internal empty areas, not just decoration',
    () async {
      final puzzles = await const LocalPuzzleRepository().getPuzzles();
      const previousBlockedCells = {
        7: 14,
        8: 16,
        9: 17,
        10: 29,
        11: 26,
        12: 45,
      };
      for (final puzzle in puzzles.where((puzzle) => puzzle.id >= 7)) {
        final occupiedRows = [
          for (var row = 0; row < puzzle.gridSize; row++)
            if (puzzle.rows[row].any((cell) => cell != '#')) row,
        ];
        final occupiedColumns = [
          for (var column = 0; column < puzzle.gridSize; column++)
            if (puzzle.rows.any((row) => row[column] != '#')) column,
        ];
        final height = occupiedRows.last - occupiedRows.first + 1;
        final width = occupiedColumns.last - occupiedColumns.first + 1;
        final playable = puzzle.rows
            .expand((row) => row)
            .where((cell) => cell != '#')
            .length;
        final area = height * width;
        final reason = 'Board ${puzzle.id} must not regain large empty areas';
        expect(width, lessThanOrEqualTo(6), reason: reason);
        expect(height, lessThanOrEqualTo(6), reason: reason);
        expect(playable / area, greaterThanOrEqualTo(0.55), reason: reason);
        expect(
          area - playable,
          lessThanOrEqualTo((previousBlockedCells[puzzle.id]! * 0.6).floor()),
          reason: 'Board ${puzzle.id} needs at least 40% fewer blocked cells',
        );
        var largestGap = 0;
        for (var top = occupiedRows.first; top <= occupiedRows.last; top++) {
          final counts = List.filled(width, 0);
          for (var bottom = top; bottom <= occupiedRows.last; bottom++) {
            var run = 0;
            for (var column = 0; column < width; column++) {
              if (!puzzle.isBlocked(bottom, occupiedColumns.first + column)) {
                counts[column]++;
              }
              run = counts[column] == 0 ? run + 1 : 0;
              final gap = run * (bottom - top + 1);
              if (gap > largestGap) largestGap = gap;
            }
          }
        }
        expect(largestGap, lessThanOrEqualTo(6), reason: reason);
      }
    },
  );

  test(
    'sample content remains pending human review without duplicate answers',
    () async {
      final raw =
          jsonDecode(
                await rootBundle.loadString('assets/data/sample_puzzles.json'),
              )
              as List<dynamic>;
      expect(
        raw.every(
          (dynamic item) =>
              (item as Map<String, dynamic>)['reviewStatus'] ==
              'pending-human-review',
        ),
        isTrue,
      );
      final puzzles = await const LocalPuzzleRepository().getPuzzles();
      final answers = puzzles
          .expand((p) => [...p.acrossClues, ...p.downClues])
          .map((clue) => TeluguAkshara.normalize(clue.answer))
          .toList();
      expect(answers, hasLength(57));
      expect(answers.toSet(), hasLength(answers.length));
    },
  );

  for (final corruption in [
    'dimensions',
    'unclued',
    'mark',
    'answer',
    'number',
  ]) {
    test('rejects puzzle with invalid $corruption', () async {
      final raw = await rootBundle.loadString(
        'assets/data/sample_puzzles.json',
      );
      final data = jsonDecode(raw) as List<dynamic>;
      final puzzle = data.first as Map<String, dynamic>;
      final rows = puzzle['rows'] as List<dynamic>;
      final clues = puzzle['clues'] as Map<String, dynamic>;
      final across = clues['across'] as List<dynamic>;
      switch (corruption) {
        case 'dimensions':
          puzzle['gridSize'] = 4;
        case 'unclued':
          (rows[2] as List<dynamic>)[2] = 'క';
        case 'mark':
          (rows[1] as List<dynamic>)[0] = 'ి';
        case 'answer':
          (across.first as Map<String, dynamic>)['answer'] = 'తప్పు';
        case 'number':
          (across.last as Map<String, dynamic>)['number'] = 1;
      }
      final repository = LocalPuzzleRepository(
        dataSource: _StringSource(jsonEncode(data)),
      );
      await expectLater(repository.getPuzzles(), throwsFormatException);
    });
  }

  test('kids prompts reconstruct the intended Telugu words', () {
    final levels = const KidsQuestionService().getLevels();
    final originals = levels
        .take(5)
        .expand((l) => l.questions.take(3))
        .toList();
    const words = [
      'కమలం',
      'అమ్మ',
      'పాఠశాల',
      'ఆకు',
      'పూలు',
      'గోరు',
      'మామిడి',
      'పశువు',
      'చెట్టు',
      'పర్యావరణం',
      'స్వాతంత్ర్యం',
      'నైపుణ్యం',
      'సామాజికం',
      'విద్యార్థి',
      'సామర్థ్యం',
    ];
    expect(originals.map((q) => q.completedWord), words);
    expect(levels.map((l) => l.questions.length), [5, 5, 7, 7, 10, 10, 10]);
    final questions = levels.expand((l) => l.questions).toList();
    expect(questions, hasLength(54));
    expect(questions.map((q) => q.completedWord).toSet(), hasLength(54));
    for (final question in questions) {
      expect('_'.allMatches(question.prompt).length, 1);
      expect(question.validate, returnsNormally);
      expect(question.hint, isNotEmpty);
      expect(question.englishHint, isNotEmpty);
      expect(question.options.toSet().length, question.options.length);
      expect(question.options.where((o) => o == question.answer).length, 1);
    }
  });

  testWidgets('failed puzzle load shows Retry and recovers', (tester) async {
    final source = _RetrySource();
    await tester.pumpWidget(
      MaterialApp(
        home: PadakeliScreen(
          repository: LocalPuzzleRepository(dataSource: source),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('puzzle-load-error')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('retry-puzzles')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('difficulty-Beginner')), findsOneWidget);
    expect(find.byKey(const ValueKey('puzzle-load-error')), findsNothing);
    expect(source.attempts, 2);
    expect(tester.takeException(), isNull);
  });

  test(
    'original practice rejects broken boundaries, ambiguous options and missing helpers',
    () {
      for (final question in [
        const KidsQuestion(
          prompt: 'అమ్_',
          answer: 'మ',
          hint: 'తల్లి',
          englishHint: 'Mother.',
          options: ['మ', 'క', 'ల'],
        ),
        const KidsQuestion(
          prompt: 'అ_',
          answer: 'మ్మ',
          hint: 'తల్లి',
          englishHint: 'Mother.',
          options: ['మ్మ', 'మ్మ', 'ల్ల'],
        ),
        const KidsQuestion(
          prompt: 'అ_',
          answer: 'మ్మ',
          hint: 'తల్లి',
          englishHint: '',
          options: ['మ్మ', 'న్న', 'ల్ల'],
        ),
        const KidsQuestion(
          prompt: 'అ__',
          answer: 'మ్మ',
          hint: 'తల్లి',
          englishHint: 'Mother.',
          options: ['మ్మ', 'న్న', 'ల్ల'],
        ),
      ]) {
        expect(question.validate, throwsFormatException);
      }
    },
  );

  testWidgets(
    'invalid puzzle content shows recovery instead of an endless spinner',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PadakeliScreen(
            repository: LocalPuzzleRepository(dataSource: _StringSource('[]')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('retry-puzzles')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all seven kids levels finish with a final score and restart', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettingsController(),
        child: const MaterialApp(home: KidsGameScreen()),
      ),
    );
    final levels = const KidsQuestionService().getLevels();
    for (final level in levels) {
      for (final question in level.questions) {
        final answer = find.byKey(ValueKey('kids-answer-${question.answer}'));
        await tester.ensureVisible(answer);
        await tester.tap(answer);
        final check = find.text('సరిచూడు');
        await tester.ensureVisible(check);
        await tester.tap(check);
        await tester.pump(const Duration(milliseconds: 1200));
        await tester.pumpAndSettle();
      }
      if (level != levels.last) {
        expect(
          find.byKey(const ValueKey('legacy-level-complete-heading')),
          findsOneWidget,
        );
        expect(find.text('${level.title} పూర్తయింది!'), findsOneWidget);
        final next = find.byKey(const ValueKey('legacy-next-level'));
        expect(next.hitTestable(), findsOneWidget);
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
    }
    expect(find.text('మొత్తం స్కోరు: 54 / 54'), findsOneWidget);
    final completionScroll = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('kids-completion-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(completionScroll.position.pixels, 0);
    final viewport = tester.getRect(
      find.byKey(const ValueKey('kids-completion-scroll')),
    );
    final hanuman = tester.getRect(
      find.byKey(const ValueKey('bal-hanuman-character')),
    );
    expect(hanuman.top, greaterThanOrEqualTo(viewport.top));
    expect(hanuman.bottom, lessThanOrEqualTo(viewport.bottom));
    expect(
      find.text('అభినందనలు! అన్ని 7 స్థాయిలను పూర్తి చేశారు.'),
      findsOneWidget,
    );
    expect(find.textContaining('త్వరలో'), findsNothing);
    await tester.ensureVisible(find.text('మళ్లీ ఆడండి'));
    await tester.tap(find.text('మళ్లీ ఆడండి'));
    await tester.pumpAndSettle();
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      0,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('kids-score')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    expect(find.text('కమ_'), findsOneWidget);
  });
}
