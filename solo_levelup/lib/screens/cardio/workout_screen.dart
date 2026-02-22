import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../services/cardio_sync_service.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  DateTime? _startTime;

  // Simulated metrics
  double _distanceKm = 0.0;
  int _steps = 0;
  double _caloriesBurned = 0.0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startWorkout() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _startTime = DateTime.now();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _secondsElapsed++;

          // Simulation heuristics (Walking ~ 5km/h, MET ~ 3.5, ~100 steps/min)
          _steps = (_secondsElapsed * (100 / 60)).round();
          _distanceKm = _secondsElapsed * (5.0 / 3600);
          _caloriesBurned = 3.5 * 70 * (_secondsElapsed / 3600); // Assume 70kg
        });
      }
    });
  }

  void _pauseWorkout() {
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeWorkout() {
    setState(() {
      _isPaused = false;
    });
  }

  Future<void> _stopWorkout() async {
    _timer?.cancel();
    final endTime = DateTime.now();

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryPurple),
      ),
    );

    // Sync to backend
    final success = await cardioSyncService.saveWorkoutSession(
      type: 'walk', // Future: allow user selection
      startTime:
          _startTime ?? endTime.subtract(Duration(seconds: _secondsElapsed)),
      endTime: endTime,
      durationSeconds: _secondsElapsed,
      steps: _steps,
      distanceKm: _distanceKm,
      caloriesBurned: _caloriesBurned,
      averagePaceKmH: 5.0, // Fixed simulation
    );

    if (mounted) {
      Navigator.of(context).pop(); // Dismiss loader

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout synced successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Will sync later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      Navigator.of(context).pop(); // Return home
    }
  }

  String _formatTime() {
    final hours = _secondsElapsed ~/ 3600;
    final minutes = (_secondsElapsed % 3600) ~/ 60;
    final seconds = _secondsElapsed % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        title: const Text(
          'Active Workout',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Map Simulation Gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryPurple.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                radius: 1.5,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Timer Text
                Text(
                  _formatTime(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),

                // Metrics Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMetricCard(
                      Icons.directions_walk_rounded,
                      'Steps',
                      '$_steps',
                      Colors.blueAccent,
                    ),
                    _buildMetricCard(
                      Icons.map_rounded,
                      'Distance',
                      '${_distanceKm.toStringAsFixed(2)} km',
                      Colors.greenAccent,
                    ),
                    _buildMetricCard(
                      Icons.local_fire_department_rounded,
                      'Calories',
                      '${_caloriesBurned.toStringAsFixed(1)} kcal',
                      Colors.orangeAccent,
                    ),
                  ],
                ),

                // Controls
                if (!_isRunning)
                  _buildLargeButton(
                    'START',
                    Icons.play_arrow_rounded,
                    AppTheme.primaryPurple,
                    _startWorkout,
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isPaused)
                        _buildLargeButton(
                          'PAUSE',
                          Icons.pause_rounded,
                          Colors.orangeAccent,
                          _pauseWorkout,
                        )
                      else ...[
                        _buildLargeButton(
                          'RESUME',
                          Icons.play_arrow_rounded,
                          Colors.greenAccent,
                          _resumeWorkout,
                        ),
                        const SizedBox(width: 16),
                        _buildLargeButton(
                          'STOP',
                          Icons.stop_rounded,
                          Colors.redAccent,
                          _stopWorkout,
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    IconData icon,
    String title,
    String value,
    Color iconColor,
  ) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLargeButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
