import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/features/finance/data/finance_repository.dart';
import 'package:mobile/src/features/finance/data/models/finance_models.dart';

final financeRepositoryProvider = Provider((ref) => FinanceRepository());

final financeListProvider = FutureProvider<List<Finance>>((ref) async {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getFinances();
});

final categoryListProvider = FutureProvider<List<FinanceCategory>>((ref) async {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getCategories();
});

final balanceProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getBalance();
});

final monthlyStatsProvider = FutureProvider<List<MonthlyFinanceStat>>((
  ref,
) async {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getMonthlyStats();
});

final dailyFinanceStatsProvider = FutureProvider<DailyFinanceStat>((ref) async {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getDailyStats();
});
