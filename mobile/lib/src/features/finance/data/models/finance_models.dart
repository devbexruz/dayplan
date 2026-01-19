class FinanceCategory {
  final int id;
  final String name;
  final String type; // active_income, passive_income, expense

  FinanceCategory({required this.id, required this.name, required this.type});

  factory FinanceCategory.fromJson(Map<String, dynamic> json) {
    return FinanceCategory(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'type': type};
  }
}

class Finance {
  final int id;
  final int amount;
  final String type;
  final String? expenseFrequency;
  final int categoryId;
  final String? description;
  final DateTime date;
  final FinanceCategory? category;

  Finance({
    required this.id,
    required this.amount,
    required this.type,
    this.expenseFrequency,
    required this.categoryId,
    this.description,
    required this.date,
    this.category,
  });

  factory Finance.fromJson(Map<String, dynamic> json) {
    return Finance(
      id: json['id'],
      amount: json['amount'],
      type: json['type'],
      expenseFrequency: json['expense_frequency'],
      categoryId: json['category_id'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      category: json['category'] != null
          ? FinanceCategory.fromJson(json['category'])
          : null,
    );
  }
}

class MonthlyFinanceStat {
  final String month;
  final double totalIncome;
  final double totalExpense;

  MonthlyFinanceStat({
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
  });

  factory MonthlyFinanceStat.fromJson(Map<String, dynamic> json) {
    return MonthlyFinanceStat(
      month: json['month'],
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
    );
  }
}

class DailyFinanceStat {
  final String date;
  final double totalIncome;
  final double totalExpense;

  DailyFinanceStat({
    required this.date,
    required this.totalIncome,
    required this.totalExpense,
  });

  factory DailyFinanceStat.fromJson(Map<String, dynamic> json) {
    return DailyFinanceStat(
      date: json['date'],
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
    );
  }
}
