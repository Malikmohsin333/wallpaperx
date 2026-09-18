import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:wallpaperx/widgets/shimmer_loading_grid.dart';

void main() {
  testWidgets(
    'ShimmerLoadingGrid renders dark mode shimmer grid',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoadingGrid(isDarkMode: true),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Container), findsNWidgets(6));

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'ShimmerLoadingGrid renders light mode shimmer grid',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerLoadingGrid(isDarkMode: false),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(Container), findsNWidgets(6));

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'LoadMoreShimmer renders loading indicator',
    (tester) async {
      const shimmer = LoadMoreShimmer();
      expect(shimmer, isA<LoadMoreShimmer>());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadMoreShimmer(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
    },
  );
}


