import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/features/mind/presentation/mind_providers.dart';

class ManageMindTasksScreen extends ConsumerWidget {
  const ManageMindTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(taskTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mashg\'ulotlar Ro\'yxati')),
      body: typesAsync.when(
        data: (types) {
          if (types.isEmpty)
            return const Center(child: Text("Mashg\'ulotlar topilmadi"));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: types.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final type = types[index];
              return SwitchListTile(
                title: Text(
                  type.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: type.description != null
                    ? Text(
                        type.description!,
                        style: const TextStyle(color: Colors.white54),
                      )
                    : null,
                value: type.isActive,
                activeColor: AppTheme.secondary,
                tileColor: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onChanged: (val) async {
                  final repo = ref.read(mindRepositoryProvider);
                  try {
                    await repo.updateTaskType(
                      type.id,
                      title: type.title,
                      description: type.description,
                      isActive: val,
                    );
                    ref.refresh(taskTypesProvider);
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
