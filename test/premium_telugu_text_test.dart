import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/screens/home_screen.dart';
import 'package:telugu_padakeli/widgets/premium_telugu_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader(PremiumTeluguText.fontFamily);
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      loader.addFont(
        rootBundle.load('assets/fonts/NotoSansTelugu-$weight.ttf'),
      );
    }
    await loader.load();
    final latinLoader = FontLoader('Roboto');
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      latinLoader.addFont(rootBundle.load('assets/fonts/Roboto-$weight.ttf'));
    }
    await latinLoader.load();
  });

  test(
    'font manifest registers real regular, medium and bold assets',
    () async {
      final manifest =
          jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
      final family = manifest.cast<Map<String, dynamic>>().singleWhere(
        (entry) => entry['family'] == PremiumTeluguText.fontFamily,
      );
      final fonts = (family['fonts'] as List).cast<Map<String, dynamic>>();
      expect(fonts.map((font) => font['weight']), [400, 500, 700]);
      for (final font in fonts) {
        final bytes = await rootBundle.load(font['asset'] as String);
        expect(bytes.getUint32(0), 0x00010000);
      }
      expect(
        await rootBundle.loadString('assets/fonts/OFL.txt'),
        contains('SIL OPEN FONT LICENSE'),
      );
      final latinFamily = manifest.cast<Map<String, dynamic>>().singleWhere(
        (entry) => entry['family'] == 'Roboto',
      );
      final latinFonts = (latinFamily['fonts'] as List)
          .cast<Map<String, dynamic>>();
      expect(latinFonts.map((font) => font['weight']), [400, 500, 700]);
      for (final font in latinFonts) {
        final bytes = await rootBundle.load(font['asset'] as String);
        expect(bytes.getUint32(0), 0x00010000);
      }
      expect(
        await rootBundle.loadString('assets/fonts/Roboto-LICENSE.txt'),
        contains('Apache License'),
      );
    },
  );

  for (final scale in [1.0, 2.0, 3.2]) {
    testWidgets('Telugu conjuncts wrap without truncation at ${scale}x', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(1.4),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 220,
                  child: PremiumTeluguText(
                    'శ్రీ క్షేత్రం విద్యార్థులు స్వాగతం కృష్ణుడు సౌందర్యం '
                    'స్త్రీ దృష్టి కృప జ్ఞానం తెలుగు పదకేళి',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(PremiumTeluguText),
          matching: find.byType(Text),
        ),
      );
      expect(text.style!.fontFamily, PremiumTeluguText.fontFamily);
      expect(text.style!.fontFamilyFallback, ['Roboto']);
      expect(text.textScaler!.scale(16), 16 * scale);
      expect(text.strutStyle!.forceStrutHeight, isFalse);
      expect(text.maxLines, isNull);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(PremiumTeluguText),
          matching: find.byType(RichText),
        ),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.size.width, lessThanOrEqualTo(220));
      expect(paragraph.size.height, greaterThan(0));
    });
  }

  for (final width in [320.0, 390.0, 768.0, 1280.0]) {
    for (final scale in [1.0, 3.2]) {
      for (final dark in [false, true]) {
        testWidgets(
          'dashboard at width $width, ${scale}x, dark=$dark has no overflow',
          (tester) async {
            tester.view.physicalSize = Size(width, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark(1.4) : AppTheme.light(1.4),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: HomeScreen(
                  onClassic: () {},
                  onLearn: () {},
                  onProgress: () {},
                  onSettings: () {},
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            for (final label in [
              'Classic Padakeli',
              'Play & Learn',
              'Daily Puzzle',
              'My Progress',
            ]) {
              await tester.ensureVisible(find.text(label));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(find.text(label).hitTestable(), findsOneWidget);
            }

            for (final paragraph
                in tester.allRenderObjects.whereType<RenderParagraph>()) {
              expect(paragraph.didExceedMaxLines, isFalse);
            }
          },
        );
      }
    }
  }
}
