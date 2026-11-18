import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telugu_padakeli/core/learning_progress.dart';
import 'package:telugu_padakeli/models/riddle.dart';
import 'package:telugu_padakeli/services/diagnostics.dart';
import 'package:telugu_padakeli/services/learning_store.dart';
import 'package:telugu_padakeli/services/problem_report.dart';

class _FailingStore extends MemoryDiagnosticStore {
  bool failRead = false;
  bool failWrite = false;
  @override
  Future<String?> read() async {
    if (failRead) throw Exception('private read message');
    return super.read();
  }

  @override
  Future<void> write(String value) async {
    if (failWrite) throw Exception('private write message');
    await super.write(value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'caps history, expires at seven days, survives restart and clears',
    () async {
      var now = DateTime.utc(2026, 11, 17);
      final store = MemoryDiagnosticStore();
      final diagnostics = Diagnostics(store, clock: () => now);
      addTearDown(diagnostics.dispose);
      await diagnostics.load();
      for (var i = 0; i < 105; i++) {
        diagnostics.location(DiagnosticScreen.classic, level: i % 5 + 1);
        now = now.add(const Duration(seconds: 1));
      }
      expect(diagnostics.events, hasLength(100));
      expect(diagnostics.events.first.level, 1);
      await diagnostics.flush();
      final restored = Diagnostics(store, clock: () => now);
      addTearDown(restored.dispose);
      await restored.load();
      expect(restored.events, hasLength(100));
      now = restored.events.last.time.add(const Duration(days: 7));
      expect(restored.events, isEmpty);
      await restored.flush();
      expect(jsonDecode(store.value!)['events'], isEmpty);
      restored.location(DiagnosticScreen.riddles, level: 2);
      await restored.setEnabled(false);
      restored.issue(DiagnosticIssue.framework);
      expect(restored.events, isEmpty);
      final disabled = Diagnostics(store, clock: () => now);
      addTearDown(disabled.dispose);
      await disabled.load();
      expect(disabled.enabled, isFalse);
      await disabled.setEnabled(true);
      disabled.location(DiagnosticScreen.kids);
      await disabled.clear();
      expect(disabled.events, isEmpty);
      expect(jsonDecode(store.value!)['events'], isEmpty);
    },
  );

  test(
    'expanded riddle level locations persist without blocking diagnostic history',
    () async {
      final store = MemoryDiagnosticStore();
      final diagnostics = Diagnostics(store);
      addTearDown(diagnostics.dispose);
      for (final level in RiddleLevel.values) {
        diagnostics.location(DiagnosticScreen.riddles, level: level.index + 1);
      }
      await diagnostics.flush();
      final restored = Diagnostics(store);
      addTearDown(restored.dispose);
      await restored.load();
      expect(restored.available, isTrue);
      expect(restored.storageError, isNull);
      expect(
        restored.events.map((event) => event.level),
        RiddleLevel.values.map((level) => level.index + 1),
      );
      for (final invalid in [0, Diagnostics.maxLevel + 1]) {
        expect(
          DiagnosticEvent.parse({
            'time': DateTime.now().toUtc().toIso8601String(),
            'screen': 'riddles',
            'level': invalid,
          }),
          isNull,
        );
        expect(
          () => diagnostics.location(DiagnosticScreen.riddles, level: invalid),
          throwsA(anyOf(isA<AssertionError>(), isA<ArgumentError>())),
        );
      }
    },
  );

  test(
    'allowlisted serialization never exports unknown persisted fields',
    () async {
      final now = DateTime.utc(2026, 11, 17);
      final store = MemoryDiagnosticStore()
        ..value = jsonEncode({
          'version': 1,
          'enabled': true,
          'email': 'private@example.test',
          'events': [
            {
              ...DiagnosticEvent(
                now,
                DiagnosticScreen.riddles,
                level: 3,
                issue: DiagnosticIssue.framework,
              ).toJson(),
              'message': 'a private answer and /user/path',
              'stack': 'raw stack',
            },
            DiagnosticEvent(
              now.add(const Duration(days: 1)),
              DiagnosticScreen.kids,
            ).toJson(),
          ],
        });
      final diagnostics = Diagnostics(store, clock: () => now);
      addTearDown(diagnostics.dispose);
      await diagnostics.load();
      expect(diagnostics.events, hasLength(1));
      final report = ProblemReport.create(
        description: 'Button does not work',
        version: '0.1.0+1',
        platform: 'android',
        diagnostics: diagnostics.events,
      );
      for (final forbidden in ['private', 'stack', '/user/path', 'email']) {
        expect(report.text, isNot(contains(forbidden)));
        expect(store.value, isNot(contains(forbidden)));
      }
      expect(report.text, contains('"level":3'));
      expect(utf8.decode(report.bytes), report.text);
      final excluded = ProblemReport.create(
        description: 'Button does not work',
        version: '0.1.0+1',
        platform: 'android',
        diagnostics: null,
      );
      expect(excluded.text, contains('not included'));
      expect(excluded.text, isNot(contains('"level"')));
    },
  );

  test(
    'read corruption blocks writes; explicit clear recovers safely',
    () async {
      final store = MemoryDiagnosticStore()..value = '{"broken":';
      final diagnostics = Diagnostics(store);
      addTearDown(diagnostics.dispose);
      await diagnostics.load();
      expect(diagnostics.storageError, isNotNull);
      expect(diagnostics.available, isFalse);
      diagnostics.issue(DiagnosticIssue.platform);
      await diagnostics.flush();
      expect(store.value, '{"broken":');
      await diagnostics.clear();
      expect(diagnostics.storageError, isNull);
      expect(diagnostics.events, isEmpty);
      await diagnostics.setEnabled(true);
      diagnostics.location(DiagnosticScreen.daily, level: 1);
      await diagnostics.flush();
      expect(jsonDecode(store.value!)['events'], hasLength(1));
    },
  );

  test('write failure is visible and retry preserves unsaved events', () async {
    final store = _FailingStore();
    final diagnostics = Diagnostics(store);
    addTearDown(diagnostics.dispose);
    await diagnostics.load();
    store.failWrite = true;
    diagnostics.location(DiagnosticScreen.practice, level: 4);
    await diagnostics.flush();
    expect(diagnostics.storageError, contains('could not be saved'));
    expect(diagnostics.storageError, isNot(contains('private')));
    store.failWrite = false;
    await diagnostics.retry();
    expect(diagnostics.storageError, isNull);
    expect(jsonDecode(store.value!)['events'].single['level'], 4);
  });

  test(
    'framework hooks preserve existing reporting without storing raw errors',
    () async {
      final diagnostics = Diagnostics(MemoryDiagnosticStore());
      addTearDown(diagnostics.dispose);
      final flutterHandler = FlutterError.onError;
      final platformHandler = PlatformDispatcher.instance.onError;
      addTearDown(() {
        FlutterError.onError = flutterHandler;
        PlatformDispatcher.instance.onError = platformHandler;
      });
      var flutterCalls = 0;
      FlutterError.onError = (_) => flutterCalls++;
      PlatformDispatcher.instance.onError = (_, _) => true;
      installDiagnosticErrorHooks(diagnostics);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: Exception('secret@example.test'),
          stack: StackTrace.fromString('private filesystem path'),
        ),
      );
      expect(flutterCalls, 1);
      expect(
        PlatformDispatcher.instance.onError!(
          Exception('private'),
          StackTrace.current,
        ),
        isTrue,
      );
      await diagnostics.flush();
      expect(diagnostics.events.map((event) => event.issue), [
        DiagnosticIssue.framework,
        DiagnosticIssue.platform,
      ]);
      expect(
        (diagnostics.store as MemoryDiagnosticStore).value,
        isNot(contains('private')),
      );
    },
  );

  test('diagnostics never modifies gameplay preferences or recovery', () async {
    const saved =
        '{"version":1,"riddles":{"current":"draft-pencil",'
        '"answers":{"sentinel":"private answer"}},"rewards":{"one":"today"}}';
    SharedPreferences.setMockInitialValues({
      PreferencesLearningStore.key: saved,
      '${PreferencesLearningStore.key}.recovery': 'keep recovery',
    });
    final diagnostics = Diagnostics(PreferencesDiagnosticStore());
    addTearDown(diagnostics.dispose);
    await diagnostics.load();
    diagnostics.location(DiagnosticScreen.settings);
    await diagnostics.clear();
    await diagnostics.setEnabled(false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(PreferencesLearningStore.key), saved);
    expect(
      prefs.getString('${PreferencesLearningStore.key}.recovery'),
      'keep recovery',
    );
  });

  test('storage failures log only their fixed category', () async {
    final diagnostics = Diagnostics(MemoryDiagnosticStore());
    addTearDown(diagnostics.dispose);
    final progress = LearningProgress(
      _ReadFailure(),
      diagnostics: diagnostics,
      autoSave: false,
    );
    addTearDown(progress.dispose);
    await progress.load();
    expect(progress.storageError, isNotNull);
    expect(diagnostics.events.single.issue, DiagnosticIssue.storageRead);
  });

  testWidgets('idle expiry also removes persisted events', (tester) async {
    final store = MemoryDiagnosticStore();
    final diagnostics = Diagnostics(store, clock: tester.binding.clock.now);
    diagnostics.location(DiagnosticScreen.riddles, level: 2);
    await diagnostics.flush();
    expect(jsonDecode(store.value!)['events'], hasLength(1));
    await tester.pump(const Duration(days: 7));
    expect(jsonDecode(store.value!)['events'], isEmpty);
    diagnostics.dispose();
  });
}

class _ReadFailure extends MemoryLearningStore {
  @override
  Future<String?> read() async => throw Exception('raw private message');
}
