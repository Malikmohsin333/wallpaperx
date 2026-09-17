import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:wallpaperx/services/image_download_service.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late ImageDownloadService service;

  setUp(() {
    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);
    service = ImageDownloadService(dio: dio);
  });

  test('downloads image bytes successfully', () async {
    const imageUrl = 'https://example.com/wallpaper.jpg';
    final expectedBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

    dioAdapter.onGet(
      imageUrl,
      (server) => server.reply(
        200,
        expectedBytes,
      ),
    );

    final result = await service.downloadImage(imageUrl);

    expect(result, expectedBytes);
    expect(result.length, 5);
  });

  test('throws when image download fails', () async {
    const imageUrl = 'https://example.com/error.jpg';

    dioAdapter.onGet(
      imageUrl,
      (server) => server.reply(
        500,
        {'error': 'Download failed'},
      ),
    );

    expect(
      () => service.downloadImage(imageUrl),
      throwsA(isA<DioException>()),
    );
  });
}
