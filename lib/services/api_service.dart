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
}
