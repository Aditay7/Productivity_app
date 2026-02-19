import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/player_provider.dart';
import '../../../core/utils/xp_calculator.dart';
import '../../../core/utils/responsive.dart';
import '../../../app/theme.dart';

/// XP progress bar widget
class XPProgressBar extends ConsumerWidget {
  const XPProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerProvider);
    final responsive = context.responsive;

    return playerAsync.when(
      data: (player) {
        final progress = XPCalculator.progressToNextLevel(player.totalXP);
        final xpRemaining = XPCalculator.xpRemainingForNextLevel(
          player.totalXP,
        );
        final currentLevelXP = XPCalculator.xpForLevel(player.level);
        final nextLevelXP = XPCalculator.xpForLevel(player.level + 1);
        final xpInCurrentLevel = player.totalXP - currentLevelXP;
        final xpNeededForNextLevel = nextLevelXP - currentLevelXP;

        return Container(
          padding: EdgeInsets.all(responsive.spacing),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.gold.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total XP: ${player.totalXP}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: responsive.isSmall ? 14 : 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: responsive.spacing * 0.5),
                  Flexible(
                    child: Text(
                      '$xpRemaining to Lv${player.level + 1}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.gold,
                        fontSize: responsive.isSmall ? 12 : 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing * 0.75),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: responsive.isSmall ? 16 : 20,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.gold,
                  ),
                ),
              ),
              SizedBox(height: responsive.spacing * 0.5),
              Text(
                '$xpInCurrentLevel / $xpNeededForNextLevel XP',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                  fontSize: responsive.isSmall ? 10 : 12,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Icon(Icons.error)),
        ),
      ),
    );
  }
}
