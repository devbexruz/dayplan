import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/providers/daily_status_provider.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/features/dashboard/presentation/dashboard_providers.dart';
import 'package:mobile/src/features/dashboard/data/models/work_status.dart';
import 'package:mobile/src/features/dashboard/presentation/analytics_providers.dart';
import 'package:mobile/src/features/dashboard/presentation/work_stats_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isActiveSelected = false;
  bool _isPassiveSelected = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  void _toggleActive() {
    final status = ref.read(dailyStatusProvider);
    if (status.isWorkSaved) return;
    setState(() {
      _isActiveSelected = !_isActiveSelected;
    });
  }

  void _togglePassive() {
    final status = ref.read(dailyStatusProvider);
    if (status.isWorkSaved) return;
    setState(() {
      _isPassiveSelected = !_isPassiveSelected;
    });
  }

  void _saveWorkReport() async {
    try {
      final repo = ref.read(dashboardRepositoryProvider);
      final newStatus = WorkStatus(
        active: _isActiveSelected,
        passive: _isPassiveSelected,
        isSaved: true,
      );

      await repo.updateWorkStatus(newStatus);

      ref.read(dailyStatusProvider.notifier).setWorkSaved(true);
      ref.invalidate(workStatusProvider);
      ref.invalidate(workStatsProvider); // Refresh stats too

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ish hisoboti saqlandi!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }
    }
  }

  void _editWorkReport() {
    ref.read(dailyStatusProvider.notifier).setWorkSaved(false);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(dailyStatusProvider);

    // Listen to remote data to init local state
    ref.listen<AsyncValue<WorkStatus>>(workStatusProvider, (prev, next) {
      next.whenData((workStatus) {
        if (!_isInitialized) {
          setState(() {
            _isActiveSelected = workStatus.active;
            _isPassiveSelected = workStatus.passive;
            _isInitialized = true;
            if (workStatus.isSaved) {
              ref.read(dailyStatusProvider.notifier).setWorkSaved(true);
            }
          });
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Xush kelibsiz, Behruz',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Work Report (Ish)
            _buildWorkReportCard(context, status.isWorkSaved),
            const SizedBox(height: 24),

            // Daily Report Status Title
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  'Kunlik Hisobot Holati',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Report Status Grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.4,
              children: [
                _buildStatusCard(
                  context,
                  'Moliya',
                  status.isFinanceClosed ? 'Yopilgan' : 'Ochiq',
                  Icons.account_balance_wallet,
                  AppTheme.primary,
                  status.isFinanceClosed,
                ),
                _buildStatusCard(
                  context,
                  'Sog\'lik',
                  status.isHealthSaved ? 'Saqlangan' : 'Kutilmoqda',
                  Icons.favorite,
                  AppTheme.secondary,
                  status.isHealthSaved,
                ),
                _buildStatusCard(
                  context,
                  'Aql',
                  status.isMindSaved ? 'Saqlangan' : 'Kutilmoqda',
                  Icons.psychology,
                  AppTheme.tertiary,
                  status.isMindSaved,
                ),
                _buildStatusCard(
                  context,
                  'Ish',
                  status.isWorkSaved ? 'Saqlangan' : 'Kutilmoqda',
                  Icons.work,
                  Colors.blueAccent,
                  status.isWorkSaved,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Work Stats (Motivational)
            _buildWorkMotivationCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkMotivationCard(BuildContext context) {
    final workStatsAsync = ref.watch(workStatsProvider);

    return workStatsAsync.when(
      data: (stats) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade900,
                Colors.purpleAccent.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Muvaffaqiyat Statistikasi",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ref.invalidate(workStatsProvider);
                      ref.invalidate(detailedHistoryProvider('work'));
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WorkStatsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    "Streak",
                    "${stats.streakDays} kun",
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                  _buildStatItem(
                    "Haftalik",
                    "${stats.completionRateWeekly.toInt()}%",
                    Icons.pie_chart,
                    Colors.cyanAccent,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.format_quote_rounded,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 8),
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
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, s) =>
          const SizedBox.shrink(), // Hide if error or not supported
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildWorkReportCard(BuildContext context, bool isWorkSaved) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.work_history_rounded,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Bugungi Ish Hisoboti',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              if (isWorkSaved)
                const Icon(Icons.check_circle, color: Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _toggleActive,
                  child: _buildWorkOption(
                    context,
                    'Active',
                    _isActiveSelected,
                    Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _togglePassive,
                  child: _buildWorkOption(
                    context,
                    'Passive',
                    _isPassiveSelected,
                    Colors.cyanAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isWorkSaved ? _editWorkReport : _saveWorkReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: isWorkSaved
                    ? Colors.white.withOpacity(0.1)
                    : Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isWorkSaved ? "Taxrirlash" : "Saqlash"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkOption(
    BuildContext context,
    String title,
    bool isSelected,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
        border: Border.all(
          color: isSelected ? color : Colors.white12,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isSelected ? Icons.check_circle : Icons.circle_outlined,
            color: isSelected ? color : Colors.white24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    String title,
    String status,
    IconData icon,
    Color color,
    bool isCompleted,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted ? color.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (isCompleted) Icon(Icons.check_circle, color: color, size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCompleted ? Colors.white : Colors.white54,
                ),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
