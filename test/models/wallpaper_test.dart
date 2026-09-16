import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaperx/models/wallpaper.dart';

void main() {
  test('Wallpaper.fromJson creates a Wallpaper correctly', () {
    final json = {
      'id': 123,
      'photographer': 'Test Photographer',
      'src': {
        'original': 'https://example.com/original.jpg',
        'large': 'https://example.com/large.jpg',
        'medium': 'https://example.com/medium.jpg',
        'portrait': 'https://example.com/portrait.jpg',
      },
    };

    final wallpaper = Wallpaper.fromJson(json);

    expect(wallpaper.id, 123);
    expect(wallpaper.photographer, 'Test Photographer');
    expect(wallpaper.originalUrl, 'https://example.com/original.jpg');
    expect(wallpaper.largeUrl, 'https://example.com/large.jpg');
    expect(wallpaper.mediumUrl, 'https://example.com/medium.jpg');
    expect(wallpaper.portraitUrl, 'https://example.com/portrait.jpg');
  });

  test('Wallpaper.fromJson preserves different valid values', () {
    final json = {
      'id': 98765,
      'photographer': 'Another Photographer',
      'src': {
        'original': 'original-url',
        'large': 'large-url',
        'medium': 'medium-url',
        'portrait': 'portrait-url',
      },
    };

    final wallpaper = Wallpaper.fromJson(json);

    expect(wallpaper.id, 98765);
    expect(wallpaper.photographer, 'Another Photographer');
    expect(wallpaper.originalUrl, 'original-url');
    expect(wallpaper.largeUrl, 'large-url');
    expect(wallpaper.mediumUrl, 'medium-url');
    expect(wallpaper.portraitUrl, 'portrait-url');
  });
}
