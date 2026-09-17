import 'dart:typed_data';

import 'package:dio/dio.dart';

class ImageDownloadService {
  final Dio _dio;

  ImageDownloadService({Dio? dio}) : _dio = dio ?? Dio();

  Future<Uint8List> downloadImage(String imageUrl) async {
    final response = await _dio.get(
      imageUrl,
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );

    return response.data as Uint8List;
  }
}
