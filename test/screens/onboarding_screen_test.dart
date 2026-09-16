import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallpaperx/screens/onboarding_screen.dart';

void main() {
  testWidgets(
    'OnboardingScreen shows the first page correctly',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      expect(find.text('Welcome to WallpaperX'), findsOneWidget);
      expect(
        find.text(
          'Discover thousands of HD & 4K wallpapers for your phone',
        ),
        findsOneWidget,
      );
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);
      expect(find.byIcon(Icons.wallpaper), findsOneWidget);
    },
  );

  testWidgets(
    'OnboardingScreen moves to the next page when Next is pressed',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );

      expect(find.text('Welcome to WallpaperX'), findsOneWidget);
      expect(find.text('Endless Categories'), findsNothing);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to WallpaperX'), findsNothing);
      expect(find.text('Endless Categories'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    },
  );
  testWidgets(
    'OnboardingScreen completes onboarding and navigates to home',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': false,
      });

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/home': (context) => const Scaffold(
                  body: Text('Home Screen'),
                ),
          },
          home: const OnboardingScreen(),
        ),
      );

      await tester.fling(
        find.byType(PageView),
        const Offset(-1000, 0),
        1000,
      );
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(PageView),
        const Offset(-1000, 0),
        1000,
      );
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(PageView),
        const Offset(-1000, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Get Started'), findsOneWidget);
      expect(find.text('Welcome to WallpaperX'), findsNothing);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isTrue);
    },
  );}


