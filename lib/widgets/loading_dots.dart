import 'package:flutter/material.dart';

class LoadingDots extends StatelessWidget {
  const LoadingDots({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.3, end: 1.0),
              duration: Duration(milliseconds: 500 + (index * 150)),
              builder: (context, double value, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 12 * value,
                  height: 12 * value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6366F1).withValues(alpha: value),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
