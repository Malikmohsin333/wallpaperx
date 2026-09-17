import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file/file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallpaperx/models/wallpaper.dart';
import 'package:wallpaperx/widgets/wallpaper_card.dart';

Wallpaper _wallpaper({String? mediumUrl}) {
  return Wallpaper(
    id: 1,
    photographer: 'Test Photographer',
    originalUrl: 'https://example.com/original.jpg',
    largeUrl: 'https://example.com/large.jpg',
    mediumUrl: mediumUrl ?? 'https://example.com/medium.jpg',
    portraitUrl: 'https://example.com/portrait.jpg',
  );
}

class FakeCacheManager implements BaseCacheManager {
  @override
  Future<File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async {
    throw Exception('Test download error');
  }

  @override
  @Deprecated('Prefer to use the new getFileStream method')
  Stream<FileInfo> getFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) {
    return Stream.error(Exception('Test download error'));
  }

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    throw Exception('Test download error');
  }

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) async {
    throw Exception('Test download error');
  }

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    return null;
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) async {
    return null;
  }

  @override
  Future<File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<File> putFileStream(
    String url,
    Stream<List<int>> source, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> removeFile(String key) async {}

  @override
  Future<void> emptyCache() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets(
    'WallpaperCard displays loading state and responds to tap',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 300,
            height: 300,
            child: WallpaperCard(
              wallpaper: _wallpaper(),
              isDarkMode: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(WallpaperCard), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(WallpaperCard));
      await tester.pump();

      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'WallpaperCard displays light mode loading state',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: SizedBox(
            width: 300,
            height: 300,
            child: WallpaperCard(
              wallpaper: _wallpaper(),
              isDarkMode: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'WallpaperCard displays error state',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 300,
            height: 300,
            child: WallpaperCard(
              wallpaper: _wallpaper(
                mediumUrl: 'https://example.com/error-medium.jpg',
              ),
              isDarkMode: true,
              onTap: () {},
              cacheManager: FakeCacheManager(),
            ),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}













