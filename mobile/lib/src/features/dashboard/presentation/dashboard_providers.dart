import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/api/api_client.dart';
import 'package:mobile/src/features/dashboard/data/dashboard_repository.dart';
import 'package:mobile/src/features/dashboard/data/models/work_status.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ApiClient());
});

final workStatusProvider = FutureProvider<WorkStatus>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getWorkStatus();
});
