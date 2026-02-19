import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/analytics_provider.dart';
import 'estimated_vs_actual_chart.dart';
import 'focus_trend_chart.dart';

class PerformanceAnalysisSection extends ConsumerWidget {
  const PerformanceAnalysisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAnalyticsAsync = ref.watch(clientAnalyticsProvider);

    return clientAnalyticsAsync.when(
      data: (data) {
        final hasTimeData = data.timeAccuracy.isNotEmpty;
        final hasFocusData = data.focusTrends.values.any((v) => v > 0);

        if (!hasTimeData && !hasFocusData) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 32),
            Text(
              'Performance Analysis',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (hasTimeData) ...[
              EstimatedVsActualChart(data: data.timeAccuracy),
              const SizedBox(height: 24),
            ],
            if (hasFocusData) ...[
              FocusTrendChart(data: data.focusTrends),
              const SizedBox(height: 24),
            ],
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Failed to load performance analysis',
          style: TextStyle(color: Colors.red[300], fontSize: 12),
        ),
      ),
    );
  }
}
