import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quest_provider.dart';
import '../../app/theme.dart';
import 'package:intl/intl.dart';

class ActivityHeatmapSection extends ConsumerStatefulWidget {
  const ActivityHeatmapSection({super.key});

  @override
  ConsumerState<ActivityHeatmapSection> createState() =>
      _ActivityHeatmapSectionState();
}

class _ActivityHeatmapSectionState
    extends ConsumerState<ActivityHeatmapSection> {
  // Configuration for the heatmap
  static const int columnsToShow = 15; // Number of weeks to show
  static const int daysInWeek = 7;

  @override
  Widget build(BuildContext context) {
    // Watch completed quests from the quest provider
    final completedQuests = ref.watch(completedQuestsProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: AppTheme.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'ACTIVITY HEATMAP',
                style: TextStyle(
                  color: AppTheme.primaryPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1630), // _kCard from Dashboard
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: _buildHeatmap(completedQuests),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(List<dynamic> allCompletedQuests) {
    // Group completed quests by date (yyyy-MM-dd) to get daily counts
    final Map<String, int> dailyCounts = {};

    for (var quest in allCompletedQuests) {
      if (quest.completedAt != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(quest.completedAt!);
        dailyCounts[dateStr] = (dailyCounts[dateStr] ?? 0) + 1;
      }
    }

    // Calculate grid data starting from today going backwards
    final today = DateTime.now();

    // Find the Sunday of the current week to align grid nicely
    // In Dart, weekday 1 = Monday, 7 = Sunday
    int daysSinceSunday = today.weekday % 7;

    // Total cells = (columnsToShow - 1) full weeks + the current week's days so far + future days in current week
    final int totalCells = columnsToShow * daysInWeek;

    final startDate = today.subtract(
      Duration(days: totalCells - 1 - (6 - daysSinceSunday)),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      reverse: true, // Scroll to the right (most recent) by default
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Labels (Mon, Wed, Fri)
          Padding(
            padding: const EdgeInsets.only(top: 14, right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 12), // Sun (hidden)
                _dayLabel('Mon'), // Mon
                const SizedBox(height: 12), // Tue
                _dayLabel('Wed'), // Wed
                const SizedBox(height: 12), // Thu
                _dayLabel('Fri'), // Fri
                const SizedBox(height: 12), // Sat (hidden)
              ],
            ),
          ),

          // Heatmap Grid
          Row(
            children: List.generate(columnsToShow, (colIndex) {
              return Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Column(
                  children: List.generate(daysInWeek, (rowIndex) {
                    final cellIndex = (colIndex * daysInWeek) + rowIndex;
                    final cellDate = startDate.add(Duration(days: cellIndex));
                    final isFuture = cellDate.isAfter(today);

                    final dateStr = DateFormat('yyyy-MM-dd').format(cellDate);
                    final count = dailyCounts[dateStr] ?? 0;

                    // Determine color based on completion count (GitHub style)
                    Color cellColor;
                    if (isFuture) {
                      cellColor = Colors.transparent;
                    } else if (count == 0) {
                      cellColor = Colors.white.withOpacity(0.04);
                    } else if (count <= 2) {
                      cellColor = AppTheme.primaryPurple.withOpacity(0.3);
                    } else if (count <= 4) {
                      cellColor = AppTheme.primaryPurple.withOpacity(0.6);
                    } else {
                      cellColor = AppTheme.primaryPurple;
                    }

                    return Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(bottom: 4.0),
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(3),
                        border: isFuture
                            ? Border.all(color: Colors.transparent)
                            : Border.all(
                                color: count > 0
                                    ? AppTheme.primaryPurple.withOpacity(0.5)
                                    : Colors.white.withOpacity(0.02),
                                width: 0.5,
                              ),
                        boxShadow:
                            count >
                                0 // Add a subtle glow for active days
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryPurple.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 4,
                                  spreadRadius: 0.5,
                                ),
                              ]
                            : [],
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _dayLabel(String text) {
    return SizedBox(
      height: 12,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
