import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/features/mind/presentation/mind_providers.dart';

class MindStatsScreen extends ConsumerWidget {
  const MindStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(detailedMindStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Aql Statistikasi",
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
                    "Jami (30 kun)",
                    "${stats.totalTasks30Days} ta",
                    Icons.check_circle_outline,
                    Colors.blueAccent,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    "Kunlik O'rtacha",
                    "${stats.avgTasksPerDay.toStringAsFixed(1)} ta",
                    Icons.psychology,
                    Colors.purpleAccent,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.done_all, color: Colors.greenAccent),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Bajarilish darajasi",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: stats.completionRate / 100,
                            backgroundColor: Colors.white10,
                            color: Colors.greenAccent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "${stats.completionRate.toInt()}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Mashg'ulot turlari bo'yicha",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (stats.typeCounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Ma'lumotlar mavjud emas",
                    style: TextStyle(color: Colors.white38),
                  ),
                ),

              ...stats.typeCounts.entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${entry.value} ta",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              }),
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
