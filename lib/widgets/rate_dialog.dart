import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class RateDialog extends StatelessWidget {
  const RateDialog({super.key});

  Future<void> _markAsRated(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_rated', true);

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _rateNow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_rated', true);

    const url =
        'https://play.google.com/store/apps/details?id=com.example.wallpaperx';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enjoying WallpaperX?'),
      content: const Text(
        'Please rate us on the Play Store and help us improve!',
      ),
      actions: [
        TextButton(
          onPressed: () => _markAsRated(context),
          child: const Text('No, Thanks'),
        ),
        TextButton(
          onPressed: () => _rateNow(context),
          child: const Text(
            'Rate Now',
            style: TextStyle(color: Color(0xFF6366F1)),
          ),
        ),
      ],
    );
  }
}
