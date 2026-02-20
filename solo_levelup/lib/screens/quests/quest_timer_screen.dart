import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../data/models/quest.dart';
import '../../providers/quest_timer_provider.dart';
import '../../providers/quest_provider.dart';
import '../../app/theme.dart';
import '../../widgets/quest/focus_rating_dialog.dart';

/// Full-screen timer view for active quest
class QuestTimerScreen extends ConsumerStatefulWidget {
  final Quest quest;

  const QuestTimerScreen({super.key, required this.quest});

  @override
  ConsumerState<QuestTimerScreen> createState() => _QuestTimerScreenState();
}

class _QuestTimerScreenState extends ConsumerState<QuestTimerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Initialize timer state if quest timer is already running/paused
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeQuest = ref.read(activeTimerQuestProvider);
      
      // If this quest is not already set as active, initialize it
      if (activeQuest?.id != widget.quest.id && 
          widget.quest.timerState != TimerState.notStarted &&
          widget.quest.timerState != TimerState.completed) {
        
        ref.read(activeTimerQuestProvider.notifier).state = widget.quest;
        
        if (widget.quest.timerState == TimerState.running) {
          ref.read(isTimerRunningProvider.notifier).state = true;
          // Start the periodic timer
          ref.read(questTimerProvider.notifier).startElapsedTimeCounter(widget.quest);
        } else if (widget.quest.timerState == TimerState.paused) {
          ref.read(isTimerRunningProvider.notifier).state = false;
          // Calculate and set elapsed time for paused state
          if (widget.quest.timeStarted != null) {
            final now = DateTime.now();
            final elapsed = now.difference(widget.quest.timeStarted!);
            final pausedSeconds = (widget.quest.pausedDuration ?? 0) ~/ 1000;
            
            int elapsedSeconds = elapsed.inSeconds - pausedSeconds;
            
            // If currently paused, also subtract current pause duration
            if (widget.quest.timePaused != null) {
              final currentPauseSeconds = now.difference(widget.quest.timePaused!).inSeconds;
              elapsedSeconds -= currentPauseSeconds;
            }
            
            ref.read(elapsedTimeProvider.notifier).state = elapsedSeconds.clamp(0, 999999);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsedSeconds = ref.watch(elapsedTimeProvider);
    final isRunning = ref.watch(isTimerRunningProvider);
    final activeQuest = ref.watch(activeTimerQuestProvider);

    // Use active quest if this is the active quest, otherwise use widget quest
    final currentQuest = (activeQuest?.id == widget.quest.id) 
        ? activeQuest! 
        : widget.quest;

    final isThisQuestActive = activeQuest?.id == widget.quest.id;
    final displaySeconds = isThisQuestActive ? elapsedSeconds : 0;

    final estimatedSeconds = currentQuest.timeEstimatedMinutes * 60;
    final progress = estimatedSeconds > 0
        ? (displaySeconds / estimatedSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(widget.quest.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),

              // Circular timer display
              Stack(
                alignment: Alignment.center,
                children: [
                  // Progress ring
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _TimerRingPainter(
                            progress: progress,
                            isRunning: isRunning,
                            pulseValue: _pulseController.value,
                          ),
                        );
                      },
                    ),
                  ),

                  // Time display
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(displaySeconds),
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'of ${currentQuest.timeEstimatedMinutes}m',
                        style: TextStyle(fontSize: 18, color: Colors.white54),
                      ),
                      if (progress > 1.0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: const Text(
                            'Over estimated time',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // Timer controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (currentQuest.timerState == TimerState.notStarted)
                    _buildControlButton(
                      icon: Icons.play_arrow,
                      label: 'Start',
                      color: Colors.green,
                      onPressed: () => _startTimer(),
                    ),

                  if (currentQuest.timerState == TimerState.running) ...[
                    _buildControlButton(
                      icon: Icons.pause,
                      label: 'Pause',
                      color: Colors.orange,
                      onPressed: () => _pauseTimer(),
                    ),
                    const SizedBox(width: 16),
                    _buildControlButton(
                      icon: Icons.stop,
                      label: 'Stop',
                      color: Colors.red,
                      onPressed: () => _showStopDialog(),
                    ),
                  ],

                  if (currentQuest.timerState == TimerState.paused) ...[
                    _buildControlButton(
                      icon: Icons.play_arrow,
                      label: 'Resume',
                      color: Colors.green,
                      onPressed: () => _resumeTimer(),
                    ),
                    const SizedBox(width: 16),
                    _buildControlButton(
                      icon: Icons.stop,
                      label: 'Stop',
                      color: Colors.red,
                      onPressed: () => _showStopDialog(),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Complete button
              if (currentQuest.timerState != TimerState.notStarted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCompleteDialog(),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete Quest'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _startTimer() async {
    await ref.read(questTimerProvider.notifier).startTimer(widget.quest);
  }

  Future<void> _pauseTimer() async {
    await ref.read(questTimerProvider.notifier).pauseTimer(widget.quest.id!);
  }

  Future<void> _resumeTimer() async {
    await ref.read(questTimerProvider.notifier).resumeTimer(widget.quest.id!);
  }

  Future<void> _showStopDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Timer'),
        content: const Text(
          'Are you sure you want to stop the timer without completing the quest?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await ref.read(questTimerProvider.notifier).stopTimer(widget.quest.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _showCompleteDialog() async {
    final result = await showDialog<int?>(
      context: context,
      builder: (context) => const FocusRatingDialog(),
    );

    // If result is null, dialog was cancelled
    if (result == null) return;

    // If result is -1, it means "Complete without rating"
    // If result is > 0, it's the rating
    final rating = result == -1 ? null : result;

    if (mounted) {
      await _completeQuest(rating);
    }
  }

  Future<void> _completeQuest(int? rating) async {
    final result = await ref
        .read(questTimerProvider.notifier)
        .completeQuestWithTimer(widget.quest.id!, focusRating: rating);

    if (result != null && mounted) {
      // Refresh quest list
      ref.invalidate(questProvider);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quest completed! +${widget.quest.xpReward} XP'),
          backgroundColor: AppTheme.primaryPurple,
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}

/// Custom painter for timer ring
class _TimerRingPainter extends CustomPainter {
  final double progress;
  final bool isRunning;
  final double pulseValue;

  _TimerRingPainter({
    required this.progress,
    required this.isRunning,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppTheme.primaryPurple, AppTheme.gold],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Pulsing glow when running
    if (isRunning) {
      final glowPaint = Paint()
        ..color = AppTheme.primaryPurple.withOpacity(0.3 * pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(center, radius, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.pulseValue != pulseValue;
  }
}
