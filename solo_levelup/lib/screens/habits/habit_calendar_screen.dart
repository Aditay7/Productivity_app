import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/quest_template_provider.dart';

class HabitCalendarScreen extends ConsumerStatefulWidget {
  const HabitCalendarScreen({super.key});

  @override
  ConsumerState<HabitCalendarScreen> createState() =>
      _HabitCalendarScreenState();
}

class _HabitCalendarScreenState extends ConsumerState<HabitCalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  String? _selectedHabitId;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(questTemplateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(questTemplateProvider);
            },
          ),
        ],
      ),
      body: templatesAsync.when(
        data: (templates) {
          final habits = templates.where((t) => t.isHabit == true).toList();

          if (habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No habit templates',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a template with habit tracking enabled',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Select first habit by default if none selected
          if (_selectedHabitId == null && habits.isNotEmpty) {
            _selectedHabitId = habits.first.id;
          }

          final selectedHabit = habits.firstWhere(
            (h) => h.id == _selectedHabitId,
            orElse: () => habits.first,
          );

          return Column(
            children: [
              // Habit selector
              _buildHabitSelector(habits),

              // Calendar
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildCalendar(selectedHabit),
                      const SizedBox(height: 24),
                      _buildHabitStats(selectedHabit),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitSelector(List<dynamic> habits) {
    return Container(
      height: 70,
      padding: EdgeInsets.zero,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: habits.length,
        itemBuilder: (context, index) {
          final habit = habits[index];
          final isSelected = habit.id == _selectedHabitId;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedHabitId = habit.id;
              });
            },
            child: Container(
              width: 130, // Slightly reduced width
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ), // Minimal vertical padding
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 18, // Smaller icon
                  ),
                  const SizedBox(height: 2),
                  Text(
                    habit.title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 11, // Smaller text
                    ),
                    maxLines: 1, // Force single line
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendar(dynamic habit) {
    final completionDates = (habit.habitCompletionHistory ?? [])
        .map((date) => DateTime.parse(date.toString()))
        .toSet();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final isCompleted = completionDates.any(
                (date) =>
                    date.year == day.year &&
                    date.month == day.month &&
                    date.day == day.day,
              );

              if (isCompleted) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
              return null;
            },
            todayBuilder: (context, day, focusedDay) {
              final isCompleted = completionDates.any(
                (date) =>
                    date.year == day.year &&
                    date.month == day.month &&
                    date.day == day.day,
              );

              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? Colors.green : Colors.blue,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
      ),
    );
  }

  Widget _buildHabitStats(dynamic habit) {
    final streak = habit.habitStreak ?? 0;
    final completionHistory = habit.habitCompletionHistory ?? [];
    final totalCompletions = completionHistory.length;
    final lastCompleted = habit.habitLastCompletedDate;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Habit Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Current Streak',
                    '$streak days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Total Completions',
                    '$totalCompletions',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lastCompleted != null
                          ? 'Last completed: ${_formatDate(DateTime.parse(lastCompleted.toString()))}'
                          : 'Not completed yet',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
