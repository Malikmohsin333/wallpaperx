import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:wallpaperx/state/theme_provider.dart';

void main() {
  setUpAll(() async {
    Hive.init('.');
    await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.box('settings').clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  test('initializes with the provided theme value', () {
    final provider = ThemeProvider(isDarkMode: true);

    expect(provider.isDarkMode, isTrue);
  });

  test('toggleTheme switches theme, saves it, and notifies listeners', () {
    final provider = ThemeProvider(isDarkMode: false);
    var notificationCount = 0;

    provider.addListener(() {
      notificationCount++;
    });

    provider.toggleTheme();

    expect(provider.isDarkMode, isTrue);
    expect(Hive.box('settings').get('isDarkMode'), isTrue);
    expect(notificationCount, 1);

    provider.toggleTheme();

    expect(provider.isDarkMode, isFalse);
    expect(Hive.box('settings').get('isDarkMode'), isFalse);
    expect(notificationCount, 2);
  });
}
