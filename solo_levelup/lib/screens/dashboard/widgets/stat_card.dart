import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/stat_types.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/player_provider.dart';
import '../../../widgets/common/stat_bar.dart';
import '../../../app/theme.dart';

/// Stat card widget for dashboard
class StatCard extends ConsumerWidget {
  final StatType statType;

  const StatCard({super.key, required this.statType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerProvider);
    final responsive = context.responsive;

    return playerAsync.when(
      data: (player) {
        final value = player.getStatValue(statType);

        return Container(
          padding: EdgeInsets.all(responsive.spacing),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(statType.colorValue).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: StatBar(statType: statType, value: value, showValue: true),
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
