import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../providers/step_provider.dart';
import 'package:confetti/confetti.dart';
import 'workout_screen.dart';

class CardioScreen extends ConsumerStatefulWidget {
  const CardioScreen({super.key});

  @override
  ConsumerState<CardioScreen> createState() => _CardioScreenState();
}

class _CardioScreenState extends ConsumerState<CardioScreen> {
  late ConfettiController _confettiController;
  bool _hasCelebrated = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // Initialize step tracking when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stepProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepState = ref.watch(stepProvider);
    final double progress = stepState.steps / stepState.dailyGoal;
    final double calories = stepState.steps * 0.04; // Very rough estimate
    final double distanceKm = stepState.steps * 0.0008; // Average stride length

    // Trigger celebration only once per threshold crossing
    if (progress >= 1.0 && !_hasCelebrated) {
      _hasCelebrated = true;
      _confettiController.play();
    } else if (progress < 1.0) {
      _hasCelebrated = false;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF16152B),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WorkoutScreen()),
          );
        },
        backgroundColor: AppTheme.primaryPurple,
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
        label: const Text(
          'START WORKOUT',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),

                  if (stepState.error != null)
                    _buildErrorBanner(stepState.error!),

                  _buildMainProgress(
                    stepState.steps,
                    stepState.dailyGoal,
                    progress,
                  ),
                  const SizedBox(height: 32),
                  _buildStatsRow(
                    calories.toStringAsFixed(1),
                    distanceKm.toStringAsFixed(2),
                  ),
                  const SizedBox(height: 32),
                  _buildStatusIndicator(stepState.status),
                ],
              ),
            ),
            // Confetti Overlay
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                AppTheme.primaryPurple,
              ],
              createParticlePath: drawStar,
            ),
          ],
        ),
      ),
    );
  }

  /// A custom Path to paint stars.
  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (3.1415926535897932 / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * 1.05 * 0.9,
        halfWidth + externalRadius * 1.05 * 0.9,
      );
      path.lineTo(
        halfWidth + internalRadius * 1.05 * 0.9,
        halfWidth + internalRadius * 1.05 * 0.9,
      );
    }
    path.close();
    return path;
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cardio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_run_rounded,
                color: AppTheme.primaryPurple,
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Daily Step Tracking',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String errorMsg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMsg,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainProgress(int steps, int goal, double progress) {
    final clampedProgress = progress > 1 ? 1.0 : progress;
    final isDone = progress >= 1;

    // Shift from Purple -> Gold as they approach goal
    final activeColor = isDone
        ? Colors.greenAccent
        : Color.lerp(
                AppTheme.primaryPurple,
                Colors.orangeAccent,
                clampedProgress,
              ) ??
              AppTheme.primaryPurple;

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: clampedProgress),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, animValue, child) {
          final displaySteps = (animValue * goal).round().clamp(0, steps);

          return Stack(
            alignment: Alignment.center,
            children: [
              // Dynamic Glowing Aura
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: isDone ? 0.3 : 0.15),
                      blurRadius: isDone ? 60 : 40,
                      spreadRadius: isDone ? 15 : 10,
                    ),
                  ],
                ),
              ),

              // Animated Circular Ring
              SizedBox(
                width: 240,
                height: 240,
                child: CircularProgressIndicator(
                  value: animValue,
                  strokeWidth: 16,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation(activeColor),
                  strokeCap: StrokeCap.round,
                ),
              ),

              // Animated Text & Icon
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDone
                        ? Icons.military_tech_rounded
                        : Icons.local_fire_department_rounded,
                    color: isDone ? Colors.greenAccent : AppTheme.gold,
                    size: 38,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displaySteps.toString(),
                    style: TextStyle(
                      color: isDone ? Colors.greenAccent : Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                    ),
                  ),
                  Text(
                    ' / $goal steps',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(String calories, String km) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Calories',
            value: calories,
            unit: 'kcal',
            icon: Icons.fastfood_outlined,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Distance',
            value: km,
            unit: 'km',
            icon: Icons.map_outlined,
            color: Colors.greenAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'walking':
        statusColor = Colors.greenAccent;
        statusIcon = Icons.directions_walk;
        break;
      case 'stopped':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.accessibility_new;
        break;
      case 'unknown':
      default:
        statusColor = Colors.white54;
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Pedestrian Status: ${status.toUpperCase()}',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
