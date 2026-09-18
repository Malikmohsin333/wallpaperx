import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallpaperx/widgets/settings_bottom_sheet.dart';

Widget buildTestApp({
  required VoidCallback onClearCache,
  required VoidCallback onShareApp,
  required VoidCallback onRateUs,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        return ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => SettingsBottomSheet(
                onClearCache: onClearCache,
                onShareApp: onShareApp,
                onRateUs: onRateUs,
              ),
            );
          },
          child: const Text('Open Settings'),
        );
      },
    ),
  );
}

void main() {
  testWidgets('renders all settings options', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        onClearCache: () {},
        onShareApp: () {},
        onRateUs: () {},
      ),
    );

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Clear Cache'), findsOneWidget);
    expect(find.text('Share App'), findsOneWidget);
    expect(find.text('Rate Us'), findsOneWidget);

    expect(find.byIcon(Icons.clear_all), findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('Clear Cache closes sheet and triggers callback', (tester) async {
    var called = false;

    await tester.pumpWidget(
      buildTestApp(
        onClearCache: () => called = true,
        onShareApp: () {},
        onRateUs: () {},
      ),
    );

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear Cache'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(find.text('Clear Cache'), findsNothing);
  });

  testWidgets('Share App closes sheet and triggers callback', (tester) async {
    var called = false;

    await tester.pumpWidget(
      buildTestApp(
        onClearCache: () {},
        onShareApp: () => called = true,
        onRateUs: () {},
      ),
    );

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share App'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(find.text('Share App'), findsNothing);
  });

  testWidgets('Rate Us closes sheet and triggers callback', (tester) async {
    var called = false;

    await tester.pumpWidget(
      buildTestApp(
        onClearCache: () {},
        onShareApp: () {},
        onRateUs: () => called = true,
      ),
    );

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rate Us'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(find.text('Rate Us'), findsNothing);
  });
}
