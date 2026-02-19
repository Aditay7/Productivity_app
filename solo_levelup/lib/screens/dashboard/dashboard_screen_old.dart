import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_provider.dart';
import '../../core/constants/stat_types.dart';
import '../../core/utils/responsive.dart';
import '../../app/theme.dart';
import 'widgets/stat_card.dart';
import 'widgets/xp_progress_bar.dart';
import 'widgets/today_quests_list.dart';
import '../quests/add_quest_screen.dart';
import '../templates/manage_templates_screen.dart';
import '../analytics/productivity_dashboard_screen.dart';
import '../goals/goals_screen.dart';

/// Dashboard screen - main command center
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerAsync = ref.watch(playerProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: playerAsync.when(
            data: (player) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with level and streak
                  _buildHeader(context, player),
                  const SizedBox(height: 24),

                  // XP Progress Bar
                  const XPProgressBar(),
                  const SizedBox(height: 24),

                  // Stats Section
                  Text(
                    'Your Stats',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...StatType.values.map((statType) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StatCard(statType: statType),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Today's Quests
                  const TodayQuestsList(),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductivityDashboardScreen(),
                ),
              );
            },
            backgroundColor: Colors.blue.shade700,
            child: const Icon(Icons.analytics, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'goals',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GoalsScreen(),
                ),
              );
            },
            backgroundColor: Colors.green.shade700,
            child: const Icon(Icons.flag, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'templates',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageTemplatesScreen(),
                ),
              );
            },
            backgroundColor: AppTheme.primaryPurple.withOpacity(0.8),
            child: const Icon(Icons.event_repeat),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'new_quest',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddQuestScreen()),
              );
            },
            backgroundColor: AppTheme.primaryPurple,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  /// Show Shadow Monarch Mode confirmation dialog
  void _showShadowModeDialog(BuildContext context, bool enable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Row(
          children: [
            const Text('⚔️'),
            const SizedBox(width: 8),
            Text(enable ? 'Enter Shadow Realm?' : 'Exit Shadow Mode?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (enable) ...[
              const Text(
                'WARNING: Shadow Monarch Mode is for absolute madmen!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text('• All quests become HARD difficulty'),
              const Text('• XP requirements DOUBLED (2x harder to level)'),
              const Text('• Breaking streaks costs 10% of your XP'),
              const Text('• BUT: XP rewards are TRIPLED (3x)'),
              const SizedBox(height: 12),
              const Text(
                'Are you ready to become the Shadow Monarch?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ] else ...[
              const Text('Exiting Shadow Mode will:'),
              const SizedBox(height: 8),
              const Text('• Keep your current progress'),
              const Text('• Disable 3x XP bonus'),
              const Text('• Remove streak penalties'),
              const Text('• Allow Easy/Medium quests'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer(
            builder: (context, ref, child) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: enable ? Colors.purple : AppTheme.primaryPurple,
                ),
                onPressed: () {
                  ref.read(playerProvider.notifier).toggleShadowMode(enable);
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        enable 
                            ? '⚔️ Shadow Monarch Mode ACTIVATED! ARISE!' 
                            : 'Shadow Mode deactivated',
                      ),
                      backgroundColor: enable ? Colors.purple : AppTheme.primaryPurple,
                    ),
                  );
                },
                child: Text(enable ? 'ARISE!' : 'Exit'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic player) {
    final responsive = context.responsive;
    
    return Container(
      padding: EdgeInsets.all(responsive.spacing),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // App Logo
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Image.asset(
                  'lib/assets/app_logo.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              // Level display
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${player.level}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: responsive.isSmall
                                ? 36
                                : responsive.isMedium
                                    ? 42
                                    : 48,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: responsive.spacing),
              // Streak display
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(responsive.spacing * 0.75),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: AppTheme.gold),
                      SizedBox(height: responsive.spacing * 0.25),
                      Text(
                        '${player.currentStreak}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Shadow Monarch Mode Toggle
          SizedBox(height: responsive.spacing),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacing,
              vertical: responsive.spacing * 0.5,
            ),
            decoration: BoxDecoration(
              gradient: player.isShadowMode
                  ? LinearGradient(
                      colors: [Colors.purple.shade900, Colors.black],
                    )
                  : null,
              color: player.isShadowMode ? null : Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: player.isShadowMode ? Colors.purple : Colors.white24,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '⚔️ Shadow Monarch Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (player.isShadowMode) ...[
                            SizedBox(width: responsive.spacing * 0.5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '3X XP',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        player.isShadowMode
                            ? 'Hard quests only • 2x requirements • Streak penalties'
                            : '3x XP • 2x requirements • Hard only',
                        style: TextStyle(
                          fontSize: responsive.isSmall ? 11 : 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: player.isShadowMode,
                  onChanged: (value) => _showShadowModeDialog(context, value),
                  activeColor: Colors.purple.shade300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
