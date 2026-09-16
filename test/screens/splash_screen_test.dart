import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallpaperx/screens/onboarding_screen.dart';
import 'package:wallpaperx/screens/splash_screen.dart';

void main() {
  testWidgets(
    'SplashScreen displays branding correctly',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': false,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('WX'), findsOneWidget);
      expect(find.text('WallpaperX'), findsOneWidget);
      expect(find.text('HD & 4K Wallpapers'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'SplashScreen navigates to onboarding when onboarding is incomplete',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': false,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    },
  );
}

