import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/quest_provider.dart';
import '../../providers/player_provider.dart';
import '../../app/theme.dart';
import '../../core/constants/stat_types.dart';
import '../../data/models/quest.dart';

class ActivityHeatmapSection extends ConsumerStatefulWidget {
  const ActivityHeatmapSection({super.key});

  @override
  ConsumerState<ActivityHeatmapSection> createState() =>
      _ActivityHeatmapSectionState();
}

class _ActivityHeatmapSectionState
    extends ConsumerState<ActivityHeatmapSection> {
  // Configuration for the heatmap
  static const int columnsToShow = 52; // Full year
  static const int daysInWeek = 7;

  StatType? _selectedFilter; // null means 'All'
  int _todayCount = 0; // Used for the micro insight

  @override
  Widget build(BuildContext context) {
    final completedQuests = ref.watch(completedQuestsProvider);
    final playerAsync = ref.watch(playerProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1630), // _kCard from Dashboard
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(completedQuests, playerAsync),
                const SizedBox(height: 20),
                _buildFilterTabs(),
                const SizedBox(height: 24),
                _buildHeatmap(completedQuests),
                const SizedBox(height: 16),
                _buildMicroInsight(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.auto_graph, color: AppTheme.primaryPurple, size: 18),
        const SizedBox(width: 8),
        const Text(
          'ACTIVITY HEATMAP',
          style: TextStyle(
            color: AppTheme.primaryPurple,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(
    List<Quest> allCompletedQuests,
    AsyncValue<dynamic> playerAsync,
  ) {
    // 1. Calculate quests in last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    int last30DaysCount = 0;

    // 2. Calculate best streak from all quests
    int bestStreak = 0;
    int currentRun = 0;
    DateTime? previousDate;

    // We need unique sorted dates
    final Set<String> uniqueDates = {};
    for (var quest in allCompletedQuests) {
      if (quest.completedAt != null &&
          (_selectedFilter == null || quest.statType == _selectedFilter)) {
        if (quest.completedAt!.isAfter(thirtyDaysAgo)) {
          last30DaysCount++;
        }
        uniqueDates.add(DateFormat('yyyy-MM-dd').format(quest.completedAt!));
      }
    }

    final sortedDates = uniqueDates.map((d) => DateTime.parse(d)).toList()
      ..sort((a, b) => a.compareTo(b));

    for (var date in sortedDates) {
      if (previousDate == null) {
        currentRun = 1;
      } else {
        final diff = date.difference(previousDate).inDays;
        if (diff == 1) {
          currentRun++;
        } else if (diff > 1) {
          currentRun = 1; // broken streak
        }
      }
      if (currentRun > bestStreak) {
        bestStreak = currentRun;
      }
      previousDate = date;
    }

    // 3. Current streak from player
    final currentStreak = playerAsync.when(
      data: (p) => p.currentStreak,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: '30 Days',
              value: '$last30DaysCount',
              icon: Icons.calendar_today,
              color: AppTheme.accentBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: 'Current',
              value: currentStreak > 0 ? '${currentStreak}d' : '-',
              icon: Icons.local_fire_department,
              color: AppTheme.gold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              title: 'Best',
              value: bestStreak > 0 ? '${bestStreak}d' : '-',
              icon: Icons.emoji_events,
              color: AppTheme.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [null, ...StatType.values];

    return SizedBox(
      height: 32,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          final color = filter?.color ?? AppTheme.primaryPurple;
          final title = filter?.name.toUpperCase() ?? 'ALL';
          final icon = filter?.emoji;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? color.withOpacity(0.8)
                      : Colors.transparent,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Row(
                  children: [
                    if (icon != null) Text(icon),
                    if (icon != null) const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeatmap(List<Quest> allCompletedQuests) {
    // Map dates to daily data records
    final Map<String, _DailyData> dailyData = {};

    for (var quest in allCompletedQuests) {
      if (quest.completedAt != null &&
          (_selectedFilter == null || quest.statType == _selectedFilter)) {
        final dateStr = DateFormat('yyyy-MM-dd').format(quest.completedAt!);

        if (!dailyData.containsKey(dateStr)) {
          dailyData[dateStr] = _DailyData();
        }

        dailyData[dateStr]!.count++;
        dailyData[dateStr]!.xp += quest.xpReward;
        dailyData[dateStr]!.categories.add(quest.statType);
      }
    }

    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    // Update local state for the insight widget (schedule state update after build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newTodayCount = dailyData[todayStr]?.count ?? 0;
      if (mounted && _todayCount != newTodayCount) {
        setState(() {
          _todayCount = newTodayCount;
        });
      }
    });

    int daysSinceSunday = today.weekday % 7;
    final int totalCells = columnsToShow * daysInWeek;
    final startDate = today.subtract(
      Duration(days: totalCells - 1 - (6 - daysSinceSunday)),
    );

    // Removed old sizing code

    // 1. Group columns by month
    final List<_MonthSpan> monthSpans = [];
    int currentMonth = -1;
    int currentMonthStartCol = 0;

    for (int colIndex = 0; colIndex < columnsToShow; colIndex++) {
      // Use Wednesday to determine the column's month
      final cellDate = startDate.add(
        Duration(days: (colIndex * daysInWeek) + 3),
      );
      final month = cellDate.month;

      if (currentMonth == -1) {
        currentMonth = month;
        currentMonthStartCol = colIndex;
      } else if (month != currentMonth) {
        monthSpans.add(
          _MonthSpan(
            monthName: DateFormat('MMM').format(
              startDate.add(
                Duration(days: (currentMonthStartCol * daysInWeek) + 3),
              ),
            ),
            colCount: colIndex - currentMonthStartCol,
          ),
        );
        currentMonth = month;
        currentMonthStartCol = colIndex;
      }
    }
    // Add the final month span
    if (currentMonth != -1) {
      monthSpans.add(
        _MonthSpan(
          monthName: DateFormat('MMM').format(
            startDate.add(
              Duration(days: (currentMonthStartCol * daysInWeek) + 3),
            ),
          ),
          colCount: columnsToShow - currentMonthStartCol,
        ),
      );
    }

    // Build the month labels row
    List<Widget> builtMonthLabels = [];
    for (var span in monthSpans) {
      // Cell width is 12 + margin right 4 = 16 pixels per column
      builtMonthLabels.add(
        SizedBox(
          width: span.colCount * 16.0,
          child: Text(
            span.colCount >= 2 ? span.monthName : '', // Hide if too squeezed
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      reverse: true, // Auto-scroll to current week
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Labels Row
          Padding(
            padding: const EdgeInsets.only(
              left: 30,
              bottom: 8,
            ), // Account for Y-axis Width
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: builtMonthLabels,
            ),
          ),
          // Heatmap Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Y-Axis Labels
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 12),
                    _dayLabel('Mon'),
                    const SizedBox(height: 12),
                    _dayLabel('Wed'),
                    const SizedBox(height: 12),
                    _dayLabel('Fri'),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // Grid columns
              Row(
                children: List.generate(columnsToShow, (colIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Column(
                      children: List.generate(daysInWeek, (rowIndex) {
                        final cellIndex = (colIndex * daysInWeek) + rowIndex;
                        final cellDate = startDate.add(
                          Duration(days: cellIndex),
                        );
                        final isFuture = cellDate.isAfter(today);

                        final dateStr = DateFormat(
                          'yyyy-MM-dd',
                        ).format(cellDate);
                        final data = dailyData[dateStr] ?? _DailyData();

                        final baseColor =
                            _selectedFilter?.color ?? AppTheme.primaryPurple;

                        Color cellColor;
                        if (isFuture) {
                          cellColor = Colors.transparent;
                        } else if (data.count == 0) {
                          cellColor = Colors.white.withOpacity(
                            0.03,
                          ); // Minimal intensity
                        } else if (data.count <= 2) {
                          cellColor = baseColor.withOpacity(0.3); // Level 1
                        } else if (data.count <= 4) {
                          cellColor = baseColor.withOpacity(0.6); // Level 2
                        } else {
                          cellColor = baseColor.withOpacity(
                            0.9,
                          ); // Level 3 (high activity)
                        }

                        // Determine if it's "Today"
                        final isToday = dateStr == todayStr;

                        return _HeatmapCell(
                          date: cellDate,
                          data: data,
                          color: cellColor,
                          isFuture: isFuture,
                          baseColor: baseColor,
                          isToday: isToday,
                        );
                      }),
                    ),
                  );
                }),
              ),
            ],
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
          color: Colors.white.withOpacity(0.4),
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMicroInsight() {
    String text;
    IconData icon;
    Color color;

    if (_todayCount == 0) {
      text = "The day is young. Start your first quest!";
      icon = Icons.bedtime_outlined;
      color = Colors.white.withOpacity(0.5);
    } else if (_todayCount <= 2) {
      text = "$_todayCount quests completed today! Looking good.";
      icon = Icons.local_fire_department_outlined;
      color = AppTheme.gold.withOpacity(0.8);
    } else {
      text = "$_todayCount quests completed today. Incredible work! 👑";
      icon = Icons.local_fire_department_rounded;
      color = AppTheme.primaryPurple;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyData {
  int count = 0;
  int xp = 0;
  Set<StatType> categories = {};
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Heatmap Cell with Tooltip
// ─────────────────────────────────────────────────────────────────────────────
class _HeatmapCell extends StatefulWidget {
  final DateTime date;
  final _DailyData data;
  final Color color;
  final bool isFuture;
  final Color baseColor;
  final bool isToday;

  const _HeatmapCell({
    required this.date,
    required this.data,
    required this.color,
    required this.isFuture,
    required this.baseColor,
    this.isToday = false,
  });

  @override
  State<_HeatmapCell> createState() => _HeatmapCellState();
}

class _HeatmapCellState extends State<_HeatmapCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isFuture) {
      return Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.only(bottom: 4.0),
        color: Colors.transparent,
      );
    }

    final dateLabel = DateFormat('MMM d, yyyy').format(widget.date);
    final tooltipMessage = widget.data.count > 0
        ? '$dateLabel\n${widget.data.count} quests • ${widget.data.xp} XP\n${widget.data.categories.map((c) => c.emoji).join(" ")}'
        : '$dateLabel\nNo quests completed';

    final bool isHighActivity = widget.data.count >= 5;

    return Tooltip(
      message: tooltipMessage,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1630).withOpacity(0.98), // Solid premium dark
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.baseColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.baseColor.withOpacity(0.25),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(bottom: 4.0),
          transform: Matrix4.identity()..scale(_isHovered ? 1.4 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isHovered && widget.data.count == 0
                ? Colors.white.withOpacity(0.15)
                : widget.color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: widget.isToday
                  ? AppTheme.gold
                  : widget.data.count > 0 || _isHovered
                  ? widget.baseColor.withOpacity(0.8)
                  : Colors.white.withOpacity(0.04),
              width: widget.isToday ? 1.5 : 0.5,
            ),
            boxShadow: isHighActivity || _isHovered
                ? [
                    BoxShadow(
                      color: widget.isToday && _isHovered
                          ? AppTheme.gold.withOpacity(0.6)
                          : widget.baseColor.withOpacity(
                              _isHovered ? 0.8 : 0.4,
                            ),
                      blurRadius: _isHovered ? 8 : (isHighActivity ? 6 : 4),
                      spreadRadius: _isHovered ? 1.5 : (isHighActivity ? 1 : 0),
                    ),
                  ]
                : [],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini Stat Card
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSpan {
  final String monthName;
  final int colCount;

  _MonthSpan({required this.monthName, required this.colCount});
}
