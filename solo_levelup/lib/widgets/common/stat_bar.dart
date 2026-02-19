import 'package:flutter/material.dart';
import '../../core/constants/stat_types.dart';
import '../../core/utils/responsive.dart';

/// Reusable stat bar widget
class StatBar extends StatelessWidget {
  final StatType statType;
  final int value;
  final int? maxValue;
  final bool showValue;

  const StatBar({
    super.key,
    required this.statType,
    required this.value,
    this.maxValue,
    this.showValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final max = maxValue ?? 100;
    final progress = (value / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stat name and value
        Row(
          children: [
            // Emoji
            Text(
              statType.emoji,
              style: TextStyle(fontSize: responsive.isSmall ? 18 : 20),
            ),
            SizedBox(width: responsive.spacing * 0.5),
            // Stat name
            Expanded(
              child: Text(
                statType.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: responsive.isSmall ? 14 : 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Value
            if (showValue)
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Color(statType.colorValue),
                  fontWeight: FontWeight.bold,
                  fontSize: responsive.isSmall ? 14 : 16,
                ),
              ),
          ],
        ),
        SizedBox(height: responsive.spacing * 0.5),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: responsive.isSmall ? 6 : 8,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(statType.colorValue),
            ),
          ),
        ),
      ],
    );
  }
}
