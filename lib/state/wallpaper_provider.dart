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
      final newWallpapers = await _apiService.getCuratedWallpapers(
        page: _currentPage,
        perPage: 20,
      );

      if (newWallpapers.isEmpty) {
        _hasMore = false;
      } else {
        _wallpapers.addAll(newWallpapers);
        _currentPage++;
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
