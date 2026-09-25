import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_test/hive_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wallpaperx/services/api_service.dart';
import 'package:wallpaperx/state/theme_provider.dart';
import 'package:wallpaperx/state/wallpaper_provider.dart';
import 'package:wallpaperx/screens/home_screen.dart';

class _FakeConnectivityPlatform extends ConnectivityPlatform {
  final List<ConnectivityResult> result;

  _FakeConnectivityPlatform({
    this.result = const [ConnectivityResult.wifi],
  });

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return result;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value(result);
}

Map<String, dynamic> _photo(int id, String photographer) {
  return {
    'id': id,
    'photographer': photographer,
    'src': {
      'original': 'https://example.com/$id-original.jpg',
      'large': 'https://example.com/$id-large.jpg',
      'medium': 'https://example.com/$id-medium.jpg',
      'portrait': 'https://example.com/$id-portrait.jpg',
    },
  };
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late DioAdapter dioAdapter;
  late WallpaperProvider provider;
  late Directory testTempDir;

  setUpAll(() async {
    dotenv.loadFromString(
      envString: 'PEXELS_API_KEY=test-api-key',
    );

    await setUpTestHive();

    await Hive.openBox('favorites');
    await Hive.openBox('recently_viewed');
    await Hive.openBox('settings');
  });

  setUp(() async {
    testTempDir = await Directory.systemTemp.createTemp('wallpaperx_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => testTempDir.path,
    );
    SharedPreferences.setMockInitialValues({});

    await Hive.box('favorites').clear();
    await Hive.box('recently_viewed').clear();

    ConnectivityPlatform.instance = _FakeConnectivityPlatform(
      result: const [ConnectivityResult.wifi],
    );

    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);
    provider = WallpaperProvider(
      apiService: ApiService(dio: dio),
    );
  });

  tearDown(() async {
    provider.dispose();
    if (await testTempDir.exists()) {
      await testTempDir.delete(recursive: true);
    }
  });
  testWidgets('HomeScreen renders and loads wallpapers online',
      (tester) async {
    dioAdapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=1&orientation=portrait',
      (server) => server.reply(
        200,
        {
          'photos': [
            _photo(1, 'Photographer One'),
            _photo(2, 'Photographer Two'),
          ],
        },
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WallpaperProvider>.value(
            value: provider,
          ),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(isDarkMode: true),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('WallpaperX'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Discover Beautiful\nWallpapers'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Trending Now'), findsOneWidget);
  });
  testWidgets('HomeScreen shows no internet state when offline',
      (tester) async {
    ConnectivityPlatform.instance = _FakeConnectivityPlatform(
      result: const [ConnectivityResult.none],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WallpaperProvider>.value(
            value: provider,
          ),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(isDarkMode: true),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('No Internet\nConnection'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Curated'), findsNothing);
    expect(provider.wallpapers, isEmpty);
  });
  testWidgets('HomeScreen toggles theme mode', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WallpaperProvider>.value(
            value: provider,
          ),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(isDarkMode: true),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    final themeProvider =
        Provider.of<ThemeProvider>(
          tester.element(find.byType(HomeScreen)),
          listen: false,
        );

    expect(themeProvider.isDarkMode, isTrue);

    await tester.tap(find.byIcon(Icons.light_mode));
    await tester.pump();

    expect(themeProvider.isDarkMode, isFalse);
    expect(Hive.box('settings').get('isDarkMode'), isFalse);
  });
  testWidgets('HomeScreen changes category and reloads wallpapers',
      (tester) async {
    dioAdapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=1&orientation=portrait',
      (server) => server.reply(
        200,
        {
          'photos': [
            _photo(1, 'Curated Photographer'),
          ],
        },
      ),
    );

    dioAdapter.onGet(
      'https://api.pexels.com/v1/search?query=Trending&per_page=15&page=1&orientation=portrait',
      (server) => server.reply(
        200,
        {
          'photos': [
            _photo(2, 'Trending Photographer'),
          ],
        },
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WallpaperProvider>.value(
            value: provider,
          ),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(isDarkMode: true),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Trending'), findsOneWidget);

    await tester.tap(find.text('Trending').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Trending Now'), findsOneWidget);
    expect(provider.wallpapers, isNotEmpty);
  });



  testWidgets('HomeScreen shows offline message when search is tapped offline',
      (tester) async {
    ConnectivityPlatform.instance = _FakeConnectivityPlatform(
      result: const [ConnectivityResult.none],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WallpaperProvider>.value(
            value: provider,
          ),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(isDarkMode: true),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    expect(find.text('No internet connection'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  });


  testWidgets('HomeScreen opens settings menu',
      (tester) async {
    ConnectivityPlatform.instance = _FakeConnectivityPlatform(
      result: const [ConnectivityResult.none],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WallpaperProvider>.value(
            value: provider,
          ),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(isDarkMode: true),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();

    expect(find.text('Clear Cache'), findsOneWidget);
    expect(find.text('Share App'), findsOneWidget);
    expect(find.text('Rate Us'), findsOneWidget);
  });


  testWidgets('HomeScreen clears cache from settings',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    ConnectivityPlatform.instance = _FakeConnectivityPlatform(
      result: const [ConnectivityResult.none],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WallpaperProvider>.value(
            value: provider,
          ),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(isDarkMode: true),
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Clear Cache'), findsOneWidget);

    await tester.tap(find.text('Clear Cache'));

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Cache cleared successfully!'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
  });

}










