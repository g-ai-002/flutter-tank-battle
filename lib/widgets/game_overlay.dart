import 'package:flutter/material.dart';

class GameOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const GameOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onTap,
                  child: const Text('继续'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
