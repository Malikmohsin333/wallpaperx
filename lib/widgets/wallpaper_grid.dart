import 'package:flutter/material.dart';

import '../models/wallpaper.dart';
import '../screens/detail_screen.dart';
import 'shimmer_loading_grid.dart';
import 'wallpaper_card.dart';

class WallpaperGrid extends StatelessWidget {
  final List<Wallpaper> wallpapers;
  final bool isDarkMode;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final Future<void> Function(Wallpaper wallpaper) onWallpaperTap;

  const WallpaperGrid({
    super.key,
    required this.wallpapers,
    required this.isDarkMode,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onWallpaperTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && wallpapers.isEmpty) {
      return ShimmerLoadingGrid(
        isDarkMode: isDarkMode,
      );
    }

    if (errorMessage != null && wallpapers.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.error, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(errorMessage!),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (wallpapers.isEmpty) {
      return const Center(
        child: Text('No wallpapers found'),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: wallpapers.length,
      itemBuilder: (context, index) {
        final wallpaper = wallpapers[index];

        return WallpaperCard(
          wallpaper: wallpaper,
          isDarkMode: isDarkMode,
          onTap: () async {
            await onWallpaperTap(wallpaper);

            if (!context.mounted) return;

            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    DetailScreen(photo: wallpaper),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(
                    CurveTween(curve: curve),
                  );

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
