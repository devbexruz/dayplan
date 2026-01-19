import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/providers/daily_status_provider.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/features/mind/presentation/mind_providers.dart';
import 'package:mobile/src/features/mind/data/models/mind_models.dart';
import 'package:mobile/src/features/mind/presentation/mind_stats_screen.dart';
import 'package:mobile/src/features/mind/presentation/manage_mind_tasks_screen.dart';

class MindScreen extends ConsumerStatefulWidget {
  const MindScreen({super.key});

  @override
  ConsumerState<MindScreen> createState() => _MindScreenState();
}

class _MindScreenState extends ConsumerState<MindScreen> {
  // We no longer mock _tasks

  void _addTask() {
    final isSaved = ref.read(dailyStatusProvider).isMindSaved;
    if (isSaved) return;

    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Yangi vazifa',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Vazifa nomi',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final repo = ref.read(mindRepositoryProvider);
                try {
                  // 1. Create Type
                  await repo.createTaskType(controller.text);
                  // 3. Refresh
                  ref.refresh(taskTypesProvider);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
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

  void _toggleTaskCheck(
    MindTaskType type,
    MindLog? log,
    bool isCompleted,
  ) async {
    final repo = ref.read(mindRepositoryProvider);
    try {
      if (log == null) {
        final newLog = await repo.createMindLog(type.id);
        if (isCompleted) await repo.updateMindLogStatus(newLog.id, true);
      } else {
        await repo.updateMindLogStatus(log.id, isCompleted);
      }
      ref.refresh(mindLogsProvider);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status o\'zgarmadi: $e')));
    }
  }

  void _saveReport() {
    ref.read(dailyStatusProvider.notifier).setMindSaved(true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Aql hisoboti saqlandi!')));
  }

  void _editReport() {
    ref.read(dailyStatusProvider.notifier).setMindSaved(false);
  }

  void _editType(MindTaskType type) {
    if (ref.read(dailyStatusProvider).isMindSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hisobot saqlangan. Tahrirlash uchun tahrirlash rejimiga o\'ting.',
          ),
        ),
      );
      return;
    }

    final controller = TextEditingController(text: type.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Vazifani Tahrirlash',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Vazifa nomi',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final repo = ref.read(mindRepositoryProvider);
                try {
                  // 1. Update Type
                  await repo.updateTaskType(
                    type.id,
                    title: controller.text,
                    description: type.description,
                    isActive: type.isActive,
                  );
                  // 3. Refresh
                  ref.refresh(taskTypesProvider);
                  ref.refresh(mindLogsProvider);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
                }
              }
              if (mounted) Navigator.pop(context);
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
    ref.invalidate(detailedMindStatsProvider);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MindStatsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReportSaved = ref.watch(dailyStatusProvider).isMindSaved;
    final logsAsync = ref.watch(mindLogsProvider);
    final typesAsync = ref.watch(taskTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aql', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => _showStats(context),
            icon: const Icon(Icons.bar_chart_rounded, color: AppTheme.tertiary),
          ),
          IconButton(
            onPressed: () => ref.refresh(mindLogsProvider),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageMindTasksScreen()),
            ),
            icon: const Icon(Icons.settings, color: AppTheme.tertiary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(taskTypesProvider);
          ref.refresh(mindLogsProvider);
        },
        child: typesAsync.when(
          data: (types) {
            final activeTypes = types.where((t) => t.isActive).toList();
            return logsAsync.when(
              data: (logs) {
                // Calculate stats based on logs? Or active types?
                // "Bugungi rivojlanish" usually refers to completed tasks among active ones?
                // Or all logs?
                // If I add a type but don't check it, it's 0/1.
                // So stats should be: (completed logs) / (active types count).

                int completedCount = 0;
                for (var type in activeTypes) {
                  if (logs.any(
                    (l) => l.taskTypeId == type.id && l.isCompleted,
                  )) {
                    completedCount++;
                  }
                }
                double progress = activeTypes.isEmpty
                    ? 0
                    : completedCount / activeTypes.length;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.tertiary,
                            AppTheme.tertiary.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bugungi rivojlanish',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$completedCount / ${activeTypes.length} vazifa',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.white24,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.psychology,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tasks Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kunlik Vazifalar',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (!isReportSaved)
                          IconButton(
                            onPressed: _addTask,
                            icon: const Icon(
                              Icons.add,
                              color: AppTheme.tertiary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (activeTypes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'Faol vazifalar yo\'q. Sozlamalardan qo\'shing!',
                          ),
                        ),
                      ),

                    // Task List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeTypes.length,
                      itemBuilder: (context, index) {
                        final type = activeTypes[index];
                        MindLog? log;
                        try {
                          log = logs.firstWhere((l) => l.taskTypeId == type.id);
                        } catch (_) {}

                        return _buildTaskItem(
                          log?.id ?? -1,
                          type.title,
                          log?.isCompleted ?? false,
                          isReportSaved,
                          onLongPress: () => _editType(type),
                          onToggle: (val) =>
                              _toggleTaskCheck(type, log, val ?? false),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Save/Edit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isReportSaved ? _editReport : _saveReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isReportSaved
                              ? Colors.white10
                              : AppTheme.tertiary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isReportSaved
                              ? 'Hisobotni Tahrirlash'
                              : 'Kunlik Hisobotni Saqlash',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildTaskItem(
    int id,
    String title,
    bool isCompleted,
    bool isReportSaved, {
    VoidCallback? onLongPress,
    ValueChanged<bool?>? onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppTheme.tertiary.withOpacity(0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onLongPress: onLongPress,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCompleted
                ? AppTheme.tertiary
                : AppTheme.tertiary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.lightbulb_outline,
            color: isCompleted ? Colors.white : AppTheme.tertiary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.white54 : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: isReportSaved
            ? Icon(
                isCompleted ? Icons.check_circle : Icons.cancel,
                color: isCompleted ? AppTheme.tertiary : Colors.grey,
              )
            : Checkbox(
                value: isCompleted,
                activeColor: AppTheme.tertiary,
                shape: const CircleBorder(),
                onChanged: onToggle,
              ),
      ),
    );
  }
}
