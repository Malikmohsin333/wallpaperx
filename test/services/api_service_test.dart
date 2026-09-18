import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';


import 'package:wallpaperx/models/wallpaper.dart';
import 'package:wallpaperx/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'PEXELS_API_KEY=test-api-key',
    );
  });

  test('ApiService can be created successfully', () {
    final apiService = ApiService();

    expect(apiService, isA<ApiService>());
  });

  test('getCuratedWallpapers parses mocked API response', () async {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    final apiService = ApiService(dio: dio);

    adapter.onGet(
      'https://api.pexels.com/v1/curated',
      (server) => server.reply(
        200,
        {
          'photos': [
            {
              'id': 101,
              'photographer': 'Test Photographer',
              'src': {
                'original': 'original-url',
                'large': 'large-url',
                'medium': 'medium-url',
                'portrait': 'portrait-url',
              },
            },
          ],
        },
      ),
      queryParameters: {
        'page': 1,
        'per_page': 20,
      },
    );

    final wallpapers = await apiService.getCuratedWallpapers();

    expect(wallpapers, hasLength(1));
    expect(wallpapers.first, isA<Wallpaper>());
    expect(wallpapers.first.id, 101);
    expect(wallpapers.first.photographer, 'Test Photographer');
    expect(wallpapers.first.originalUrl, 'original-url');
    expect(wallpapers.first.largeUrl, 'large-url');
    expect(wallpapers.first.mediumUrl, 'medium-url');
    expect(wallpapers.first.portraitUrl, 'portrait-url');
  });

  test('searchWallpapers parses mocked API response', () async {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    final apiService = ApiService(dio: dio);

    adapter.onGet(
      'https://api.pexels.com/v1/search',
      (server) => server.reply(
        200,
        {
          'photos': [
            {
              'id': 201,
              'photographer': 'Nature Photographer',
              'src': {
                'original': 'nature-original',
                'large': 'nature-large',
                'medium': 'nature-medium',
                'portrait': 'nature-portrait',
              },
            },
            {
              'id': 202,
              'photographer': 'City Photographer',
              'src': {
                'original': 'city-original',
                'large': 'city-large',
                'medium': 'city-medium',
                'portrait': 'city-portrait',
              },
            },
          ],
        },
      ),
      queryParameters: {
        'query': 'nature',
        'page': 2,
        'per_page': 10,
      },
    );

    final wallpapers = await apiService.searchWallpapers(
      query: 'nature',
      page: 2,
      perPage: 10,
    );

    expect(wallpapers, hasLength(2));
    expect(wallpapers[0].id, 201);
    expect(wallpapers[0].photographer, 'Nature Photographer');
    expect(wallpapers[0].originalUrl, 'nature-original');

    expect(wallpapers[1].id, 202);
    expect(wallpapers[1].photographer, 'City Photographer');
    expect(wallpapers[1].portraitUrl, 'city-portrait');
  });
  test('getCuratedWallpapers throws when API returns an error', () async {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    final apiService = ApiService(dio: dio);

    adapter.onGet(
      'https://api.pexels.com/v1/curated',
      (server) => server.reply(
        401,
        {
          'error': 'Invalid API key',
        },
      ),
      queryParameters: {
        'page': 1,
        'per_page': 20,
      },
    );

    expect(
      () => apiService.getCuratedWallpapers(),
      throwsA(isA<DioException>()),
    );
  });

  test('getWallpapers uses the curated endpoint for Curated category', () async {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    final apiService = ApiService(dio: dio);

    adapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=2&orientation=portrait',
      (server) => server.reply(
        200,
        {
          'photos': [
            {
              'id': 301,
              'photographer': 'Curated Photographer',
              'src': {
                'original': 'curated-original',
                'large': 'curated-large',
                'medium': 'curated-medium',
                'portrait': 'curated-portrait',
              },
            },
          ],
        },
      ),
    );

    final wallpapers = await apiService.getWallpapers(
      category: 'Curated',
      page: 2,
      perPage: 15,
    );

    expect(wallpapers, hasLength(1));
    expect(wallpapers.first.id, 301);
    expect(wallpapers.first.photographer, 'Curated Photographer');
    expect(wallpapers.first.portraitUrl, 'curated-portrait');
  });
  test('getWallpapers uses the 4K search endpoint for 4K Ultra HD category', () async {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    final apiService = ApiService(dio: dio);

    adapter.onGet(
      'https://api.pexels.com/v1/search?query=4k+wallpaper&per_page=15&page=1',
      (server) => server.reply(
        200,
        {
          'photos': [
            {
              'id': 401,
              'photographer': '4K Photographer',
              'src': {
                'original': '4k-original',
                'large': '4k-large',
                'medium': '4k-medium',
                'portrait': '4k-portrait',
              },
            },
          ],
        },
      ),
    );

    final wallpapers = await apiService.getWallpapers(
      category: '4K Ultra HD',
      page: 1,
      perPage: 15,
    );

    expect(wallpapers, hasLength(1));
    expect(wallpapers.first.id, 401);
    expect(wallpapers.first.photographer, '4K Photographer');
    expect(wallpapers.first.largeUrl, '4k-large');
  });
  test('getWallpapers uses the search endpoint for a normal category', () async {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    final apiService = ApiService(dio: dio);

    adapter.onGet(
      'https://api.pexels.com/v1/search?query=Nature&per_page=15&page=3',
      (server) => server.reply(
        200,
        {
          'photos': [
            {
              'id': 501,
              'photographer': 'Nature Photographer',
              'src': {
                'original': 'nature-original',
                'large': 'nature-large',
                'medium': 'nature-medium',
                'portrait': 'nature-portrait',
              },
            },
          ],
        },
      ),
    );

    final wallpapers = await apiService.getWallpapers(
      category: 'Nature',
      page: 3,
      perPage: 15,
    );

    expect(wallpapers, hasLength(1));
    expect(wallpapers.first.id, 501);
    expect(wallpapers.first.photographer, 'Nature Photographer');
    expect(wallpapers.first.mediumUrl, 'nature-medium');
  });
  test('getCuratedWallpapers returns an empty list when API has no photos', () async {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    final apiService = ApiService(dio: dio);

    adapter.onGet(
      'https://api.pexels.com/v1/curated',
      (server) => server.reply(
        200,
        {
          'photos': [],
        },
      ),
      queryParameters: {
        'page': 1,
        'per_page': 20,
      },
    );

    final wallpapers = await apiService.getCuratedWallpapers();

    expect(wallpapers, isEmpty);
  });
  test('getWallpapers uses the curated endpoint for Trending category', () async {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    final apiService = ApiService(dio: dio);

    adapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=2&orientation=portrait',
      (server) => server.reply(
        200,
        {
          'photos': [
            {
              'id': 601,
              'photographer': 'Trending Photographer',
              'src': {
                'original': 'trending-original',
                'large': 'trending-large',
                'medium': 'trending-medium',
                'portrait': 'trending-portrait',
              },
            },
          ],
        },
      ),
    );

    final wallpapers = await apiService.getWallpapers(
      category: 'Trending',
      page: 2,
      perPage: 15,
    );

    expect(wallpapers, hasLength(1));
    expect(wallpapers.first.id, 601);
    expect(wallpapers.first.photographer, 'Trending Photographer');
  });

  test('getWallpapers uses the offset curated endpoint for New category', () async {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    final apiService = ApiService(dio: dio);

    adapter.onGet(
      'https://api.pexels.com/v1/curated?per_page=15&page=22&orientation=portrait',
      (server) => server.reply(
        200,
        {
          'photos': [
            {
              'id': 701,
              'photographer': 'New Photographer',
              'src': {
                'original': 'new-original',
                'large': 'new-large',
                'medium': 'new-medium',
                'portrait': 'new-portrait',
              },
            },
          ],
        },
      ),
    );

    final wallpapers = await apiService.getWallpapers(
      category: 'New',
      page: 2,
      perPage: 15,
    );

    expect(wallpapers, hasLength(1));
    expect(wallpapers.first.id, 701);
    expect(wallpapers.first.photographer, 'New Photographer');
  });

  test('getWallpapers uses a random curated page for Random category', () async {
    final dio = Dio();
    final adapter = DioAdapter(
      dio: dio,
      matcher: const UrlRequestMatcher(),
    );
    final apiService = ApiService(dio: dio);

    adapter.onGet(
      RegExp(r'https://api\.pexels\.com/v1/curated.*'),
      (server) => server.reply(
        200,
        {
          'photos': [
            {
              'id': 801,
              'photographer': 'Random Photographer',
              'src': {
                'original': 'random-original',
                'large': 'random-large',
                'medium': 'random-medium',
                'portrait': 'random-portrait',
              },
            },
          ],
        },
      ),

    );

    final wallpapers = await apiService.getWallpapers(
      category: 'Random',
      page: 3,
      perPage: 15,
    );

    expect(wallpapers, hasLength(1));
    expect(wallpapers.first.id, 801);
    expect(wallpapers.first.photographer, 'Random Photographer');
  });
}