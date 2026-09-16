import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:file/file.dart' as file;
import 'package:file/src/backends/memory/memory_file_system.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wallpaperx/screens/favorites_screen.dart';

void _log(String msg) {
  File('diag_log.txt').writeAsStringSync('$msg\n', mode: FileMode.append, flush: true);
}

class FakeCacheManager implements BaseCacheManager {
  final file.File testFile;

  FakeCacheManager(this.testFile);

  @override
  Future<file.File> getSingleFile(String url, {String? key, Map<String, String>? headers}) async {
    return testFile;
  }

  @override
  Stream<FileInfo> getFile(String url, {String? key, Map<String, String>? headers}) {
    return Stream.value(FileInfo(testFile, FileSource.Cache, DateTime.now().add(const Duration(hours: 1)), url));
  }

  @override
  Stream<FileResponse> getFileStream(String url, {String? key, Map<String, String>? headers, bool withProgress = false}) {
    return Stream.value(FileInfo(testFile, FileSource.Cache, DateTime.now().add(const Duration(hours: 1)), url));
  }

  @override
  Future<FileInfo> downloadFile(String url, {String? key, Map<String, String>? authHeaders, bool force = false}) async {
    return FileInfo(testFile, FileSource.Cache, DateTime.now().add(const Duration(hours: 1)), url);
  }

  @override
  Future<FileInfo?> getFileFromCache(String key, {bool ignoreMemCache = false}) async {
    return FileInfo(testFile, FileSource.Cache, DateTime.now().add(const Duration(hours: 1)), key);
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) async {
    return null;
  }

  @override
  Future<file.File> putFile(String url, Uint8List fileBytes, {String? key, String? eTag, Duration maxAge = const Duration(days: 30), String fileExtension = 'file'}) async {
    return testFile;
  }

  @override
  Future<file.File> putFileStream(String url, Stream<List<int>> fileStream, {String? key, String? eTag, Duration maxAge = const Duration(days: 30), String fileExtension = 'file'}) async {
    return testFile;
  }

  @override
  Future<void> removeFile(String key) async {}

  @override
  Future<void> emptyCache() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  setUpAll(() async {
    _log('SETUP-0: opening in-memory box');
    // bytes: Uint8List(0) forces Hive's in-memory storage backend,
    // avoiding real disk I/O entirely -- no Hive.init(), no temp dir,
    // no Windows file-lock/antivirus interaction.
    await Hive.openBox('favorites', bytes: Uint8List(0));
    _log('SETUP-3: box opened');
  });

  setUp(() async {
    _log('SETUP-EACH-0: before clear');
    await Hive.box('favorites').clear();
    _log('SETUP-EACH-1: after clear');
  });

  tearDown(() async {
    _log('TEARDOWN-EACH-0: before clear');
    await Hive.box('favorites').clear();
    _log('TEARDOWN-EACH-1: after clear');
  });

  tearDownAll(() async {
    _log('TEARDOWNALL-0: before Hive.close');
    await Hive.close();
    _log('TEARDOWNALL-1: after Hive.close');
  });

  testWidgets('FavoritesScreen displays empty state when there are no favorites', (tester) async {
    _log('TEST1-0: start');
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.light(), home: const FavoritesScreen()),
    );
    await tester.pump();
    _log('TEST1-1: pumped');

    expect(find.text('My Favorites'), findsOneWidget);
    expect(find.text('No favorites yet'), findsOneWidget);
    expect(find.text('Tap the heart icon to add wallpapers'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    _log('TEST1-2: assertions passed');
  });

  testWidgets('FavoritesScreen displays favorite wallpaper', (tester) async {
    _log('TEST2-0: start');
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
    _log('TEST2-1: png written to memory fs');

    final cacheManager = FakeCacheManager(testFile);

    _log('TEST2-2: before Hive.box(favorites).put');
    await Hive.box('favorites').put('test-key', {
      'id': 1,
      'photographer': 'Test Photographer',
      'src': {
        'original': 'https://example.com/original.jpg',
        'large': 'https://example.com/large.jpg',
        'medium': 'https://example.com/medium.jpg',
        'portrait': 'https://example.com/portrait.jpg',
      },
    });
    _log('TEST2-3: after Hive.box(favorites).put -- PUT COMPLETED');

    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.light(), home: FavoritesScreen(cacheManager: cacheManager)),
    );
    _log('TEST2-4: after pumpWidget');
    await tester.pump();
    _log('TEST2-5: after pump');

    expect(find.text('My Favorites'), findsOneWidget);
    _log('TEST2-6: title check passed');
    expect(find.text('No favorites yet'), findsNothing);
    _log('TEST2-7: empty-text check passed');
    expect(find.byType(GridView), findsOneWidget);
    _log('TEST2-8: GridView check passed');
    expect(find.byType(GestureDetector), findsWidgets);
    _log('TEST2-9: GestureDetector check passed');
  });
}


