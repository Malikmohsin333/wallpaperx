import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallpaperx/widgets/animated_message.dart';

void main() {

  testWidgets(
    'AnimatedMessage displays success message',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Stack(
            children: [
              AnimatedMessage(
                message: 'Download successful',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Download successful'), findsOneWidget);
      expect(find.byType(Positioned), findsOneWidget);
      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
      expect(find.byType(Transform), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
    },
  );

  testWidgets(
    'AnimatedMessage displays error message',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Stack(
            children: [
              AnimatedMessage(
                message: 'Download failed',
                isSuccess: false,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Download failed'), findsOneWidget);
      expect(find.byType(Positioned), findsOneWidget);
      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
      expect(find.byType(Transform), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
    },
  );
}


