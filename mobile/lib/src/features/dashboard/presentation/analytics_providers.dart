import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/api/api_client.dart';
import 'package:mobile/src/features/dashboard/data/analytics_repository.dart';
import 'package:mobile/src/features/dashboard/data/models/analytics_models.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ApiClient());
});

final workStatsProvider = FutureProvider<WorkStats>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getWorkStats();
});

final healthStatsProvider = FutureProvider<HealthStats>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getHealthStats();
});

final mindStatsProvider = FutureProvider<MindStats>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getMindStats();
});

final detailedHistoryProvider = FutureProvider.family<DetailedStats, String>((
  ref,
  module,
) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getDetailedHistory(module);
});
