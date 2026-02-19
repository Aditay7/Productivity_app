import 'package:flutter/material.dart';
import '../../app/theme.dart';

class FocusRatingDialog extends StatefulWidget {
  const FocusRatingDialog({super.key});

  @override
  State<FocusRatingDialog> createState() => _FocusRatingDialogState();
}

class _FocusRatingDialogState extends State<FocusRatingDialog> {
  int? _selectedRating;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      title: const Text(
        'Complete Quest',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How focused were you?',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final rating = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = rating;
                  });
                },
                child: Icon(
                  _selectedRating != null && rating <= _selectedRating!
                      ? Icons.star
                      : Icons.star_border,
                  size: 40,
                  color: AppTheme.gold,
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedRating ?? -1),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.gold,
            foregroundColor: Colors.black,
            disabledBackgroundColor: AppTheme.gold.withOpacity(0.3),
          ),
          child: const Text('Complete'),
        ),
      ],
    );
  }
}
