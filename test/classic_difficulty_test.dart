import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/screens/padakeli_screen.dart';

void main() {
  testWidgets('Classic Easy sample puzzle is selectable and checkable', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PadakeliScreen()));
    for (
      var frame = 0;
      frame < 100 && find.text('స్థాయిని ఎంచుకోండి').evaluate().isEmpty;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();

    expect(find.byKey(const ValueKey('difficulty-Beginner')), findsOneWidget);
    expect(find.byKey(const ValueKey('difficulty-Easy')), findsOneWidget);
    expect(find.text('Coming Soon'), findsNWidgets(3));
    final easyDifficulty = find.byKey(const ValueKey('difficulty-Easy'));
    await tester.ensureVisible(easyDifficulty);
    await tester.tap(easyDifficulty);
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('selected-clue'))).data,
      '1. జరిగిన లేదా ఊహించిన సంఘటనల వర్ణన',
    );

    for (final entry in {0: 'క', 1: 'థ', 3: 'లం'}.entries) {
      final cell = find.byKey(ValueKey('crossword-cell-${entry.key}'));
      await tester.ensureVisible(cell);
      await tester.tap(cell);
      final akshara = find.byKey(ValueKey('akshara-${entry.value}'));
      await tester.ensureVisible(akshara);
      await tester.tap(akshara);
    }
    await tester.ensureVisible(find.byKey(const ValueKey('classic-check')));
    await tester.tap(find.byKey(const ValueKey('classic-check')));
    await tester.pumpAndSettle();
    expect(find.text('అద్భుతం! సమాధానం సరైనది.'), findsOneWidget);
    await tester.tap(find.byTooltip('Change difficulty'));
    await tester.pumpAndSettle();
    final beginnerDifficulty = find.byKey(
      const ValueKey('difficulty-Beginner'),
    );
    await tester.ensureVisible(beginnerDifficulty);
    await tester.tap(beginnerDifficulty);
    await tester.pump();
    expect(find.byKey(const ValueKey('selected-cell')), findsOneWidget);

    final ka = find.byKey(const ValueKey('akshara-ఆ'));
    await tester.ensureVisible(ka);
    await tester.tap(ka);
    await tester.pump();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-0')))
          .data,
      'ఆ',
    );
    final ma = find.byKey(const ValueKey('akshara-ట'));
    await tester.ensureVisible(ma);
    await tester.tap(ma);
    await tester.pump();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-0')))
          .data,
      'ఆ',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-1')))
          .data,
      'ట',
    );

    await tester.ensureVisible(find.byKey(const ValueKey('open-hints')));
    await tester.tap(find.byKey(const ValueKey('open-hints')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hint-basic')));
    await tester.pumpAndSettle();
    expect(find.text('పిల్లలు కలిసి ఆడేది'), findsOneWidget);
    await tester.ensureVisible(find.text('నిలువు (Down)'));
    await tester.tap(find.text('నిలువు (Down)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('open-hints')));
    await tester.tap(find.byKey(const ValueKey('open-hints')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hint-reveal-first')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-0')))
          .data,
      'ఆ',
    );

    await tester.ensureVisible(find.byKey(const ValueKey('open-hints')));
    await tester.tap(find.byKey(const ValueKey('open-hints')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hint-reveal-cell')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('crossword-cell-value-6')))
          .data,
      'శం',
    );

    await tester.ensureVisible(find.text('నిలువు (Down)'));
    await tester.tap(find.text('నిలువు (Down)'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('selected-clue'))).data,
      '1. మన పైన నీలంగా కనిపించేది',
    );
    expect(
      tester
          .widget<ListTile>(find.byKey(const ValueKey('clue-down-1')))
          .selected,
      isTrue,
    );

    await tester.ensureVisible(find.text('అడ్డం (Across)'));
    await tester.tap(find.text('అడ్డం (Across)'));
    await tester.pumpAndSettle();
    final downClueTwo = find.byKey(const ValueKey('clue-across-2'));
    await tester.ensureVisible(downClueTwo);
    await tester.tap(downClueTwo);
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('selected-clue'))).data,
      '2. ఊదితే శబ్దం చేసే సముద్రపు గుల్ల',
    );
    expect(
      find.byKey(const ValueKey('crossword-cell-container-7')),
      findsOneWidget,
    );
  });
}
