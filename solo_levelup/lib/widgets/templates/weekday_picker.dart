import 'package:flutter/material.dart';

/// Widget for selecting weekdays
class WeekdayPicker extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  const WeekdayPicker({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  static const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Days',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final day = index + 1; // 1=Mon, 7=Sun
            final isSelected = selectedDays.contains(day);
            return FilterChip(
              label: Text(_weekdayNames[index]),
              selected: isSelected,
              onSelected: (selected) {
                final newDays = List<int>.from(selectedDays);
                if (selected) {
                  newDays.add(day);
                } else {
                  newDays.remove(day);
                }
                newDays.sort();
                onChanged(newDays);
              },
            );
          }),
        ),
      ],
    );
  }
}
