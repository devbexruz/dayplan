import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/features/finance/presentation/finance_providers.dart';
import 'package:mobile/src/features/dashboard/presentation/analytics_providers.dart';
import 'package:mobile/src/features/dashboard/presentation/widgets/stats_chart.dart';

String formatCurrency(num amount) {
  return amount.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]} ',
  );
}

class FinanceStatsScreen extends ConsumerWidget {
  const FinanceStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyStatsAsync = ref.watch(monthlyStatsProvider);
    final expenseTrendAsync = ref.watch(
      detailedHistoryProvider('finance_expense'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Moliya Statistikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Daily Trend
            const Text(
              '30 Kunlik Xarajatlar Trendi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            expenseTrendAsync.when(
              data: (stats) => StatsChart(
                stats: stats,
                color: Colors.redAccent,
                title: "Kunlik Xarajat (so'm)",
              ),
              loading: () => const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) =>
                  Text("Error: $e", style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 32),

            // 2. Monthly Bars
            Text(
              'Oylik Kirim va Chiqimlar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            monthlyStatsAsync.when(
              data: (stats) {
                if (stats.isEmpty) return const Text("Ma'lumot yo'q");

                // Find max value for scaling
                double maxVal = 0;
                for (var s in stats) {
                  if (s.totalIncome > maxVal) maxVal = s.totalIncome;
                  if (s.totalExpense > maxVal) maxVal = s.totalExpense;
                }
                if (maxVal == 0) maxVal = 100;

                final incomeGroups = stats.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.totalIncome,
                        color: Colors.greenAccent,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: e.value.totalExpense,
                        color: Colors.redAccent,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList();

                return Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.5,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxVal * 1.2,
                          titlesData: FlTitlesData(
                            show: true,
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < 0 ||
                                      value.toInt() >= stats.length)
                                    return const SizedBox.shrink();
                                  final label = stats[value.toInt()].month
                                      .split('-')
                                      .last;
                                  return SideTitleWidget(
                                    meta: meta,
                                    child: Text(label),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: maxVal / 5,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.white10,
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: incomeGroups,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legendItem(Colors.greenAccent, "Kirim"),
                        const SizedBox(width: 24),
                        _legendItem(Colors.redAccent, "Chiqim"),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stats.length,
                      itemBuilder: (context, index) {
                        final stat = stats[index];
                        return Card(
                          color: Colors.white.withOpacity(0.05),
                          child: ListTile(
                            title: Text(
                              stat.month,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+${formatCurrency(stat.totalIncome)} so\'m',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                  ),
                                ),
                                Text(
                                  '-${formatCurrency(stat.totalExpense)} so\'m',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  Text("Error: $e", style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
