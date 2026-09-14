class Wallpaper {
  final int id;
  final String photographer;
  final String originalUrl;
  final String largeUrl;
  final String portraitUrl;

  Wallpaper({
    required this.id,
    required this.photographer,
    required this.originalUrl,
    required this.largeUrl,
    required this.portraitUrl,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    final src = json['src'] as Map<String, dynamic>;

    return Wallpaper(
      id: json['id'] as int,
      photographer: json['photographer'] as String,
      originalUrl: src['original'] as String,
      largeUrl: src['large'] as String,
      portraitUrl: src['portrait'] as String,
    );
  }
}
