import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Level up dialog shown when player levels up
class LevelUpDialog extends StatelessWidget {
  final int newLevel;
  final int xpGained;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    required this.xpGained,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.gold.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Level up icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.gold.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                size: 48,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(height: 16),

            // Level up text
            Text(
              'LEVEL UP!',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // New level
            Text(
              'Level $newLevel',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // XP gained
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+$xpGained XP',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppTheme.gold),
              ),
            ),
            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the level up dialog
  static Future<void> show(BuildContext context, int newLevel, int xpGained) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          LevelUpDialog(newLevel: newLevel, xpGained: xpGained),
    );
  }
}
