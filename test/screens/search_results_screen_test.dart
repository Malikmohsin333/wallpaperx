import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wallpaperx/models/wallpaper.dart';
import 'package:wallpaperx/screens/detail_screen.dart';
import 'package:wallpaperx/screens/search_results_screen.dart';
import 'package:wallpaperx/services/api_service.dart';

class FakeApiService extends ApiService {
  List<Wallpaper> results;
  bool shouldThrow;

  FakeApiService({
    this.results = const [],
    this.shouldThrow = false,
  });

  @override
  Future<List<Wallpaper>> searchWallpapers({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    if (shouldThrow) {
      throw Exception('Test API error');
    }

    return List<Wallpaper>.from(results);
  }
}

Wallpaper _wallpaper(int id) {
  return Wallpaper(
    id: id,
    photographer: 'Test Photographer',
    originalUrl: 'https://example.com/original-$id.jpg',
    largeUrl: 'https://example.com/large-$id.jpg',
    mediumUrl: 'https://example.com/medium-$id.jpg',
    portraitUrl: 'https://example.com/portrait-$id.jpg',
  );
}

Widget _app({
  required FakeApiService apiService,
  String query = 'Mountains',
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    themeMode: themeMode,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    home: SearchResultsScreen(
      searchQuery: query,
      apiService: apiService,
    ),
  );
}

void main() {
  testWidgets('CustomSearchDelegate actions, leading and results',
      (tester) async {
    final delegate = CustomSearchDelegate();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: delegate,
                  );
                },
                child: const Text('Open Search'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Search'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'Mountains');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(delegate.query, '');

    await tester.enterText(find.byType(EditableText), 'Cars');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Open Search'), findsOneWidget);
  });

  testWidgets('CustomSearchDelegate builds results and dark suggestions',
      (tester) async {
    final delegate = CustomSearchDelegate();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: delegate,
                );
              },
              child: const Text('Open Search'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Search'));
    await tester.pumpAndSettle();

    expect(find.text('Search for wallpapers'), findsOneWidget);
    expect(find.text('e.g., Mountains, Cars, Pakistan'), findsOneWidget);

    delegate.query = 'Nature';

    final results = delegate.buildResults(tester.element(find.text('Search for wallpapers')));

    expect(results, isA<Container>());
  });
  testWidgets('shows loading state while search is in progress', (tester) async {
    final apiService = FakeApiService();

    await tester.pumpWidget(
      _app(apiService: apiService),
    );

    expect(find.text('Searching...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('displays search results', (tester) async {
    final apiService = FakeApiService(
      results: [
        _wallpaper(1),
        _wallpaper(2),
      ],
    );

    await tester.pumpWidget(
      _app(apiService: apiService),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Search: Mountains'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('shows no results state when API returns empty list',
      (tester) async {
    final apiService = FakeApiService();

    await tester.pumpWidget(
      _app(apiService: apiService),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.text('No results found'), findsOneWidget);
    expect(find.text('Try a different keyword'), findsOneWidget);
  });

  testWidgets('shows error state when API throws', (tester) async {
    final apiService = FakeApiService(
      shouldThrow: true,
    );

    await tester.pumpWidget(
      _app(apiService: apiService),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.text('Failed to load search results'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Failed to load search results'), findsOneWidget);
  });



  testWidgets('back button pops the screen', (tester) async {
    final apiService = FakeApiService();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchResultsScreen(
                        searchQuery: 'Cars',
                        apiService: apiService,
                      ),
                    ),
                  );
                },
                child: const Text('Open Search'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SearchResultsScreen), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SearchResultsScreen), findsNothing);
  });
  testWidgets('loads more results when scrolled near bottom',
      (tester) async {
    final apiService = FakeApiService(
      results: List.generate(20, (index) => _wallpaper(index + 1)),
    );

    await tester.pumpWidget(
      _app(apiService: apiService),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final grid = find.byType(GridView);
    expect(grid, findsOneWidget);

    await tester.drag(grid, const Offset(0, -5000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(GridView), findsOneWidget);
  });
  testWidgets('opens detail screen when wallpaper is tapped',
      (tester) async {
    final apiService = FakeApiService(
      results: [_wallpaper(99)],
    );

    await tester.pumpWidget(
      _app(apiService: apiService),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(GridView), findsOneWidget);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DetailScreen), findsOneWidget);
  });
  testWidgets('shows image error widget for a wallpaper result',
      (tester) async {
    final apiService = FakeApiService(
      results: [_wallpaper(10)],
    );

    await tester.pumpWidget(
      _app(apiService: apiService),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsOneWidget);

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );

    final errorWidget = image.errorWidget!(
      tester.element(find.byType(CachedNetworkImage)),
      image.imageUrl,
      Exception('Test image error'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: errorWidget,
        ),
      ),
    );

    expect(find.byIcon(Icons.error), findsOneWidget);
  });
  testWidgets('builds correctly in dark theme', (tester) async {
    final apiService = FakeApiService(
      results: [_wallpaper(20)],
    );

    await tester.pumpWidget(
      _app(
        apiService: apiService,
        themeMode: ThemeMode.dark,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Search: Mountains'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('CustomSearchDelegate shows suggestions', (tester) async {
    final delegate = CustomSearchDelegate();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: delegate,
                  );
                },
                child: const Text('Open Search'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Search for wallpapers'), findsOneWidget);
    expect(find.text('e.g., Mountains, Cars, Pakistan'), findsOneWidget);
  });
}
















