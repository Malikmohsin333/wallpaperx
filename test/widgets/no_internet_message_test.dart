import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallpaperx/widgets/no_internet_message.dart';

void main() {
  testWidgets(
    'NoInternetMessage displays correctly in dark mode',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));

      var retryPressed = false;
      var favoritesPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: NoInternetMessage(
            isDarkMode: true,
            onRetry: () {
              retryPressed = true;
            },
            onViewFavorites: () {
              favoritesPressed = true;
            },
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(
        find.text('Please check your connection\nand try again.'),
        findsOneWidget,
      );
      expect(
        find.text('Your favorites are still available!'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('View Favorites'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryPressed, isTrue);
      expect(favoritesPressed, isFalse);

      await tester.tap(find.text('View Favorites'));
      await tester.pump();

      expect(favoritesPressed, isTrue);

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'NoInternetMessage displays correctly in light mode',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: NoInternetMessage(
            isDarkMode: false,
            onRetry: () {},
            onViewFavorites: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('View Favorites'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    },
  );
}
