import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallpaperx/widgets/detail_action_button.dart';

void main() {
  testWidgets(
    'DetailActionButton displays correctly in dark mode and responds to tap',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DetailActionButton(
            icon: Icons.download,
            label: 'Download',
            isDarkMode: true,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      expect(find.byIcon(Icons.download), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);

      final text = tester.widget<Text>(find.text('Download'));
      expect(text.style?.color, Colors.white);

      final icon = tester.widget<Icon>(find.byIcon(Icons.download));
      expect(icon.color, Colors.white);

      await tester.tap(find.text('Download'));
      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'DetailActionButton displays correctly in light mode',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DetailActionButton(
            icon: Icons.wallpaper,
            label: 'Set Wallpaper',
            isDarkMode: false,
            onTap: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.wallpaper), findsOneWidget);
      expect(find.text('Set Wallpaper'), findsOneWidget);

      final text = tester.widget<Text>(find.text('Set Wallpaper'));
      expect(text.style?.color, Colors.black);

      final icon = tester.widget<Icon>(find.byIcon(Icons.wallpaper));
      expect(icon.color, Colors.black);
    },
  );

  testWidgets(
    'DetailActionButton handles null onTap',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DetailActionButton(
            icon: Icons.close,
            label: 'Close',
            isDarkMode: true,
            onTap: null,
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
    },
  );
}
