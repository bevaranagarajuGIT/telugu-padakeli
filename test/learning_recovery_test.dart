import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telugu_padakeli/core/learning_progress.dart';
import 'package:telugu_padakeli/services/learning_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final preferences in [false, true]) {
    final name = preferences ? 'preferences' : 'memory';
    LearningStore createStore() =>
        preferences ? PreferencesLearningStore() : MemoryLearningStore();

    Future<String?> recovery(LearningStore store) async =>
        store is MemoryLearningStore
        ? store.recovery
        : (await SharedPreferences.getInstance()).getString(
            '${PreferencesLearningStore.key}.recovery',
          );

    for (final damagedSection in ['settings', 'sessions']) {
      test(
        '$name: malformed $damagedSection preserves other progress and reward identity',
        () async {
          final store = createStore();
          final saved = LearningProgress(store, autoSave: false);
          saved.setSetting('englishHelper', true);
          saved.recordAnswer('question', true);
          saved.completeActivity('pictures');
          saved.saveSession('pictures', {'questionId': 'question'});
          saved.saveBoard('classic', {
            'id': 101,
            'cells': ['saved cell'],
            'hints': 2,
          });
          await saved.flush();
          saved.dispose();
          final snapshot =
              jsonDecode((await store.read())!) as Map<String, dynamic>;
          final raw = jsonEncode({
            ...snapshot,
            damagedSection: null,
            'futureMetadata': {'retained': true},
          });
          await store.write(raw);

          final restored = LearningProgress(store, autoSave: false);
          addTearDown(restored.dispose);
          await restored.load();
          expect(restored.board('classic'), snapshot['boards']['classic']);
          expect(restored.checkedQuestions, 1);
          expect(restored.firstAttemptCorrect, 1);
          expect(restored.todayQuestions, 1);
          expect(restored.completedActivities, {'pictures'});
          expect(restored.stars, 1);
          if (damagedSection == 'settings') {
            expect(restored.sessions, snapshot['sessions']);
          } else {
            expect(restored.settings, snapshot['settings']);
          }
          expect(restored.recoveryNotice, isNotNull);
          expect(restored.storageError, isNull);
          expect(await recovery(store), raw);
          expect(restored.completeActivity('pictures'), isFalse);
          await restored.flush();
          final repaired = jsonDecode((await store.read())!);
          expect(repaired['boards'], snapshot['boards']);
          expect(repaired['answers'], snapshot['answers']);
          expect(repaired['rewards'], snapshot['rewards']);
          expect(repaired['futureMetadata'], {'retained': true});
          expect(repaired[damagedSection], <String, dynamic>{});
          expect(await recovery(store), raw);
        },
      );
    }

    for (final missing in [false, true]) {
      test(
        '$name: ${missing ? 'missing' : 'unreadable'} reward identities block saving and new rewards',
        () async {
          final store = createStore();
          final saved = LearningProgress(store, autoSave: false);
          saved.completeActivity('pictures');
          saved.saveBoard('classic', {
            'id': 101,
            'cells': ['saved cell'],
            'hints': 2,
          });
          await saved.flush();
          saved.dispose();
          final snapshot =
              jsonDecode((await store.read())!) as Map<String, dynamic>;
          if (missing) {
            snapshot.remove('rewards');
          } else {
            snapshot['rewards'] = null;
          }
          final raw = jsonEncode(snapshot);
          await store.write(raw);

          final restored = LearningProgress(store, autoSave: false);
          addTearDown(restored.dispose);
          await restored.load();
          expect(restored.board('classic'), snapshot['boards']['classic']);
          expect(restored.completedActivities, {'pictures'});
          expect(restored.recoveryNotice, isNotNull);
          expect(restored.canRetrySave, isFalse);
          expect(restored.completeActivity('pictures'), isFalse);
          expect(restored.completePuzzle('101'), isFalse);
          restored.setSetting('englishHelper', true);
          await restored.flush();
          expect(await store.read(), raw);
          expect(await recovery(store), raw);
        },
      );
    }

    test(
      '$name: a different existing recovery copy blocks unsafe overwrite',
      () async {
        final store = createStore();
        const first = 'first unreadable save';
        const second = '{"version":1,"boards":';
        await store.preserveRecoveryCopy(first);
        await store.write(second);
        final restored = LearningProgress(store, autoSave: false);
        addTearDown(restored.dispose);
        await restored.load();
        expect(restored.storageError, isNotNull);
        expect(restored.canRetrySave, isFalse);
        restored.recordAnswer('temporary answer', true);
        await restored.flush();
        expect(await store.read(), second);
        expect(await recovery(store), first);
      },
    );

    test(
      '$name: preserving the identical recovery copy is idempotent',
      () async {
        final store = createStore();
        const raw = 'unreadable save';
        await store.preserveRecoveryCopy(raw);
        await store.preserveRecoveryCopy(raw);
        expect(await recovery(store), raw);
      },
    );
  }

  test(
    'missing and older saves are distinguished without overwriting',
    () async {
      for (final raw in [null, '{"version":0,"legacy":{"answers":["kept"]}}']) {
        final store = MemoryLearningStore()..value = raw;
        final saved = LearningProgress(store, autoSave: false);
        addTearDown(saved.dispose);
        await saved.load();
        expect(saved.storageError, isNull);
        expect(saved.recoveryNotice, raw == null ? isNull : isNotNull);
        if (raw != null) {
          saved.recordAnswer('temporary answer', true);
          await saved.flush();
          expect(store.value, raw);
        }
      }
    },
  );
}
