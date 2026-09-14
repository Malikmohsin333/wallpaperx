import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/wallpaper.dart';

class ApiService {
  final Dio _dio = Dio();

  String get _apiKey => dotenv.env['PEXELS_API_KEY'] ?? '';

  Future<List<Wallpaper>> getCuratedWallpapers({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      'https://api.pexels.com/v1/curated',
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
      options: Options(
        headers: {
          'Authorization': _apiKey,
        },
      ),
    );

    final photos = response.data['photos'] as List;

    return photos
        .map(
          (photo) => Wallpaper.fromJson(
            photo as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<Wallpaper>> searchWallpapers({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      'https://api.pexels.com/v1/search',
      queryParameters: {
        'query': query,
        'page': page,
        'per_page': perPage,
      },
      options: Options(
        headers: {
          'Authorization': _apiKey,
        },
      ),
    );

    final photos = response.data['photos'] as List;

        return photos
        .map(
          (photo) => Wallpaper.fromJson(
            photo as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<Wallpaper>> getWallpapers({
    required String category,
    int page = 1,
    int perPage = 15,
  }) async {
    String endpoint;

    if (category == 'Curated') {
      endpoint =
          'https://api.pexels.com/v1/curated?per_page=$perPage&page=$page&orientation=portrait';
    } else if (category == '4K Ultra HD') {
      endpoint =
          'https://api.pexels.com/v1/search?query=4k+wallpaper&per_page=$perPage&page=$page';
    } else if (category == 'Trending') {
      endpoint =
          'https://api.pexels.com/v1/curated?per_page=$perPage&page=$page&orientation=portrait';
    } else if (category == 'New') {
      endpoint =
          'https://api.pexels.com/v1/curated?per_page=$perPage&page=${page + 20}&orientation=portrait';
    } else if (category == 'Random') {
      final seed = (DateTime.now().millisecondsSinceEpoch % 15) + page;
      endpoint =
          'https://api.pexels.com/v1/curated?per_page=$perPage&page=$seed&orientation=portrait';
    } else {
      endpoint =
          'https://api.pexels.com/v1/search?query=$category&per_page=$perPage&page=$page';
    }

    final response = await _dio.get(
      endpoint,
      options: Options(
        headers: {
          'Authorization': _apiKey,
        },
      ),
    );

    final photos = response.data['photos'] as List;

    return photos
        .map(
          (photo) => Wallpaper.fromJson(
            photo as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
