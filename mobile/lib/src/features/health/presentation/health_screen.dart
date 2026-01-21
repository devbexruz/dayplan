import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/providers/daily_status_provider.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/features/health/presentation/manage_sports_screen.dart';
import 'package:mobile/src/features/health/presentation/health_providers.dart';
import 'package:mobile/src/features/health/data/models/health_models.dart';
import 'package:mobile/src/features/health/presentation/health_stats_screen.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleSleep() async {
    final sleepLogAsync = ref.read(sleepLogProvider);
    final repo = ref.read(healthRepositoryProvider);

    sleepLogAsync.whenData((log) async {
      try {
        final isSleeping = log != null && log.endTime == null;

        if (isSleeping) {
          // Direct Wake Up
          await repo.wakeUp();
        } else {
          // Confirm Sleep
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.surface,
              title: const Text(
                'Rostan ham uxlamoqchimisiz?',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Yo\'q',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Ha',
                    style: TextStyle(color: AppTheme.secondary),
                  ),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await repo.sleep();
          } else {
            return;
          }
        }
        ref.invalidate(sleepLogProvider);
        ref.invalidate(dailyHabitProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
        }
      }
    });
  }

  void _startDay() async {
    try {
      final repo = ref.read(healthRepositoryProvider);
      await repo.wakeUp();
      ref.invalidate(sleepLogProvider);
      ref.invalidate(dailyHabitProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }
    }
  }

  void _addSport() {
    if (ref.read(dailyStatusProvider).isHealthSaved) return;

    final nameController = TextEditingController();
    final setsController = TextEditingController();
    final repsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Yangi Mashq', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Mashq nomi',
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: setsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Sets',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: repsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Reps',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final repo = ref.read(healthRepositoryProvider);
                try {
                  int sets = int.tryParse(setsController.text) ?? 0;
                  int reps = int.tryParse(repsController.text) ?? 0;
                  // 1. Create Type with sets/reps
                  await repo.createExerciseType(
                    name: nameController.text,
                    sets: sets,
                    reps: reps,
                  );
                  // 3. Refresh
                  ref.refresh(exerciseTypesProvider);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
                  }
                }
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              'Qo\'shish',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSportCheck(
    ExerciseType type,
    SportLog? log,
    bool isCompleted,
  ) async {
    if (ref.read(dailyStatusProvider).isHealthSaved) return;
    final repo = ref.read(healthRepositoryProvider);
    try {
      if (log == null) {
        // Create log first
        final newLog = await repo.createSportLog(exerciseTypeId: type.id);
        if (isCompleted) {
          await repo.updateSportLogStatus(newLog.id, true);
        }
      } else {
        await repo.updateSportLogStatus(log.id, isCompleted);
      }
      ref.refresh(sportLogsProvider);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _saveReport() {
    ref.read(dailyStatusProvider.notifier).setHealthSaved(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mashg\'ulotlar hisoboti saqlandi!')),
    );
  }

  void _editReport() {
    ref.read(dailyStatusProvider.notifier).setHealthSaved(false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mashg\'ulotlarni tahrirlash rejimi!')),
    );
  }

  void _editType(ExerciseType type) {
    if (ref.read(dailyStatusProvider).isHealthSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hisobot saqlangan. Tahrirlash uchun tahrirlash rejimiga o\'ting.',
          ),
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: type.name);
    final setsController = TextEditingController(text: type.sets.toString());
    final repsController = TextEditingController(text: type.reps.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Tahrirlash', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Mashq nomi',
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: setsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Sets',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: repsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Reps',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () async {
              final repo = ref.read(healthRepositoryProvider);
              try {
                await repo.updateExerciseType(
                  id: type.id,
                  name: nameController.text,
                  sets: int.tryParse(setsController.text) ?? 0,
                  reps: int.tryParse(repsController.text) ?? 0,
                  isActive: type.isActive,
                );
                ref.invalidate(sportLogsProvider);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
                }
              }
            },
            child: const Text(
              'Saqlash',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showStats(BuildContext context) {
    ref.invalidate(detailedHealthStatsProvider);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HealthStatsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReportSaved = ref.watch(dailyStatusProvider).isHealthSaved;
    final logsAsync = ref.watch(sportLogsProvider);
    final typesAsync = ref.watch(exerciseTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sog\'lik',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => _showStats(context),
            icon: const Icon(
              Icons.bar_chart_rounded,
              color: AppTheme.secondary,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageSportsScreen()),
            ),
            icon: const Icon(Icons.settings, color: AppTheme.secondary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(exerciseTypesProvider);
          ref.refresh(sportLogsProvider);
          ref.refresh(sleepLogProvider);
          ref.refresh(dailyHabitProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Daily Habits Section (Sleep, Food, Hygiene)
              _buildDailyHabits(context),
              const SizedBox(height: 24),

              // Sport Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sport va Mashqlar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isReportSaved)
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppTheme.secondary,
                      ),
                      onPressed: _addSport,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Sport List
              // Sport List
              typesAsync.when(
                data: (types) {
                  final activeTypes = types.where((t) => t.isActive).toList();
                  if (activeTypes.isEmpty) {
                    return const Center(
                      child: Text(
                        'Faol mashqlar yo\'q. Sozlamalardan qo\'shing!',
                      ),
                    );
                  }

                  return logsAsync.when(
                    data: (logs) {
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeTypes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final type = activeTypes[index];
                          SportLog? log;
                          try {
                            log = logs.firstWhere(
                              (l) => l.exerciseTypeId == type.id,
                            );
                          } catch (_) {}

                          return _buildSportItem(
                            context,
                            log?.id ?? -1, // -1 means not created
                            type.name,
                            '${type.sets} set x ${type.reps} reps',
                            log?.isCompleted ?? false,
                            isReportSaved,
                            onLongPress: () => _editType(type),
                            onToggle: (val) =>
                                _toggleSportCheck(type, log, val ?? false),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),

              const SizedBox(height: 32),

              // Save/Edit Button (Specific to Sports)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isReportSaved ? _editReport : _saveReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReportSaved
                        ? Colors.white10
                        : AppTheme.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isReportSaved
                        ? 'Mashg\'ulotlarni Tahrirlash'
                        : 'Mashg\'ulotlarni Saqlash',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyHabits(BuildContext context) {
    final sleepLogAsync = ref.watch(sleepLogProvider);
    final dailyHabitAsync = ref.watch(dailyHabitProvider);

    return sleepLogAsync.when(
      data: (sleepLog) {
        final dailyHabit = dailyHabitAsync.value;
        final isSleeping = sleepLog != null && sleepLog.endTime == null;
        final isDayStarted = dailyHabit != null;

        // Timer Logic for Sleeping
        String timerText = "";
        Duration? sleepDuration;
        Duration? timeSinceWake;

        if (isSleeping) {
          try {
            final start = DateTime.parse(sleepLog!.startTime);
            final duration = DateTime.now().difference(start);
            timerText = _formatDuration(duration);
          } catch (_) {}
        } else {
          // Calculate last sleep stats
          if (sleepLog != null && sleepLog.endTime != null) {
            try {
              final start = DateTime.parse(sleepLog.startTime);
              final end = DateTime.parse(sleepLog.endTime!);
              sleepDuration = end.difference(start);
              timeSinceWake = DateTime.now().difference(end);
            } catch (_) {}
          }
        }

        if (isSleeping) {
          // Sleeping UI
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade900, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigoAccent.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.nights_stay_rounded,
                  size: 64,
                  color: Colors.amberAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Hayrli tun",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  timerText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  onPressed: _toggleSleep,
                  child: const Text(
                    "Uxlashni bekor qilish",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          );
        }

        // Awake / Start Day UI
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sunny,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Uyqu',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        if (!isDayStarted)
                          const Text(
                            "Kuningizni boshlang!",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        else if (sleepLog != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Uyg'oq",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (sleepDuration != null &&
                                  timeSinceWake != null)
                                Text(
                                  "${_formatDuration(sleepDuration!)} uxlandi (${_formatDuration(timeSinceWake!)} oldin)",
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          )
                        else
                          const Text(
                            "Uyg'oq",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isDayStarted)
                    ElevatedButton.icon(
                      onPressed: _toggleSleep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.nights_stay),
                      label: const Text("Uxlayapman"),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _startDay, // Trigger Wake Up logic
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.sunny),
                      label: const Text("Boshlash"),
                    ),
                ],
              ),

              if (isDayStarted) ...[
                const Divider(height: 32, color: Colors.white10),
                dailyHabitAsync.when(
                  data: (habit) {
                    final mealCount = habit?.mealCount ?? 0;
                    final hygiene = habit?.morningHygieneDone ?? false;

                    return Column(
                      children: [
                        _buildHabitRow(
                          context,
                          'Ovqatlanish',
                          '$mealCount marta',
                          Icons.restaurant_rounded,
                          Colors.orangeAccent,
                          action: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.white38,
                                onPressed: () {
                                  if (mealCount > 0) {
                                    ref
                                        .read(healthRepositoryProvider)
                                        .updateDailyHabit(
                                          mealCount: mealCount - 1,
                                          morningHygieneDone: hygiene,
                                        )
                                        .then(
                                          (_) =>
                                              ref.refresh(dailyHabitProvider),
                                        );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: AppTheme.secondary,
                                onPressed: () {
                                  ref
                                      .read(healthRepositoryProvider)
                                      .updateDailyHabit(
                                        mealCount: mealCount + 1,
                                        morningHygieneDone: hygiene,
                                      )
                                      .then(
                                        (_) => ref.refresh(dailyHabitProvider),
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 32, color: Colors.white10),
                        _buildHabitRow(
                          context,
                          'Ertalabki tozalik',
                          hygiene ? 'Bajarildi' : 'Bajarilmadi',
                          Icons.clean_hands_rounded,
                          Colors.tealAccent,
                          action: Switch(
                            value: hygiene,
                            activeColor: AppTheme.secondary,
                            onChanged: (v) {
                              ref
                                  .read(healthRepositoryProvider)
                                  .updateDailyHabit(
                                    mealCount: mealCount,
                                    morningHygieneDone: v,
                                  )
                                  .then((_) => ref.refresh(dailyHabitProvider));
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Widget _buildHabitRow(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    Widget? action,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildSportItem(
    BuildContext context,
    int id,
    String name,
    String details,
    bool isCompleted,
    bool isReportSaved, {
    VoidCallback? onLongPress,
    ValueChanged<bool?>? onToggle,
  }) {
    return Card(
      child: ListTile(
        onLongPress: onLongPress,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.fitness_center_rounded,
            color: AppTheme.secondary,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(details),
        trailing: isReportSaved
            ? Icon(
                isCompleted ? Icons.check_circle : Icons.cancel,
                color: isCompleted ? AppTheme.secondary : Colors.grey,
              )
            : Checkbox(
                value: isCompleted,
                activeColor: AppTheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: onToggle,
              ),
      ),
    );
  }
}
