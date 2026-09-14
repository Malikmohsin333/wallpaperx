import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode;

  ThemeProvider({
    required bool isDarkMode,
  }) : _isDarkMode = isDarkMode;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;

    final settingsBox = Hive.box('settings');
    settingsBox.put('isDarkMode', _isDarkMode);

    notifyListeners();
  }
}