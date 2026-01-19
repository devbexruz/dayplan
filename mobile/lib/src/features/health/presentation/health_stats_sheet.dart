import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/features/health/data/models/stats_models.dart';
import 'package:mobile/src/features/health/presentation/health_providers.dart';

class HealthStatsSheet extends ConsumerWidget {
  const HealthStatsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(detailedHealthStatsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Sog'lik Statistikasi",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          statsAsync.when(
            data: (stats) => Column(
              children: [
                _buildSectionTitle("Uyqu (Sleep)"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                      "Kunlik O'rtacha",
                      "${stats.avgDailySleep.toStringAsFixed(1)} h",
                      Icons.bedtime,
                      Colors.indigoAccent,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      "Bir marta",
                      "${stats.avgSessionSleep.toStringAsFixed(1)} h",
                      Icons.timer,
                      Colors.blueAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionTitle("Ovqatlanish (Food)"),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                      "Bu hafta (o'rtacha)",
                      "${stats.weeklyAvgMeals.toStringAsFixed(1)} ta",
                      Icons.restaurant,
                      Colors.orangeAccent,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      "Bu oy (o'rtacha)",
                      "${stats.monthlyAvgMeals.toStringAsFixed(1)} ta",
                      Icons.calendar_today,
                      Colors.deepOrangeAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionTitle("Tozalik (Hygiene)"),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.clean_hands, color: Colors.cyanAccent),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Ertalabki tozalik",
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: stats.hygieneConsistency / 100,
                              backgroundColor: Colors.white10,
                              color: Colors.cyanAccent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "${stats.hygieneConsistency.toInt()}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ), // Added missing closing parenthesis for the Container here.
                const SizedBox(height: 24),
                _buildSectionTitle("Mashqlar Statistikasi (7 kunlik grafik)"),
                const SizedBox(height: 12),
                if (stats.exerciseStats.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "Mashqlar statistikasi mavjud emas",
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                ...stats.exerciseStats.map(
                  (e) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.exerciseName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Jami (30 kun): ${e.count30Days} marta",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 40,
                                child: _buildMiniChart(e.last7DaysCounts),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "7 kun",
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) =>
                Text("Error: $e", style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMiniChart(List<int> counts) {
    int max = counts.fold(0, (prev, elem) => elem > prev ? elem : prev);
    if (max == 0) max = 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: counts.map((c) {
        return Container(
          width: 8,
          height: (30 * (c / max)).clamp(
            4.0,
            30.0,
          ), // Min height 4 for visibility
          decoration: BoxDecoration(
            color: c > 0 ? Colors.greenAccent : Colors.white12,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.bold,
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
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
