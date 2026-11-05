import 'package:flutter/foundation.dart';

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
  TeluguFontSize _fontSize = TeluguFontSize.normal;
  bool _darkMode = false;

  TeluguFontSize get fontSize => _fontSize;
  bool get darkMode => _darkMode;
  double get fontScale => _fontSize.scale;

  void setFontSize(TeluguFontSize value) {
    if (_fontSize == value) {
      return;
    }
    _fontSize = value;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (_darkMode == value) {
      return;
    }
    _darkMode = value;
    notifyListeners();
  }
}
