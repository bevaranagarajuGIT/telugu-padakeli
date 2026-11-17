import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:telugu_padakeli/core/app_settings_controller.dart';
import 'package:telugu_padakeli/core/app_theme.dart';
import 'package:telugu_padakeli/screens/report_problem_screen.dart';
import 'package:telugu_padakeli/screens/settings_screen.dart';
import 'package:telugu_padakeli/services/diagnostics.dart';
import 'package:telugu_padakeli/services/problem_report.dart';

class _Reporter implements ProblemReporter {
  int shares = 0;
  bool failVersion = false;
  bool failShare = false;
  ProblemReport? shared;
  Rect? origin;
  ShareResultStatus status = ShareResultStatus.dismissed;

  @override
  Future<String> appVersion() async {
    if (failVersion) throw Exception('private version error');
    return '0.1.0+1';
  }

  @override
  Future<ShareResultStatus> share(ProblemReport report, Rect origin) async {
    shares++;
    if (failShare) throw Exception('private share error');
    shared = report;
    this.origin = origin;
    return status;
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  final viewport =
      Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
  await tester.tapAt(tester.getRect(finder).intersect(viewport).center);
  await tester.pumpAndSettle();
}

Future<Diagnostics> _open(
  WidgetTester tester, {
  required Widget screen,
  double width = 390,
  double scale = 1,
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final diagnostics = Diagnostics(MemoryDiagnosticStore());
  diagnostics.location(DiagnosticScreen.riddles, level: 4);
  final settings = AppSettingsController();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => diagnostics),
        ChangeNotifierProvider(create: (_) => settings),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark(1.4) : AppTheme.light(1),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  return diagnostics;
}

void main() {
  testWidgets(
    'requires description; diagnostics off until chosen; preview is exact',
    (tester) async {
      final reporter = _Reporter();
      final diagnostics = await _open(
        tester,
        screen: ReportProblemScreen(reporter: reporter),
      );
      expect(reporter.shares, 0);
      await _tap(tester, 'report-preview');
      expect(
        find.textContaining('Please describe the problem'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('report-description')),
        'The Next button did not respond.',
      );
      await _tap(tester, 'report-preview');
      expect(find.textContaining('Diagnostics: not included.'), findsOneWidget);
      expect(reporter.shares, 0);
      await _tap(tester, 'report-edit');
      expect(find.text('The Next button did not respond.'), findsOneWidget);
      await _tap(tester, 'report-include-diagnostics');
      await _tap(tester, 'report-preview');
      final preview = tester
          .widget<SelectableText>(
            find.descendant(
              of: find.byKey(const ValueKey('report-content')),
              matching: find.byType(SelectableText),
            ),
          )
          .data!;
      expect(preview, contains('"level":4'));
      expect(preview, contains('0.1.0+1'));
      diagnostics.location(DiagnosticScreen.daily, level: 2);
      await _tap(tester, 'report-share');
      expect(reporter.shared!.text, preview);
      expect(reporter.origin!.size.isEmpty, isFalse);
      expect(find.textContaining('Sharing cancelled.'), findsOneWidget);
      expect(find.byKey(const ValueKey('report-content')), findsOneWidget);
      reporter.status = ShareResultStatus.success;
      await _tap(tester, 'report-share');
      expect(find.textContaining('Delivery is not confirmed.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('version and sharing failures are visible and retryable', (
    tester,
  ) async {
    final reporter = _Reporter()..failVersion = true;
    await _open(tester, screen: ReportProblemScreen(reporter: reporter));
    await tester.enterText(
      find.byKey(const ValueKey('report-description')),
      'The report button needs checking.',
    );
    await _tap(tester, 'report-preview');
    expect(
      find.textContaining('Could not read the app version'),
      findsOneWidget,
    );
    expect(find.textContaining('private version'), findsNothing);
    reporter.failVersion = false;
    await _tap(tester, 'report-preview');
    reporter.failShare = true;
    await _tap(tester, 'report-share');
    expect(find.textContaining('Could not open sharing'), findsOneWidget);
    expect(find.textContaining('private share'), findsNothing);
    reporter.failShare = false;
    await _tap(tester, 'report-share');
    expect(reporter.shared, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Settings controls clear history and open report without sending',
    (tester) async {
      final diagnostics = await _open(tester, screen: const SettingsScreen());
      await _tap(tester, 'diagnostics-clear');
      expect(diagnostics.events, isEmpty);
      diagnostics.issue(DiagnosticIssue.framework);
      await _tap(tester, 'diagnostics-setting');
      expect(diagnostics.enabled, isFalse);
      expect(diagnostics.events, isEmpty);
      await _tap(tester, 'report-problem-setting');
      expect(find.byType(ReportProblemScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('report-description')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-share')), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(diagnostics.screen, DiagnosticScreen.settings);
      expect(tester.takeException(), isNull);
    },
  );

  for (final config in [
    (width: 320.0, scale: 1.0, dark: false),
    (width: 320.0, scale: 2.0, dark: true),
    (width: 800.0, scale: 2.0, dark: false),
  ]) {
    testWidgets('report wraps and actions remain reachable $config', (
      tester,
    ) async {
      final reporter = _Reporter();
      await _open(
        tester,
        screen: ReportProblemScreen(reporter: reporter),
        width: config.width,
        scale: config.scale,
        dark: config.dark,
      );
      await tester.enterText(
        find.byKey(const ValueKey('report-description')),
        'రెండో స్థాయిలో కొనసాగించలేకపోయాను. Next did not work.',
      );
      await _tap(tester, 'report-include-diagnostics');
      await _tap(tester, 'report-preview');
      await tester.ensureVisible(find.byKey(const ValueKey('report-share')));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('report-share'))).height,
        greaterThanOrEqualTo(48),
      );
      await _tap(tester, 'report-share');
      expect(reporter.shares, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
