import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/features/health/presentation/health_providers.dart';

class ManageSportsScreen extends ConsumerWidget {
  const ManageSportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(exerciseTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mashqlar Ro\'yxati')),
      body: typesAsync.when(
        data: (types) {
          if (types.isEmpty)
            return const Center(child: Text("Mashqlar topilmadi"));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: types.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final type = types[index];
              return SwitchListTile(
                title: Text(
                  type.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  "${type.sets} sets x ${type.reps} reps",
                  style: const TextStyle(color: Colors.white54),
                ),
                value: type.isActive,
                activeColor: AppTheme.secondary,
                tileColor: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onChanged: (val) async {
                  final repo = ref.read(healthRepositoryProvider);
                  try {
                    await repo.updateExerciseType(
                      id: type.id,
                      name: type.name,
                      sets: type.sets,
                      reps: type.reps,
                      isActive: val,
                    );
                    ref.refresh(exerciseTypesProvider);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
                    }
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Xatolik: $e")),
      ),
    );
  }
}
