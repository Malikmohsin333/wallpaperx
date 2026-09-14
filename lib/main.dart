import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'state/wallpaper_provider.dart';
import 'app.dart' as app;
import 'state/theme_provider.dart' as theme;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox('favorites');
  await Hive.openBox('recently_viewed');

  final settingsBox = await Hive.openBox('settings');
  // ignore: unused_local_variable
  final isDarkMode = settingsBox.get('isDarkMode', defaultValue: true);

  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => theme.ThemeProvider(isDarkMode: isDarkMode),
        ),
        ChangeNotifierProvider(
          create: (_) => WallpaperProvider(),
        ),
      ],
      child: app.WallpaperXApp(showOnboarding: !showOnboarding),
    ),
  );
}

class LegacyThemeProvider extends ChangeNotifier {
  bool _isDarkMode;
  LegacyThemeProvider({required bool isDarkMode}) : _isDarkMode = isDarkMode;
  bool get isDarkMode => _isDarkMode;
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    final settingsBox = Hive.box('settings');
    settingsBox.put('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}

// All Categories Screen

// Custom Search Delegate

// Search Results Screen

// Detail Screen
