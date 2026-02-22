import 'package:flutter/material.dart';
import '../../app/theme.dart';

class NoInternetWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Warning Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),

            // Main Title
            const Text(
              'LINK SEVERED',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: [Shadow(color: Colors.redAccent, blurRadius: 10)],
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'The connection to the System has been lost. Please establish a network link to continue your journey.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Retry Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                label: const Text(
                  'REESTABLISH LINK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: AppTheme.primaryPurple.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
