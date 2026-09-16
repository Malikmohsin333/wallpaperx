import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wallpaper.dart';
import '../widgets/animated_message.dart';
import '../widgets/wallpaper_option.dart';
import '../widgets/detail_action_button.dart';
import '../services/image_download_service.dart';

class DetailScreen extends StatefulWidget {
  final Wallpaper photo;

  const DetailScreen({
    super.key,
    required this.photo,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class WallpaperManager {
  static const int flagsystem = 1;
  static const int flaglock = 2;
}

class _DetailScreenState extends State<DetailScreen> {
  final ImageDownloadService _imageDownloadService = ImageDownloadService();
  late Box favoritesBox;
  bool isFavorite = false;
  bool isSettingWallpaper = false;

  Future<bool> _requestPermission() async {
    if (await Permission.photos.isGranted) return true;
    if (await Permission.storage.isGranted) return true;

    if (await Permission.photos.request().isGranted) return true;
    if (await Permission.storage.request().isGranted) return true;

    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
          'Please allow storage permission to save wallpapers.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return false;
      return await _requestPermission();
    }

    return false;
  }

  void _showAnimatedMessage(
    String message, {
    bool isSuccess = true,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => AnimatedMessage(
        message: message,
        isSuccess: isSuccess,
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(
      const Duration(seconds: 2),
      () => overlayEntry.remove(),
    );
  }
  void _toggleFavorite() {
    final id = widget.photo.id.toString();

    if (isFavorite) {
      favoritesBox.delete(id);

      setState(() {
        isFavorite = false;
      });

      _showAnimatedMessage(
        'Removed from Favorites',
        isSuccess: true,
      );
    } else {
      final photo = {
        'id': widget.photo.id,
        'photographer': widget.photo.photographer,
        'src': {
          'original': widget.photo.originalUrl,
          'large': widget.photo.largeUrl,
          'medium': widget.photo.mediumUrl,
          'portrait': widget.photo.portraitUrl,
        },
      };

      favoritesBox.put(id, photo);

      setState(() {
        isFavorite = true;
      });

      _showAnimatedMessage(
        'Added to Favorites',
        isSuccess: true,
      );
    }
  }

  Future<void> _saveImage(
    BuildContext context,
    String imageUrl,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final downloadCount = (prefs.getInt('download_count') ?? 0) + 1;

    await prefs.setInt(
      'download_count',
      downloadCount,
    );

    final hasPermission = await _requestPermission();

    if (!hasPermission) {
      if (context.mounted) {
        _showAnimatedMessage(
          'Storage permission denied',
          isSuccess: false,
        );
      }

      return;
    }

    try {
      final bytes = await _imageDownloadService.downloadImage(imageUrl);

      const platform = MethodChannel('download_channel');

      final String? result = await platform.invokeMethod(
        'saveToGallery',
        {
          'imageBytes': bytes,
          'fileName': 'wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg',
        },
      );

      if (result == 'success' && context.mounted) {
        _showAnimatedMessage(
          'Wallpaper Saved to Gallery',
          isSuccess: true,
        );
      } else if (context.mounted) {
        _showAnimatedMessage(
          'Failed to save wallpaper',
          isSuccess: false,
        );
      }
    } catch (e) {
      debugPrint('Error: $e');

      if (context.mounted) {
        _showAnimatedMessage(
          'Failed to save wallpaper',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _shareWallpaper(String imageUrl) async {
    try {
      final bytes = await _imageDownloadService.downloadImage(imageUrl);

      final tempDir = await getTemporaryDirectory();

      final file = File(
        '${tempDir.path}/share_wallpaper.jpg',
      );

      await file.writeAsBytes(bytes);

      const playStoreLink =
          'https://play.google.com/store/apps/details?id=com.example.wallpaperx';

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Check out this amazing wallpaper from WallpaperX!\n\nDownload more: $playStoreLink',
      );

      await file.delete();

      _showAnimatedMessage(
        'Shared successfully',
        isSuccess: true,
      );
    } catch (e) {
      debugPrint('Share error: $e');

      if (mounted) {
        _showAnimatedMessage(
          'Failed to share wallpaper',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _setWallpaper(
    String imageUrl,
    int type,
  ) async {
    _showAnimatedMessage(
      'Setting wallpaper...',
      isSuccess: true,
    );

    setState(() {
      isSettingWallpaper = true;
    });

    try {
      final bytes = await _imageDownloadService.downloadImage(imageUrl);

      final tempDir = await getTemporaryDirectory();

      final file = File(
        '${tempDir.path}/temp_wallpaper.jpg',
      );

      await file.writeAsBytes(bytes);

      const platform = MethodChannel('wallpaper_channel');

      if (type == 2) {
        final bool success = await platform.invokeMethod(
          'setWallpaperDirect',
          {
            'path': file.path,
            'type': WallpaperManager.flagsystem | WallpaperManager.flaglock,
          },
        );

        if (mounted) {
          _showAnimatedMessage(
            success ? 'Wallpaper Set Successfully!' : 'Failed to set wallpaper',
            isSuccess: success,
          );
        }
      } else {
        await platform.invokeMethod(
          'setWallpaper',
          {
            'path': file.path,
            'type': type,
          },
        );
      }

      await file.delete();
    } catch (e) {
      debugPrint('Set wallpaper error: $e');

      if (mounted) {
        _showAnimatedMessage(
          'Failed to set wallpaper',
          isSuccess: false,
        );
      }
    }

    if (mounted) {
      setState(() {
        isSettingWallpaper = false;
      });
    }
  }

  void _showSetWallpaperOptions(
    BuildContext context,
    String imageUrl,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set as Wallpaper',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                WallpaperOption(
                  icon: Icons.home,
                  label: 'Home Screen',
                  onTap: () {
                    Navigator.pop(context);
                    _setWallpaper(imageUrl, 0);
                  },
                  isDarkMode: isDarkMode,
                ),
                WallpaperOption(
                  icon: Icons.lock,
                  label: 'Lock Screen',
                  onTap: () {
                    Navigator.pop(context);
                    _setWallpaper(imageUrl, 1);
                  },
                  isDarkMode: isDarkMode,
                ),
                WallpaperOption(
                  icon: Icons.home_work,
                  label: 'Both',
                  onTap: () {
                    Navigator.pop(context);
                    _setWallpaper(imageUrl, 2);
                  },
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = widget.photo.originalUrl;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite
                  ? Colors.red
                  : (isDarkMode ? Colors.white : Colors.black),
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
          Container(
            color: isDarkMode ? Colors.black : Colors.white,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              top: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DetailActionButton(
                  icon: Icons.download,
                  label: 'Download',
                  onTap: () => _saveImage(context, imageUrl),
                  isDarkMode: isDarkMode,
                ),
                DetailActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () => _shareWallpaper(imageUrl),
                  isDarkMode: isDarkMode,
                ),
                DetailActionButton(
                  icon: Icons.wallpaper,
                  label: isSettingWallpaper ? 'Setting...' : 'Set as',
                  onTap: isSettingWallpaper
                      ? null
                      : () => _showSetWallpaperOptions(
                            context,
                            imageUrl,
                          ),
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

