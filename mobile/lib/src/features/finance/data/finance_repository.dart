import 'package:mobile/src/core/api/api_client.dart';
import 'package:mobile/src/features/finance/data/models/finance_models.dart';

class FinanceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<FinanceCategory>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/finance/categories/');
      return (response.data as List)
          .map((e) => FinanceCategory.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<FinanceCategory> createCategory(String name, String type) async {
    try {
      final response = await _apiClient.dio.post(
        '/finance/categories/',
        data: {'name': name, 'type': type},
      );
      return FinanceCategory.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  Future<List<Finance>> getFinances() async {
    try {
      final response = await _apiClient.dio.get('/finance/');
      return (response.data as List).map((e) => Finance.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load finances: $e');
    }
  }

  Future<Finance> createFinance({
    required int amount,
    required String type,
    required int categoryId,
    String? expenseFrequency,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/finance/',
        data: {
          'amount': amount,
          'type': type,
          'category_id': categoryId,
          'expense_frequency': expenseFrequency,
          'description': description,
        },
      );
      return Finance.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create finance: $e');
    }
  }

  Future<Finance> updateFinance({
    required int id,
    required int amount,
    required String type,
    required int categoryId,
    String? expenseFrequency,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/finance/$id',
        data: {
          'amount': amount,
          'type': type,
          'category_id': categoryId,
          'expense_frequency': expenseFrequency,
          'description': description,
        },
      );
      return Finance.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update finance: $e');
    }
  }

  Future<int> getBalance() async {
    try {
      final response = await _apiClient.dio.get('/finance/balance');
      return response.data['balance'];
    } catch (e) {
      throw Exception('Failed to load balance: $e');
    }
  }

  Future<List<MonthlyFinanceStat>> getMonthlyStats() async {
    try {
      final response = await _apiClient.dio.get('/finance/stats/monthly');
      return (response.data as List)
          .map((e) => MonthlyFinanceStat.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to load monthly stats: $e');
    }
  }

  Future<DailyFinanceStat> getDailyStats() async {
    try {
      final response = await _apiClient.dio.get('/finance/stats/daily');
      return DailyFinanceStat.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load daily stats: $e');
    }
  }
}
