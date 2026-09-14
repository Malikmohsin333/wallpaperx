import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'state/wallpaper_provider.dart';
import 'app.dart' as app;
import 'state/theme_provider.dart' as theme;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox('favorites');
  await Hive.openBox('recently_viewed');

  final settingsBox = await Hive.openBox('settings');
  // ignore: unused_local_variable
  final isDarkMode = settingsBox.get('isDarkMode', defaultValue: true);

  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => theme.ThemeProvider(isDarkMode: isDarkMode),
        ),
        ChangeNotifierProvider(
          create: (_) => WallpaperProvider(),
        ),
      ],
      child: app.WallpaperXApp(showOnboarding: !showOnboarding),
    ),
  );
}

class LegacyThemeProvider extends ChangeNotifier {
  bool _isDarkMode;
  LegacyThemeProvider({required bool isDarkMode}) : _isDarkMode = isDarkMode;
  bool get isDarkMode => _isDarkMode;
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    final settingsBox = Hive.box('settings');
    settingsBox.put('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}

// All Categories Screen

// Custom Search Delegate

// Search Results Screen

// Detail Screen
class DetailScreen extends StatefulWidget {
  final dynamic photo;
  const DetailScreen({super.key, required this.photo});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

// FIX: WallpaperManager constants defined locally instead of using undefined package
class WallpaperManager {
  static const int flagsystem = 1;
  static const int flaglock = 2;
}

class _DetailScreenState extends State<DetailScreen> {
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

  void _showAnimatedMessage(String message, {bool isSuccess = true}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80,
        left: 20,
        right: 20,
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
  }

  @override
  void initState() {
    super.initState();
    favoritesBox = Hive.box('favorites');
    _checkIfFavorite();
  }

  void _checkIfFavorite() {
    final id = widget.photo['id'].toString();
    setState(() {
      isFavorite = favoritesBox.containsKey(id);
    });
  }

  void _toggleFavorite() {
    final id = widget.photo['id'].toString();
    if (isFavorite) {
      favoritesBox.delete(id);
      setState(() => isFavorite = false);
      _showAnimatedMessage('Removed from Favorites', isSuccess: true);
    } else {
      favoritesBox.put(id, widget.photo);
      setState(() => isFavorite = true);
      _showAnimatedMessage('Added to Favorites', isSuccess: true);
    }
  }

  Future<void> _saveImage(BuildContext context, String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final downloadCount = (prefs.getInt('download_count') ?? 0) + 1;
    await prefs.setInt('download_count', downloadCount);

    final hasPermission = await _requestPermission();
    if (!hasPermission) {
      if (context.mounted) {
        _showAnimatedMessage('Storage permission denied', isSuccess: false);
      }
      return;
    }

    try {
      final response = await Dio().get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data as Uint8List;

      const platform = MethodChannel('download_channel');
      final String? result = await platform.invokeMethod('saveToGallery', {
        'imageBytes': bytes,
        'fileName': 'wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg',
      });

      if (result == 'success' && context.mounted) {
        _showAnimatedMessage('Wallpaper Saved to Gallery', isSuccess: true);
      } else if (context.mounted) {
        _showAnimatedMessage('Failed to save wallpaper', isSuccess: false);
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (context.mounted) {
        _showAnimatedMessage('Failed to save wallpaper', isSuccess: false);
      }
    }
  }

  Future<void> _shareWallpaper(String imageUrl) async {
    try {
      final response = await Dio().get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data as Uint8List;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_wallpaper.jpg');
      await file.writeAsBytes(bytes);

      const playStoreLink =
          'https://play.google.com/store/apps/details?id=com.example.wallpaperx';

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Check out this amazing wallpaper from WallpaperX!\n\nDownload more: $playStoreLink',
      );

      await file.delete();
      _showAnimatedMessage('Shared successfully', isSuccess: true);
    } catch (e) {
      debugPrint('Share error: $e');
      if (mounted) {
        _showAnimatedMessage('Failed to share wallpaper', isSuccess: false);
      }
    }
  }

  Future<void> _setWallpaper(String imageUrl, int type) async {
    _showAnimatedMessage('Setting wallpaper...', isSuccess: true);
    setState(() => isSettingWallpaper = true);

    try {
      final response = await Dio().get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data as Uint8List;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/temp_wallpaper.jpg');
      await file.writeAsBytes(bytes);

      const platform = MethodChannel('wallpaper_channel');

      if (type == 2) {
        // FIX: use local WallpaperManager constants
        final bool success = await platform.invokeMethod('setWallpaperDirect', {
          'path': file.path,
          'type': WallpaperManager.flagsystem | WallpaperManager.flaglock,
        });
        if (mounted) {
          _showAnimatedMessage(
            success ? 'Wallpaper Set Successfully!' : 'Failed to set wallpaper',
            isSuccess: success,
          );
        }
      } else {
        await platform.invokeMethod('setWallpaper', {
          'path': file.path,
          'type': type,
        });
      }

      await file.delete();
    } catch (e) {
      debugPrint('Set wallpaper error: $e');
      if (mounted) {
        _showAnimatedMessage('Failed to set wallpaper', isSuccess: false);
      }
    }

    if (mounted) setState(() => isSettingWallpaper = false);
  }

  void _showSetWallpaperOptions(BuildContext context, String imageUrl) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                _buildWallpaperOption(
                  icon: Icons.home,
                  label: 'Home Screen',
                  onTap: () {
                    Navigator.pop(context);
                    _setWallpaper(imageUrl, 0);
                  },
                  isDarkMode: isDarkMode,
                ),
                _buildWallpaperOption(
                  icon: Icons.lock,
                  label: 'Lock Screen',
                  onTap: () {
                    Navigator.pop(context);
                    _setWallpaper(imageUrl, 1);
                  },
                  isDarkMode: isDarkMode,
                ),
                _buildWallpaperOption(
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

  Widget _buildWallpaperOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = widget.photo['src']['original'];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black),
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
                _buildActionButton(
                  icon: Icons.download,
                  label: 'Download',
                  onTap: () => _saveImage(context, imageUrl),
                  isDarkMode: isDarkMode,
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () => _shareWallpaper(imageUrl),
                  isDarkMode: isDarkMode,
                ),
                _buildActionButton(
                  icon: Icons.wallpaper,
                  label: isSettingWallpaper ? 'Setting...' : 'Set as',
                  onTap: isSettingWallpaper
                      ? null
                      : () => _showSetWallpaperOptions(context, imageUrl),
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: isDarkMode ? Colors.white : Colors.black, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('favorites').listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No favorites yet',
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Tap the heart icon to add wallpapers',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final favorites = box.values.toList();

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final photo = favorites[index];
              final String imageUrl = photo['src']['medium'];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          DetailScreen(photo: photo),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        return SlideTransition(
                            position: animation.drive(tween), child: child);
                      },
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      child: const Icon(Icons.error, color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
