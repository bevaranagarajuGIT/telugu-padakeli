import 'package:shared_preferences/shared_preferences.dart';

class LearningStorageException implements Exception {
  const LearningStorageException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract interface class LearningStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> preserveRecoveryCopy(String value);
}

class PreferencesLearningStore implements LearningStore {
  static const key = 'padakeli.learning.v1';

  @override
  Future<String?> read() async {
    final value = (await SharedPreferences.getInstance()).get(key);
    if (value != null && value is! String) {
      throw const LearningStorageException(
        'Saved progress has an invalid type.',
      );
    }
    return value as String?;
  }

  @override
  Future<void> write(String value) async {
    if (!await (await SharedPreferences.getInstance()).setString(key, value)) {
      throw const LearningStorageException(
        'The device did not save learning progress.',
      );
    }
  }

  @override
  Future<void> preserveRecoveryCopy(String value) async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.get('$key.recovery');
    if (existing != null) {
      if (existing == value) return;
      throw const LearningStorageException(
        'A different recovery copy already exists. The current save must '
        'not be overwritten.',
      );
    }
    if (!await preferences.setString('$key.recovery', value)) {
      throw const LearningStorageException(
        'The recovery copy could not be saved.',
      );
    }
  }
}

class MemoryLearningStore implements LearningStore {
  String? value;
  String? recovery;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;

  @override
  Future<void> preserveRecoveryCopy(String value) async {
    if (recovery != null && recovery != value) {
      throw const LearningStorageException(
        'A different recovery copy already exists. The current save must '
        'not be overwritten.',
      );
    }
    recovery ??= value;
  }
}
