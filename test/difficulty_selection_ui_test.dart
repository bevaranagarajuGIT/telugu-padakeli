import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/app/theme/app_colors.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'helpers/returning_user_app.dart';
import 'package:telugu_padakeli/widgets/difficulty_selection.dart';
import 'package:telugu_padakeli/widgets/premium_telugu_text.dart';

void main() {
  setUpAll(() async {
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
        'colourful difficulties fit $width, app=$appScale, system=$systemScale, dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          final selected = <String>[];
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
              home: DifficultySelection(
                availableLevels: const {'beginner', 'easy'},
                onSelect: selected.add,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Coming Soon'), findsNWidgets(3));
          expect(tester.takeException(), isNull);
          for (final name in ['Beginner', 'Easy', 'Medium', 'Hard', 'Expert']) {
            final card = find.byKey(ValueKey('difficulty-$name'));
            await tester.ensureVisible(find.text(name));
            await tester.pumpAndSettle();
            expect(tester.getSize(card).width, lessThanOrEqualTo(width - 32));
            expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
            final data = tester.getSemantics(card).getSemanticsData();
            final playable = name == 'Beginner' || name == 'Easy';
            expect(data.flagsCollection.isButton, isTrue);
            expect(data.hasAction(SemanticsAction.tap), playable);
            expect(data.value, playable ? 'ఆడటం ప్రారంభించండి' : 'Coming Soon');
            final decoration =
                tester
                        .widget<Ink>(
                          find.descendant(of: card, matching: find.byType(Ink)),
                        )
                        .decoration!
                    as BoxDecoration;
            final foreground = dark ? Colors.white : AppColors.ink;
            for (final color
                in (decoration.gradient! as LinearGradient).colors) {
              final light = foreground.computeLuminance();
              final surface = color.computeLuminance();
              final contrast = light > surface
                  ? (light + 0.05) / (surface + 0.05)
                  : (surface + 0.05) / (light + 0.05);
              expect(contrast, greaterThanOrEqualTo(4.5));
            }
            await tester.tap(find.text(name), warnIfMissed: playable);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          expect(selected, ['beginner', 'easy']);
          semantics.dispose();
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets('only available levels activate from the keyboard', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(1),
        home: DifficultySelection(
          availableLevels: const {'beginner', 'easy'},
          onSelect: selected.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, ['beginner', 'easy', 'beginner']);
  });

  testWidgets('a missing available puzzle stays disabled', (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: DifficultySelection(
          availableLevels: const {'beginner'},
          onSelect: selected.add,
        ),
      ),
    );
    final easy = find.byKey(const ValueKey('difficulty-Easy'));
    expect(tester.widget<Semantics>(easy).properties.enabled, isFalse);
    await tester.tap(find.text('Easy'));
    expect(selected, isEmpty);
    expect(find.text('Coming Soon'), findsNWidgets(4));
  });

  testWidgets('selector Back returns Home and Classic remains usable', (
    tester,
  ) async {
    await tester.pumpWidget(const TeluguPadakeliApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-classic')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back to Home'));
    await tester.pumpAndSettle();
    expect(find.text('Classic Padakeli'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-classic')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Easy'));
    await tester.tap(find.text('Easy'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('classic-check')), findsOneWidget);
    await tester.tap(find.byTooltip('Change difficulty'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('difficulty-Beginner')), findsOneWidget);
    expect(find.text('Coming Soon'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
