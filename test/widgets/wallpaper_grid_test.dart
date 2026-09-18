import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallpaperx/models/wallpaper.dart';
import 'package:wallpaperx/widgets/shimmer_loading_grid.dart';
import 'package:wallpaperx/widgets/wallpaper_card.dart';
import 'package:wallpaperx/widgets/wallpaper_grid.dart';

Wallpaper _wallpaper(int id) {
  return Wallpaper(
    id: id,
    photographer: 'Test Photographer',
    originalUrl: 'https://example.com/original.jpg',
    largeUrl: 'https://example.com/large.jpg',
    mediumUrl: 'https://example.com/medium.jpg',
    portraitUrl: 'https://example.com/portrait.jpg',
  );
}

void main() {
  testWidgets(
    'WallpaperGrid shows shimmer while loading with no wallpapers',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WallpaperGrid(
            wallpapers: const [],
            isDarkMode: true,
            isLoading: true,
            errorMessage: null,
            onRetry: () {},
            onWallpaperTap: (_) async {},
          ),
        ),
      );

      expect(find.byType(ShimmerLoadingGrid), findsOneWidget);
    },
  );

  testWidgets(
    'WallpaperGrid shows error message and Retry button',
    (tester) async {
      var retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: WallpaperGrid(
            wallpapers: const [],
            isDarkMode: false,
            isLoading: false,
            errorMessage: 'Failed to load wallpapers',
            onRetry: () {
              retryPressed = true;
            },
            onWallpaperTap: (_) async {},
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Failed to load wallpapers'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryPressed, isTrue);
    },
  );

  testWidgets(
    'WallpaperGrid shows empty state when there are no wallpapers',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WallpaperGrid(
            wallpapers: const [],
            isDarkMode: false,
            isLoading: false,
            errorMessage: null,
            onRetry: () {},
            onWallpaperTap: (_) async {},
          ),
        ),
      );

      expect(find.text('No wallpapers found'), findsOneWidget);
    },
  );

  testWidgets(
    'WallpaperGrid opens detail screen when a wallpaper is tapped',
    (tester) async {
      var wallpaperTapped = false;

      await tester.binding.setSurfaceSize(const Size(400, 900));

      await tester.pumpWidget(
        MaterialApp(
          home: WallpaperGrid(
            wallpapers: [_wallpaper(1)],
            isDarkMode: true,
            isLoading: false,
            errorMessage: null,
            onRetry: () {},
            onWallpaperTap: (_) async {
              wallpaperTapped = true;
            },
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(WallpaperCard), findsOneWidget);

      await tester.tap(find.byType(WallpaperCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(wallpaperTapped, isTrue);

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'WallpaperGrid displays wallpaper cards',
    (tester) async {
      final wallpapers = [
        _wallpaper(1),
        _wallpaper(2),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: WallpaperGrid(
            wallpapers: wallpapers,
            isDarkMode: true,
            isLoading: false,
            errorMessage: null,
            onRetry: () {},
            onWallpaperTap: (_) async {},
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(WallpaperCard), findsNWidgets(2));
    },
  );
}


