import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaperx/widgets/loading_dots.dart';

void main() {
  testWidgets(
    'LoadingDots renders three animated dots',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingDots(),
          ),
        ),
      );

      expect(find.byType(LoadingDots), findsOneWidget);
      expect(find.byType(TweenAnimationBuilder<double>), findsNWidgets(3));
      expect(find.byType(Container), findsNWidgets(3));

      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byType(TweenAnimationBuilder<double>), findsNWidgets(3));
      expect(find.byType(Container), findsNWidgets(3));
    },
  );
}
