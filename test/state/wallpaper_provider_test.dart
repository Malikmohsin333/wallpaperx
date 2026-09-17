import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:wallpaperx/models/wallpaper.dart';
import 'package:wallpaperx/services/api_service.dart';
import 'package:wallpaperx/state/wallpaper_provider.dart';

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
  late Dio dio;
  late DioAdapter dioAdapter;
  late ApiService apiService;
  late WallpaperProvider provider;

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'PEXELS_API_KEY=test-api-key',
    );
  });

  setUp(() {
    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);
    apiService = ApiService(dio: dio);
    provider = WallpaperProvider(apiService: apiService);
  });

  tearDown(() {
    provider.dispose();
  });

  test('initial state is correct', () {
    expect(provider.wallpapers, isEmpty);
    expect(provider.isLoading, isFalse);
    expect(provider.hasMore, isTrue);
    expect(provider.error, isNull);
  });

  test('loads wallpapers successfully', () async {
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

    await provider.loadWallpapers();

    expect(provider.wallpapers, hasLength(2));
    expect(provider.wallpapers.first, isA<Wallpaper>());
    expect(provider.wallpapers.first.id, 1);
    expect(provider.wallpapers.last.id, 2);
    expect(provider.isLoading, isFalse);
    expect(provider.hasMore, isTrue);
    expect(provider.error, isNull);
  });

  test('removes duplicate wallpaper IDs', () async {
    dioAdapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=1&orientation=portrait',
      (server) => server.reply(
        200,
        {
          'photos': [
            _photo(1, 'First'),
            _photo(2, 'Second'),
          ],
        },
      ),
    );

    await provider.loadWallpapers();

    dioAdapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=2&orientation=portrait',
      (server) => server.reply(
        200,
        {
          'photos': [
            _photo(2, 'Duplicate'),
            _photo(3, 'Third'),
          ],
        },
      ),
    );

    await provider.loadWallpapers();

    expect(provider.wallpapers, hasLength(3));
    expect(
      provider.wallpapers.map((wallpaper) => wallpaper.id),
      [1, 2, 3],
    );
  });

  test('sets hasMore to false when API returns empty list', () async {
    dioAdapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=1&orientation=portrait',
      (server) => server.reply(
        200,
        {'photos': []},
      ),
    );

    await provider.loadWallpapers();

    expect(provider.wallpapers, isEmpty);
    expect(provider.hasMore, isFalse);
    expect(provider.isLoading, isFalse);
    expect(provider.error, isNull);
  });

  test('handles API errors', () async {
    dioAdapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=1&orientation=portrait',
      (server) => server.reply(
        500,
        {'error': 'Server error'},
      ),
    );

    await provider.loadWallpapers();

    expect(provider.wallpapers, isEmpty);
    expect(provider.isLoading, isFalse);
    expect(provider.hasMore, isTrue);
    expect(provider.error, 'Failed to load wallpapers');
  });

  test('refresh clears existing wallpapers and reloads from page one',
      () async {
    dioAdapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=1&orientation=portrait',
      (server) => server.reply(
        200,
        {
          'photos': [
            _photo(1, 'First'),
          ],
        },
      ),
    );

    await provider.loadWallpapers();

    expect(provider.wallpapers, hasLength(1));

    dioAdapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=1&orientation=portrait',
      (server) => server.reply(
        200,
        {
          'photos': [
            _photo(10, 'Refreshed'),
          ],
        },
      ),
    );

    await provider.loadWallpapers(refresh: true);

    expect(provider.wallpapers, hasLength(1));
    expect(provider.wallpapers.first.id, 10);
  });

  test('loadMoreWallpapers loads the next page', () async {
    dioAdapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=1&orientation=portrait',
      (server) => server.reply(
        200,
        {
          'photos': [
            _photo(1, 'First'),
          ],
        },
      ),
    );

    await provider.loadWallpapers();

    dioAdapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=2&orientation=portrait',
      (server) => server.reply(
        200,
        {
          'photos': [
            _photo(2, 'Second'),
          ],
        },
      ),
    );

    await provider.loadMoreWallpapers(category: 'Curated');

    expect(provider.wallpapers, hasLength(2));
    expect(provider.wallpapers.last.id, 2);
  });

  test('clearWallpapers resets provider state', () async {
    dioAdapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=1&orientation=portrait',
      (server) => server.reply(
        200,
        {
          'photos': [
            _photo(1, 'First'),
          ],
        },
      ),
    );

    await provider.loadWallpapers();

    provider.clearWallpapers();

    expect(provider.wallpapers, isEmpty);
    expect(provider.hasMore, isTrue);
    expect(provider.error, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('does not load when hasMore is false', () async {
    dioAdapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=1&orientation=portrait',
      (server) => server.reply(
        200,
        {'photos': []},
      ),
    );

    await provider.loadWallpapers();

    expect(provider.hasMore, isFalse);

    await provider.loadWallpapers();

    expect(provider.wallpapers, isEmpty);
  });

  test('loadMoreWallpapers returns when hasMore is false', () async {
    dioAdapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=1&orientation=portrait',
      (server) => server.reply(
        200,
        {'photos': []},
      ),
    );

    await provider.loadWallpapers();

    await provider.loadMoreWallpapers(category: 'Curated');

    expect(provider.wallpapers, isEmpty);
    expect(provider.hasMore, isFalse);
  });
}
