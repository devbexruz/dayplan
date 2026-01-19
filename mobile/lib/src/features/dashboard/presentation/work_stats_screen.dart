import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/features/dashboard/presentation/analytics_providers.dart';
import 'package:mobile/src/features/dashboard/presentation/widgets/stats_chart.dart';

class WorkStatsScreen extends ConsumerWidget {
  const WorkStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(workStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ish Statistikasi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: statsAsync.when(
          data: (stats) => Column(
            children: [
              Row(
                children: [
                  _buildStatCard(
                    "Streak",
                    "${stats.streakDays} kun",
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    "Haftalik",
                    "${stats.completionRateWeekly.toInt()}%",
                    Icons.pie_chart,
                    Colors.cyanAccent,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailedChart(ref),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepOrange.shade900,
                      Colors.orange.shade800,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.yellowAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        stats.motivationMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(
            child: Text("Error: $e", style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedChart(WidgetRef ref) {
    final chartAsync = ref.watch(detailedHistoryProvider('work'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ish Unumdorligi (30 kun)",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        chartAsync.when(
          data: (dStats) => StatsChart(
            stats: dStats,
            color: Colors.blueAccent,
            title: "Kunlik Bajarilish (%)",
          ),
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) =>
              Text("Error: $e", style: const TextStyle(color: Colors.white38)),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
