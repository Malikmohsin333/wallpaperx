import 'package:flutter/material.dart';

class AnimatedMessage extends StatelessWidget {
  final String message;
  final bool isSuccess;

  const AnimatedMessage({
    super.key,
    required this.message,
    this.isSuccess = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 20,
      right: 20,
      child: TweenAnimationBuilder<double>(
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
    );
  }
}
