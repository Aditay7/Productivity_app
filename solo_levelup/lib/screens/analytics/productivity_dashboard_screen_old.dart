import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/analytics_provider.dart';
import '../../app/theme.dart';

/// Productivity Dashboard Screen with analytics and insights
class ProductivityDashboardScreen extends ConsumerWidget {
  const ProductivityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(productivityDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Insights'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: dashboardAsync.when(
          data: (dashboard) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodProgress(context, dashboard),
                const SizedBox(height: 24),
                _buildBestTimes(context, dashboard),
                const SizedBox(height: 24),
                _buildProductivityPatterns(context, dashboard),
                const SizedBox(height: 24),
                _buildDifficultyStats(context, dashboard),
                const SizedBox(height: 24),
                _buildStatBalance(context, dashboard),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.white38),
                const SizedBox(height: 16),
                Text(
                  'Error loading analytics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodProgress(BuildContext context, dashboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress Overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildProgressCard(
                'This Week',
                dashboard.weeklyProgress.questsCompleted,
                dashboard.weeklyProgress.xpEarned,
                Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProgressCard(
                'This Month',
                dashboard.monthlyProgress.questsCompleted,
                dashboard.monthlyProgress.xpEarned,
                Icons.calendar_month,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCard(String label, int quests, int xp, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$quests Quests',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$xp XP Earned',
            style: const TextStyle(
              color: AppTheme.primaryPurple,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestTimes(BuildContext context, dashboard) {
    final bestTimes = dashboard.bestCompletionTimes;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: AppTheme.primaryPurple),
              const SizedBox(width: 8),
              Text(
                'Best Completion Times',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (bestTimes.recommendation != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: AppTheme.primaryPurple, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bestTimes.recommendation!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          ...bestTimes.bestHours.map((hourCount) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      hourCount.timeString,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: hourCount.count / (bestTimes.bestHours.first.count),
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primaryPurple),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${hourCount.count}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductivityPatterns(BuildContext context, dashboard) {
    final patterns = dashboard.productivityPatterns;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppTheme.primaryPurple),
              const SizedBox(width: 8),
              Text(
                'Weekly Patterns',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPatternBadge(
                '🏆 Most Productive',
                patterns.mostProductiveDay.day,
                '${patterns.mostProductiveDay.count} quests',
                Colors.green,
              ),
              _buildPatternBadge(
                '💤 Least Active',
                patterns.leastProductiveDay.day,
                '${patterns.leastProductiveDay.count} quests',
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatternBadge(String label, String day, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyStats(BuildContext context, dashboard) {
    final difficulties = ['Easy', 'Medium', 'Hard', 'Expert'];
    final icons = [Icons.sentiment_satisfied, Icons.sentiment_neutral, Icons.sentiment_dissatisfied, Icons.warning];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: AppTheme.primaryPurple),
              const SizedBox(width: 8),
              Text(
                'Quest Analytics by Difficulty',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(4, (index) {
            final diff = index + 1;
            final stats = dashboard.questsByDifficulty[diff];
            if (stats == null || stats.completed == 0) return const SizedBox.shrink();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(icons[index], size: 20, color: Colors.white70),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: Text(
                      difficulties[index],
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${stats.completed} completed • Avg ${stats.averageTime} min',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatBalance(BuildContext context, dashboard) {
    if (dashboard.statBalance == null) return const SizedBox.shrink();
    
    final balance = dashboard.statBalance;
    final balanceColor = balance!.balance == 'Excellent' ? Colors.green :
                         balance.balance == 'Good' ? Colors.blue :
                         balance.balance == 'Fair' ? Colors.orange : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.balance, color: AppTheme.primaryPurple),
              const SizedBox(width: 8),
              Text(
                'Stat Balance',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: balanceColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: balanceColor),
                ),
                child: Text(
                  balance.balance,
                  style: TextStyle(color: balanceColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatIndicator('💪 Strongest', balance.mostDeveloped, Colors.green),
              _buildStatIndicator('📈 Needs Work', balance.leastDeveloped, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatIndicator(String label, String stat, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
