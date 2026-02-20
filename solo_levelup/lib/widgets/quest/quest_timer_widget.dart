import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/quest.dart';
import '../../providers/quest_timer_provider.dart';
import '../../app/theme.dart';

/// Compact timer widget for quest cards
class QuestTimerWidget extends ConsumerWidget {
  final Quest quest;
  final VoidCallback? onTap;

  const QuestTimerWidget({super.key, required this.quest, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsedSeconds = ref.watch(elapsedTimeProvider);
    final isRunning = ref.watch(isTimerRunningProvider);
    final activeQuest = ref.watch(activeTimerQuestProvider);

    final isThisQuestActive = activeQuest?.id == quest.id;

    // Show live time if active, saved actual time if completed, else 0
    final int displaySeconds;
    if (isThisQuestActive) {
      displaySeconds = elapsedSeconds;
    } else if (quest.timerState == TimerState.completed) {
      // Prefer precise seconds, fall back to minutes * 60
      final actualSecs =
          quest.timeActualSeconds ?? ((quest.timeActualMinutes ?? 0) * 60);
      displaySeconds = actualSecs > 0 ? actualSecs : 0;
    } else {
      displaySeconds = 0;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getTimerColor().withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getTimerColor().withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timer icon/indicator
            SizedBox(
              width: 20,
              height: 20,
              child: _buildTimerIndicator(isThisQuestActive, isRunning),
            ),
            const SizedBox(width: 8),

            // Time display
            Text(
              _formatTime(displaySeconds),
              style: TextStyle(
                color: _getTimerColor(),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            // Estimated time
            if (quest.timeEstimatedMinutes > 0) ...[
              const SizedBox(width: 4),
              Text(
                '/ ${quest.timeEstimatedMinutes}m',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimerIndicator(bool isActive, bool isRunning) {
    if (!isActive) {
      return Icon(_getTimerIcon(), size: 20, color: _getTimerColor());
    }

    if (isRunning) {
      return CustomPaint(
        painter: _PulsingCirclePainter(color: _getTimerColor()),
      );
    } else {
      return Icon(Icons.pause_circle, size: 20, color: _getTimerColor());
    }
  }

  IconData _getTimerIcon() {
    switch (quest.timerState) {
      case TimerState.notStarted:
        return Icons.play_circle_outline;
      case TimerState.running:
        return Icons.pause_circle_outline;
      case TimerState.paused:
        return Icons.play_circle_outline;
      case TimerState.completed:
        return Icons.check_circle;
    }
  }

  Color _getTimerColor() {
    switch (quest.timerState) {
      case TimerState.notStarted:
        return Colors.blue;
      case TimerState.running:
        return Colors.green;
      case TimerState.paused:
        return Colors.orange;
      case TimerState.completed:
        return AppTheme.gold;
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}

/// Pulsing circle painter for running timer
class _PulsingCirclePainter extends CustomPainter {
  final Color color;

  _PulsingCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius, paint);

    // Draw pulsing ring
    final ringPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius * 1.3, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
