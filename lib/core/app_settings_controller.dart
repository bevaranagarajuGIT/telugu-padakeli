import 'package:flutter/foundation.dart';
import 'learning_progress.dart';

enum TeluguFontSize {
  normal,
  large,
  extraLarge;

  String get label {
    switch (this) {
      case TeluguFontSize.normal:
        return 'సాధారణం';
      case TeluguFontSize.large:
        return 'పెద్దది';
      case TeluguFontSize.extraLarge:
        return 'అతి పెద్దది';
    }
  }

  double get scale {
    switch (this) {
      case TeluguFontSize.normal:
        return 1;
      case TeluguFontSize.large:
        return 1.2;
      case TeluguFontSize.extraLarge:
        return 1.4;
    }
  }
}

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({this.progress}) {
    final saved = progress?.settings ?? {};
    _fontSize =
        TeluguFontSize.values
            .where((size) => size.name == saved['fontSize'])
            .firstOrNull ??
        TeluguFontSize.normal;
    _darkMode = saved['darkMode'] == true;
    _englishHelper = saved['englishHelper'] == true;
    _soundEnabled = saved['soundEnabled'] == true;
  }

  final LearningProgress? progress;
  TeluguFontSize _fontSize = TeluguFontSize.normal;
  bool _darkMode = false;
  bool _englishHelper = false;
  bool _soundEnabled = false;

  TeluguFontSize get fontSize => _fontSize;
  bool get darkMode => _darkMode;
  bool get englishHelper => _englishHelper;
  bool get soundEnabled => _soundEnabled;
  double get fontScale => _fontSize.scale;

  void setFontSize(TeluguFontSize value) {
    if (_fontSize == value) {
      return;
    }
    _fontSize = value;
    progress?.setSetting('fontSize', value.name);
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (_darkMode == value) {
      return;
    }
    _darkMode = value;
    progress?.setSetting('darkMode', value);
    notifyListeners();
  }

  void setEnglishHelper(bool value) {
    if (_englishHelper == value) return;
    _englishHelper = value;
    progress?.setSetting('englishHelper', value);
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    if (_soundEnabled == value) return;
    _soundEnabled = value;
    progress?.setSetting('soundEnabled', value);
    notifyListeners();
  }
}
