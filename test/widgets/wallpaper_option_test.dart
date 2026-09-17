import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallpaperx/widgets/wallpaper_option.dart';

void main() {
  testWidgets(
    'WallpaperOption displays correctly in dark mode and responds to tap',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: WallpaperOption(
            icon: Icons.wallpaper,
            label: 'Set Wallpaper',
            isDarkMode: true,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      expect(find.byIcon(Icons.wallpaper), findsOneWidget);
      expect(find.text('Set Wallpaper'), findsOneWidget);

      final text = tester.widget<Text>(find.text('Set Wallpaper'));
      expect(text.style?.color, Colors.white);

      await tester.tap(find.text('Set Wallpaper'));
      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'WallpaperOption displays black label in light mode',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WallpaperOption(
            icon: Icons.download,
            label: 'Download',
            isDarkMode: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.download), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);

      final text = tester.widget<Text>(find.text('Download'));
      expect(text.style?.color, Colors.black);
    },
  );
}
