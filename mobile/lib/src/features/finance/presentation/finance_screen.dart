import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/providers/daily_status_provider.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/features/finance/presentation/finance_providers.dart';
import 'package:mobile/src/features/finance/presentation/finance_stats_screen.dart';
import 'package:mobile/src/features/finance/data/models/finance_models.dart';
import 'package:mobile/src/features/dashboard/presentation/analytics_providers.dart';

String formatCurrency(num amount) {
  return amount.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]} ',
  );
}

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  void _showAddTransactionModal([Finance? financeToEdit]) {
    final isClosed = ref.read(dailyStatusProvider).isFinanceClosed;
    if (isClosed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hisobot yopilgan. Tahrirlash uchun qayta oching.'),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AddTransactionModal(financeToEdit: financeToEdit),
    );
  }

  void _closeDay() {
    ref.read(dailyStatusProvider.notifier).setFinanceClosed(true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Moliya hisoboti yopildi!')));
  }

  void _reopenDay() {
    ref.read(dailyStatusProvider.notifier).setFinanceClosed(false);
  }

  @override
  Widget build(BuildContext context) {
    final isDayClosed = ref.watch(dailyStatusProvider).isFinanceClosed;
    final balanceAsync = ref.watch(balanceProvider);
    final financeListAsync = ref.watch(financeListProvider);
    final dailyStatsAsync = ref.watch(dailyFinanceStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Moliya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        actions: [
          // Refresh button removed
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              ref.invalidate(monthlyStatsProvider);
              ref.invalidate(detailedHistoryProvider('finance_expense'));
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FinanceStatsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(balanceProvider);
          ref.refresh(financeListProvider);
          ref.refresh(dailyFinanceStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jami Balans',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    balanceAsync.when(
                      data: (balance) => Text(
                        '${formatCurrency(balance)} so\'m',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      loading: () => const SizedBox(
                        height: 48,
                        width: 48,
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      error: (err, stack) =>
                          Text('Error', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(height: 24),
                    // Summary Items
                    dailyStatsAsync.when(
                      data: (stats) => Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              context,
                              'Bugungi Kirim',
                              '+${formatCurrency(stats.totalIncome)} so\'m',
                              Icons.arrow_downward,
                              Colors.greenAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryItem(
                              context,
                              'Bugungi Chiqim',
                              '-${formatCurrency(stats.totalExpense)} so\'m',
                              Icons.arrow_upward,
                              Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      error: (e, s) => Text(
                        'Statistika yuklanmadi',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Transactions Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'O\'tkazmalar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isDayClosed)
                    TextButton(child: const Text('Barchasi'), onPressed: () {}),
                ],
              ),
              const SizedBox(height: 16),

              // Transaction List
              financeListAsync.when(
                data: (finances) {
                  if (finances.isEmpty) {
                    return const Center(
                      child: Text('Hozircha o\'tkazmalar yo\'q'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: finances.length,
                    itemBuilder: (context, index) {
                      final finance = finances[index];
                      final isExpense = finance.type == 'expense';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isExpense
                                  ? Icons.shopping_bag_outlined
                                  : Icons.attach_money,
                              color: AppTheme.primary,
                            ),
                          ),
                          title: Text(
                            finance.category?.name ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            finance.date.toString().substring(0, 16),
                          ),
                          trailing: Text(
                            '${isExpense ? '-' : '+'}${formatCurrency(finance.amount)} so\'m',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: isExpense
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          onTap: () => _showAddTransactionModal(finance),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Xatolik: $err')),
              ),

              const SizedBox(height: 32),

              // Close Day Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isDayClosed ? _reopenDay : _closeDay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDayClosed
                        ? Colors.white10
                        : AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isDayClosed
                        ? 'Hisobotni Qayta Ochish'
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
          ),
        ),
      ),
      floatingActionButton: isDayClosed
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddTransactionModal(),
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AddTransactionModal extends ConsumerStatefulWidget {
  final Finance? financeToEdit;
  const AddTransactionModal({super.key, this.financeToEdit});

  @override
  ConsumerState<AddTransactionModal> createState() =>
      _AddTransactionModalState();
}

class _AddTransactionModalState extends ConsumerState<AddTransactionModal> {
  // Types
  String _transactionType = 'expense'; // expense, active_income, passive_income
  String _expenseFrequency = 'one_time'; // weekly, monthly, yearly, one_time

  final _amountController = TextEditingController();
  final _categoryController = TextEditingController(); // For new category name
  final _descriptionController = TextEditingController();

  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.financeToEdit != null) {
      final f = widget.financeToEdit!;
      _transactionType = f.type;
      _amountController.text = formatCurrency(f.amount);
      _selectedCategoryId = f.categoryId;
      _descriptionController.text = f.description ?? '';
      if (f.expenseFrequency != null) {
        _expenseFrequency = f.expenseFrequency!;
      }
      // Since category name is separate, we can't easily pre-fill name unless passed,
      // but we have categoryId. The chip selector should work if we have id.
      // We don't prefill _categoryController text unless it's new, but here it's existing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final isEditing = widget.financeToEdit != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEditing ? 'Tahrirlash' : 'Yangi O\'tkazma',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Type Selection
            const Text('Turi', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    'Chiqim',
                    'expense',
                    Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    'Active Kirim',
                    'active_income',
                    Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    'Passive',
                    'passive_income',
                    Colors.tealAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Expense Frequency (Only visible if Expense)
            if (_transactionType == 'expense') ...[
              const Text('Davriylik', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFrequencyButton('Bir martalik', 'one_time'),
                    const SizedBox(width: 8),
                    _buildFrequencyButton('Haftalik', 'weekly'),
                    const SizedBox(width: 8),
                    _buildFrequencyButton('Oylik', 'monthly'),
                    const SizedBox(width: 8),
                    _buildFrequencyButton('Yillik', 'yearly'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Amount Input
            TextField(
              controller: _amountController,
              inputFormatters: [CurrencyInputFormatter()],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Summa',
                suffixText: ' so\'m',
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Selection/Input (Dynamic)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kategoriya',
                  style: TextStyle(color: Colors.white54),
                ),
                Text(
                  _transactionType == 'expense'
                      ? '(Xarajat turlari)'
                      : _transactionType == 'active_income'
                      ? '(Faol daromad manbalari)'
                      : '(Passiv manbalar)',
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Categories Display
            categoriesAsync.when(
              data: (categories) {
                final currentCategories = categories
                    .where((c) => c.type == _transactionType)
                    .toList();
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: currentCategories
                      .map((c) => _buildCategoryChip(c.name, c.id))
                      .toList(),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => Text('Error loading categories'),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: _selectedCategoryId == null
                    ? 'Yangi kategoriya qo\'shish...'
                    : 'Tanlangan kategoriya (yangi yaratish uchun bekor qiling)',
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon:
                    _categoryController.text.isNotEmpty ||
                        _selectedCategoryId != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          setState(() {
                            _categoryController.clear();
                            _selectedCategoryId = null;
                          });
                        },
                      )
                    : null,
                enabled: _selectedCategoryId == null,
              ),
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Description Input
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Izoh (ixtiyoriy)',
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing ? 'Yangilash' : 'Saqlash',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, int id) {
    final isSelected = _selectedCategoryId == id;
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected
          ? AppTheme.primary
          : Colors.white.withOpacity(0.05),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onPressed: () {
        setState(() {
          _selectedCategoryId = id;
          _categoryController.text = label;
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    );
  }

  Widget _buildTypeButton(String label, String value, Color color) {
    final isSelected = _transactionType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _transactionType = value;
          _selectedCategoryId = null;
          _categoryController.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFrequencyButton(String label, String value) {
    final isSelected = _expenseFrequency == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (v) => setState(() => _expenseFrequency = value),
      backgroundColor: Colors.white.withOpacity(0.05),
      selectedColor: AppTheme.primary.withOpacity(0.3),
      checkmarkColor: AppTheme.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    );
  }

  Future<void> _saveTransaction() async {
    final amount = int.tryParse(_amountController.text.replaceAll(' ', ''));
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Iltimos summani kiriting')));
      return;
    }

    final repo = ref.read(financeRepositoryProvider);
    int categoryId;

    try {
      if (_selectedCategoryId != null) {
        categoryId = _selectedCategoryId!;
      } else if (_categoryController.text.isNotEmpty) {
        // Create new category
        final newCat = await repo.createCategory(
          _categoryController.text,
          _transactionType,
        );
        categoryId = newCat.id;
        // Refresh categories
        ref.invalidate(categoryListProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Iltimos kategoriyani tanlang')),
        );
        return;
      }

      if (widget.financeToEdit != null) {
        // Update Mode
        await repo.updateFinance(
          id: widget.financeToEdit!.id,
          amount: amount,
          type: _transactionType,
          categoryId: categoryId,
          expenseFrequency: _transactionType == 'expense'
              ? _expenseFrequency
              : null,
          description: _descriptionController.text,
        );
      } else {
        // Create Mode
        await repo.createFinance(
          amount: amount,
          type: _transactionType,
          categoryId: categoryId,
          expenseFrequency: _transactionType == 'expense'
              ? _expenseFrequency
              : null,
          description: _descriptionController.text,
        );
      }

      // Refresh data
      ref.invalidate(balanceProvider);
      ref.invalidate(financeListProvider);
      ref.invalidate(dailyFinanceStatsProvider);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }
    }
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    int value = int.tryParse(newText) ?? 0;

    // Format with spaces
    String formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
