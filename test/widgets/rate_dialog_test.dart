import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallpaperx/widgets/rate_dialog.dart';

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
      expect(find.text('Please rate us on the Play Store and help us improve!'), findsOneWidget);
      expect(find.text('No, Thanks'), findsOneWidget);
      expect(find.text('Rate Now'), findsOneWidget);

      await tester.tap(find.text('No, Thanks'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getBool('has_rated'), isTrue);
      expect(find.byType(RateDialog), findsNothing);
    },
  );
}
