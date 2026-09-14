import 'package:flutter/material.dart';

class SettingsBottomSheet extends StatelessWidget {
  final VoidCallback onClearCache;
  final VoidCallback onShareApp;
  final VoidCallback onRateUs;

  const SettingsBottomSheet({
    super.key,
    required this.onClearCache,
    required this.onShareApp,
    required this.onRateUs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(
              Icons.clear_all,
              color: Color(0xFF6366F1),
            ),
            title: const Text('Clear Cache'),
            onTap: () {
              Navigator.pop(context);
              onClearCache();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.share,
              color: Color(0xFF6366F1),
            ),
            title: const Text('Share App'),
            onTap: () {
              Navigator.pop(context);
              onShareApp();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.star,
              color: Color(0xFF6366F1),
            ),
            title: const Text('Rate Us'),
            onTap: () {
              Navigator.pop(context);
              onRateUs();
            },
          ),
        ],
      ),
    );
  }
}
