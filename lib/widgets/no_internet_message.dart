import 'package:flutter/material.dart';

class NoInternetMessage extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onRetry;
  final VoidCallback onViewFavorites;

  const NoInternetMessage({
    super.key,
    required this.isDarkMode,
    required this.onRetry,
    required this.onViewFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.wifi_off,
            size: 80,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Internet Connection',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection\nand try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Retry'),
          ),
          const SizedBox(height: 40),
          Text(
            'Your favorites are still available!',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onViewFavorites,
            icon: const Icon(
              Icons.favorite_border,
              color: Color(0xFF6366F1),
            ),
            label: const Text(
              'View Favorites',
              style: TextStyle(color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }
}
