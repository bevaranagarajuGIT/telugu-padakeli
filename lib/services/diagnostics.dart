import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DiagnosticScreen {
  home,
  classic,
  kids,
  practice,
  riddles,
  daily,
  progress,
  settings,
  report,
}

enum DiagnosticIssue { framework, platform, storageRead, storageWrite }

abstract interface class DiagnosticStore {
  Future<String?> read();
  Future<void> write(String value);
}

class PreferencesDiagnosticStore implements DiagnosticStore {
  static const key = 'padakeli.diagnostics.v1';

  @override
  Future<String?> read() async {
    final value = (await SharedPreferences.getInstance()).get(key);
    if (value != null && value is! String) {
      throw const FormatException('Invalid diagnostics storage type.');
    }
    return value as String?;
  }

  @override
  Future<void> write(String value) async {
    if (!await (await SharedPreferences.getInstance()).setString(key, value)) {
      throw Exception('Diagnostic history was not saved.');
    }
  }
}

class MemoryDiagnosticStore implements DiagnosticStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
}

class DiagnosticEvent {
  const DiagnosticEvent(this.time, this.screen, {this.level, this.issue});

  final DateTime time;
  final DiagnosticScreen screen;
  final int? level;
  final DiagnosticIssue? issue;

  Map<String, Object> toJson() => {
    'time': time.toUtc().toIso8601String(),
    'screen': screen.name,
    'level': ?level,
    if (issue != null) 'issue': issue!.name,
  };

  static DiagnosticEvent? parse(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final time = value['time'];
    final screen = DiagnosticScreen.values
        .where((item) => item.name == value['screen'])
        .firstOrNull;
    final level = value['level'];
    final issue = DiagnosticIssue.values
        .where((item) => item.name == value['issue'])
        .firstOrNull;
    if (time is! String ||
        screen == null ||
        (level != null &&
            (level is! int || level < 1 || level > Diagnostics.maxLevel)) ||
        (value['issue'] != null && issue == null)) {
      return null;
    }
    final parsed = DateTime.tryParse(time);
    return parsed == null
        ? null
        : DiagnosticEvent(
            parsed.toUtc(),
            screen,
            level: level as int?,
            issue: issue,
          );
  }
}

/// Only enum categories and bounded level numbers enter diagnostic storage.
class Diagnostics extends ChangeNotifier {
  static const maxLevel = 20;

  Diagnostics(this.store, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final DiagnosticStore store;
  final DateTime Function() clock;
  final _events = <DiagnosticEvent>[];
  bool enabled = true;
  bool _blocked = false;
  bool _disposed = false;
  bool get available => !_blocked;
  String? storageError;
  DiagnosticScreen screen = DiagnosticScreen.home;
  int? level;
  Future<void> _writes = Future.value();
  Timer? _debounce;
  Timer? _expiry;

  List<DiagnosticEvent> get events {
    _prune();
    return List.unmodifiable(_events);
  }

  void _prune() {
    final now = clock().toUtc();
    final cutoff = now.subtract(const Duration(days: 7));
    _events.removeWhere(
      (event) => !event.time.isAfter(cutoff) || event.time.isAfter(now),
    );
    _events.sort((a, b) => a.time.compareTo(b.time));
    if (_events.length > 100) _events.removeRange(0, _events.length - 100);
    _expiry?.cancel();
    if (!_disposed && _events.isNotEmpty) {
      _expiry = Timer(
        _events.first.time.add(const Duration(days: 7)).difference(now),
        flush,
      );
    }
  }

  Future<void> load() async {
    try {
      final raw = await store.read();
      if (raw != null) {
        final value = jsonDecode(raw);
        if (value is! Map<String, dynamic> ||
            value['version'] != 1 ||
            value['enabled'] is! bool ||
            value['events'] is! List) {
          throw const FormatException('Invalid diagnostics.');
        }
        enabled = value['enabled'] as bool;
        final parsed = (value['events'] as List)
            .map(DiagnosticEvent.parse)
            .toList();
        if (parsed.any((event) => event == null)) {
          throw const FormatException('Invalid diagnostic event.');
        }
        _events
          ..clear()
          ..addAll(parsed.whereType<DiagnosticEvent>());
        if (!enabled) _events.clear();
      }
      _blocked = false;
      storageError = null;
      _prune();
      await flush();
    } on Exception {
      _blocked = true;
      enabled = false;
      _events.clear();
      storageError =
          'Diagnostic history could not be opened. Retry or clear '
          'history in Settings. Gameplay and saved progress are unaffected.';
      debugPrint('Diagnostic storage read failed.');
    }
    if (!_disposed) notifyListeners();
  }

  void location(DiagnosticScreen value, {int? level}) {
    assert(level == null || (level >= 1 && level <= maxLevel));
    if (level != null && (level < 1 || level > maxLevel)) {
      throw ArgumentError.value(level, 'level', 'Expected 1 to $maxLevel');
    }
    final changed = screen != value || this.level != level || _events.isEmpty;
    screen = value;
    this.level = level;
    if (changed) _record();
  }

  void issue(DiagnosticIssue issue) {
    _record(issue);
    if (enabled && !_blocked && !_disposed) unawaited(flush());
  }

  void _record([DiagnosticIssue? issue]) {
    if (!enabled || _blocked || _disposed) return;
    _events.add(
      DiagnosticEvent(clock().toUtc(), screen, level: level, issue: issue),
    );
    _prune();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), flush);
  }

  Future<void> setEnabled(bool value) async {
    if (_blocked) return;
    enabled = value;
    if (!value) _events.clear();
    await flush();
    if (!_disposed) notifyListeners();
  }

  Future<void> clear() async {
    _events.clear();
    _blocked = false;
    await flush();
    if (!_disposed) notifyListeners();
  }

  Future<void> retry() => _blocked ? load() : flush();

  Future<void> flush() {
    _debounce?.cancel();
    if (_blocked) return _writes;
    _prune();
    final value = jsonEncode({
      'version': 1,
      'enabled': enabled,
      'events': _events.map((event) => event.toJson()).toList(),
    });
    _writes = _writes.then((_) async {
      try {
        await store.write(value);
        storageError = null;
      } on Exception {
        storageError =
            'Diagnostic changes could not be saved. Retry in '
            'Settings. Gameplay and saved progress are unaffected.';
        debugPrint('Diagnostic storage write failed.');
      }
      if (!_disposed) notifyListeners();
    });
    return _writes;
  }

  @override
  void dispose() {
    _disposed = true;
    _expiry?.cancel();
    unawaited(flush());
    super.dispose();
  }
}

/// Preserve Flutter's existing reporting; never persist messages or stacks.
void installDiagnosticErrorHooks(Diagnostics diagnostics) {
  final flutterHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    diagnostics.issue(DiagnosticIssue.framework);
    flutterHandler?.call(details);
  };
  final platformHandler = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    diagnostics.issue(DiagnosticIssue.platform);
    return platformHandler?.call(error, stack) ?? false;
  };
}
