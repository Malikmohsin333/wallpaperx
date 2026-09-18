import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file/file.dart' as file;
import 'package:file/src/backends/memory/memory_file_system.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallpaperx/screens/detail_screen.dart';
import 'package:wallpaperx/screens/favorites_screen.dart';

class FakeCacheManager implements BaseCacheManager {
  final file.File testFile;

  FakeCacheManager(this.testFile);

  @override
  Future<file.File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async {
    return testFile;
  }

  @override
  Stream<FileInfo> getFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) {
    return Stream.value(
      FileInfo(
        testFile,
        FileSource.Cache,
        DateTime.now().add(const Duration(hours: 1)),
        url,
      ),
    );
  }

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    return Stream.value(
      FileInfo(
        testFile,
        FileSource.Cache,
        DateTime.now().add(const Duration(hours: 1)),
        url,
      ),
    );
  }

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) async {
    return FileInfo(
      testFile,
      FileSource.Cache,
      DateTime.now().add(const Duration(hours: 1)),
      url,
    );
  }

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    return FileInfo(
      testFile,
      FileSource.Cache,
      DateTime.now().add(const Duration(hours: 1)),
      key,
    );
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) async {
    return null;
  }

  @override
  Future<file.File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    return testFile;
  }

  @override
  Future<file.File> putFileStream(
    String url,
    Stream<List<int>> fileStream, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    return testFile;
  }

  @override
  Future<void> removeFile(String key) async {}

  @override
  Future<void> emptyCache() async {}

  @override
  Future<void> dispose() async {}
}

class ErrorCacheManager implements BaseCacheManager {
  @override
  Future<file.File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) async {
    throw Exception('cache error');
  }

  @override
  Stream<FileInfo> getFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) {
    return const Stream.empty();
  }

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    return Stream<FileResponse>.error(Exception("cache error"));
  }

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) async {
    throw Exception('cache error');
  }

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    throw Exception('cache error');
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) async {
    return null;
  }

  @override
  Future<file.File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    throw Exception('cache error');
  }

  @override
  Future<file.File> putFileStream(
    String url,
    Stream<List<int>> fileStream, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    throw Exception('cache error');
  }

  @override
  Future<void> removeFile(String key) async {}

  @override
  Future<void> emptyCache() async {}

  @override
  Future<void> dispose() async {}
}

Future<void> _addFavorite({
  String key = 'test-key',
  String urlPrefix = 'https://example.com',
}) async {
  await Hive.box('favorites').put(key, {
    'id': 1,
    'photographer': 'Test Photographer',
    'src': {
      'original': '$urlPrefix/original.jpg',
      'large': '$urlPrefix/large.jpg',
      'medium': '$urlPrefix/medium.jpg',
      'portrait': '$urlPrefix/portrait.jpg',
    },
  });
}

Future<file.File> _validTestFile() async {
  final memoryFileSystem = MemoryFileSystem();
  final testFile = memoryFileSystem.file('test_wallpaper.png');

  final pngBytes = Uint8List.fromList([
    137, 80, 78, 71, 13, 10, 26, 10,
    0, 0, 0, 13, 73, 72, 68, 82,
    0, 0, 0, 1, 0, 0, 0, 1, 8, 6,
    0, 0, 0, 31, 21, 196, 137,
    0, 0, 0, 13, 73, 68, 65, 84,
    120, 156, 99, 248, 207, 192, 240,
    31, 0, 5, 0, 1, 255, 137, 153,
    61, 29, 0, 0, 0, 0, 73, 69,
    78, 68, 174, 66, 96, 130,
  ]);

  await testFile.writeAsBytes(pngBytes);
  return testFile;
}

void main() {
  setUpAll(() async {
    await Hive.openBox('favorites', bytes: Uint8List(0));
  });

  setUp(() async {
    await Hive.box('favorites').clear();
  });

  tearDown(() async {
    await Hive.box('favorites').clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets(
    'FavoritesScreen displays empty state when there are no favorites',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const FavoritesScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('My Favorites'), findsOneWidget);
      expect(find.text('No favorites yet'), findsOneWidget);
      expect(
        find.text('Tap the heart icon to add wallpapers'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    },
  );

  testWidgets(
    'FavoritesScreen displays favorite wallpaper',
    (tester) async {
      final testFile = await _validTestFile();
      final cacheManager = FakeCacheManager(testFile);

      await _addFavorite();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: FavoritesScreen(cacheManager: cacheManager),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('My Favorites'), findsOneWidget);
      expect(find.text('No favorites yet'), findsNothing);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(GestureDetector), findsWidgets);
    },
  );

  testWidgets(
    'FavoritesScreen back button pops the screen',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FavoritesScreen(),
                      ),
                    );
                  },
                  child: const Text('Open Favorites'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Favorites'));
      await tester.pumpAndSettle();

      expect(find.text('My Favorites'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Open Favorites'), findsOneWidget);
      expect(find.text('My Favorites'), findsNothing);
    },
  );

  testWidgets(
    'FavoritesScreen opens detail screen when favorite is tapped',
    (tester) async {
      final testFile = await _validTestFile();
      final cacheManager = FakeCacheManager(testFile);

      await _addFavorite();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: FavoritesScreen(cacheManager: cacheManager),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final favoriteTile = find.byType(GestureDetector).first;
      expect(favoriteTile, findsOneWidget);

      await tester.tap(favoriteTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byType(DetailScreen), findsOneWidget);
    },
  );

  testWidgets(
    'FavoritesScreen shows image error widget',
    (tester) async {
      await _addFavorite(
        key: 'error-light',
        urlPrefix: 'https://error-light.example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: FavoritesScreen(
            cacheManager: ErrorCacheManager(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.error), findsOneWidget);
    },
  );

  testWidgets(
    'FavoritesScreen uses dark theme colors for image error',
    (tester) async {
      await _addFavorite(
        key: 'error-dark',
        urlPrefix: 'https://error-dark.example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: FavoritesScreen(
            cacheManager: ErrorCacheManager(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.error), findsOneWidget);
    },
  );
}





