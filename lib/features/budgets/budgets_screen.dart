import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final txnsAsync = ref.watch(monthlyTransactionsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    final catMap = {
      for (final c in categoriesAsync.valueOrNull ?? <Category>[]) c.id: c
    };
    final txns = txnsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Budgets — ${DateFormat('MMM yyyy').format(month)}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => _BudgetFormScreen(month: month))),
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (budgets) {
          if (budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_outlined,
                      size: 56, color: context.colors.textHint),
                  const SizedBox(height: 12),
                  Text('No budgets set for this month',
                      style: TextStyle(
                          color: context.colors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Tap + to set a budget limit',
                      style:
                          TextStyle(color: context.colors.textHint, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: budgets.length,
            itemBuilder: (_, i) {
              final b = budgets[i];
              final cat = catMap[b.categoryId];
              final spent = txns
                  .where((t) =>
                      t.type == 'expense' && t.categoryId == b.categoryId)
                  .fold(0.0, (s, t) => s + t.amount);
              return _BudgetCard(
                budget: b,
                category: cat,
                spent: spent,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        _BudgetFormScreen(existing: b, month: month))),
              );
            },
          );
        },
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetLimit budget;
  final Category? category;
  final double spent;
  final VoidCallback onTap;

  const _BudgetCard({
    required this.budget,
    this.category,
    required this.spent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        budget.limitAmount > 0 ? (spent / budget.limitAmount).clamp(0.0, 1.0) : 0.0;
    final isOver = spent > budget.limitAmount;
    final color = isOver
        ? context.colors.expense
        : progress > 0.8
            ? context.colors.warning
            : context.colors.income;
    final remaining = budget.limitAmount - spent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isOver ? context.colors.expenseLight : context.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(category?.icon ?? '📦',
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.name ?? 'Unknown',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      Text(
                        budget.period.capitalize(),
                        style: TextStyle(
                            color: context.colors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(spent),
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                    Text(
                      'of ${CurrencyFormatter.format(budget.limitAmount)}',
                      style: TextStyle(
                          color: context.colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: context.colors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% used',
                  style: TextStyle(
                      color: context.colors.textSecondary, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  isOver
                      ? 'Over by ${CurrencyFormatter.format(-remaining)}'
                      : '${CurrencyFormatter.format(remaining)} left',
                  style: TextStyle(
                      color: isOver ? context.colors.expense : context.colors.income,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Budget Form ───────────────────────────────────────────────────────────────

class _BudgetFormScreen extends ConsumerStatefulWidget {
  final BudgetLimit? existing;
  final DateTime month;
  const _BudgetFormScreen({this.existing, required this.month});

  @override
  ConsumerState<_BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<_BudgetFormScreen> {
  late TextEditingController _amountCtrl;
  Category? _selectedCategory;
  late String _period;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amountCtrl = TextEditingController(
        text: e?.limitAmount.toStringAsFixed(2) ?? '');
    _period = e?.period ?? 'monthly';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedCategory == null && widget.existing == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a category')));
      return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    try {
      final catId = _selectedCategory?.id ?? widget.existing!.categoryId;
      final companion = BudgetLimitsCompanion(
        categoryId: Value(catId),
        limitAmount: Value(amount),
        period: Value(_period),
        month: Value(widget.month.month),
        year: Value(widget.month.year),
      );
      if (widget.existing != null) {
        await db.updateBudget(
            companion.copyWith(id: Value(widget.existing!.id)));
      } else {
        await db.insertBudget(companion);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    await ref.read(databaseProvider).deleteBudget(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final cats = categoriesAsync.valueOrNull ?? [];

    // Init selected category
    if (_selectedCategory == null && widget.existing != null && cats.isNotEmpty) {
      _selectedCategory = cats.firstWhere(
          (c) => c.id == widget.existing!.categoryId,
          orElse: () => cats.first);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Budget' : 'Add Budget'),
        actions: [
          if (widget.existing != null)
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Category
          Text('Category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (widget.existing != null)
            // When editing, category is locked
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(cats
                          .firstWhere(
                              (c) => c.id == widget.existing!.categoryId,
                              orElse: () => cats.first)
                          .icon,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    cats
                        .firstWhere(
                            (c) => c.id == widget.existing!.categoryId,
                            orElse: () => cats.first)
                        .name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cats.map((c) {
                final sel = _selectedCategory?.id == c.id;
                final color = AppColors.categoryColors[
                    c.colorIndex % AppColors.categoryColors.length];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? context.colors.primarySurface
                          : context.colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: sel
                          ? Border.all(color: color)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.icon,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(c.name,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? color : context.colors.textPrimary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),

          // Amount
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Budget limit', prefixText: 'RM '),
          ),
          const SizedBox(height: 20),

          // Period
          Text('Period', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['monthly', 'weekly', 'yearly'].map((p) {
              final sel = _period == p;
              return ChoiceChip(
                label: Text(p.capitalize()),
                selected: sel,
                onSelected: (_) => setState(() => _period = p),
                selectedColor: context.colors.primarySurface,
                labelStyle: TextStyle(
                    color: sel ? context.colors.primary : context.colors.textPrimary,
                    fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(widget.existing != null
                      ? 'Save Changes'
                      : 'Add Budget'),
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
