import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:wallpaperx/widgets/rate_dialog.dart';

class FakeUrlLauncher extends UrlLauncherPlatform {
  String? launchedUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchedUrl = url;
    return true;
  }
}

void main() {
  testWidgets(
    'RateDialog marks user as rated when No, Thanks is pressed',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_rated': false,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RateDialog(),
          ),
        ),
      );

      expect(find.text('Enjoying WallpaperX?'), findsOneWidget);
      expect(
        find.text('Please rate us on the Play Store and help us improve!'),
        findsOneWidget,
      );
      expect(find.text('No, Thanks'), findsOneWidget);
      expect(find.text('Rate Now'), findsOneWidget);

      await tester.tap(find.text('No, Thanks'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getBool('has_rated'), isTrue);
      expect(find.byType(RateDialog), findsNothing);
    },
  );

  testWidgets(
    'RateDialog marks user as rated and launches Play Store when Rate Now is pressed',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_rated': false,
      });

      final fakeLauncher = FakeUrlLauncher();
      final previousLauncher = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = fakeLauncher;

      addTearDown(() {
        UrlLauncherPlatform.instance = previousLauncher;
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RateDialog(),
          ),
        ),
      );

      await tester.tap(find.text('Rate Now'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getBool('has_rated'), isTrue);
      expect(
        fakeLauncher.launchedUrl,
        'https://play.google.com/store/apps/details?id=com.mohsin.wallpaperx',
      );
      expect(find.byType(RateDialog), findsNothing);
    },
  );
}


