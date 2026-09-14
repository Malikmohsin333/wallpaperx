import 'package:flutter/foundation.dart';

import '../models/wallpaper.dart';
import '../services/api_service.dart';

class WallpaperProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  final List<Wallpaper> _wallpapers = [];

  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  List<Wallpaper> get wallpapers => List.unmodifiable(_wallpapers);

  bool get isLoading => _isLoading;

  bool get hasMore => _hasMore;

  String? get error => _error;

    Future<void> loadWallpapers({
    String category = 'Curated',
    bool refresh = false,
  }) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _wallpapers.clear();
    }

    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newWallpapers = await _apiService.getWallpapers(
        category: category,
        page: _currentPage,
        perPage: 15,
      );

      if (newWallpapers.isEmpty) {
        _hasMore = false;
      } else {
        final existingIds = _wallpapers.map((wallpaper) => wallpaper.id).toSet();

        final uniqueWallpapers = newWallpapers
            .where((wallpaper) => !existingIds.contains(wallpaper.id))
            .toList();

        _wallpapers.addAll(uniqueWallpapers);
        _currentPage++;
        _hasMore = newWallpapers.isNotEmpty;
      }
    } catch (e) {
      _error = 'Failed to load wallpapers';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearWallpapers() {
    _wallpapers.clear();
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }
}
