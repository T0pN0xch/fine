import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';
import '../transactions/add_edit_transaction_screen.dart';
import '../transactions/transactions_screen.dart';
import '../budgets/budgets_screen.dart';
import '../bills/bills_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final txnsAsync = ref.watch(monthlyTransactionsProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final incomeAsync = ref.watch(monthlyIncomeProvider);
    final expenseAsync = ref.watch(monthlyExpenseProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final billsAsync = ref.watch(activeBillsProvider);

    return Scaffold(
      backgroundColor: context.colors.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            _DashboardHeader(month: month),

            // ── Balance Card ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _BalanceCard(
                incomeAsync: incomeAsync,
                expenseAsync: expenseAsync,
                accountsAsync: accountsAsync,
              ),
            ),

            // ── Scrollable Content ───────────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: txnsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (txns) {
                    final catMap = {
                      for (final c
                          in categoriesAsync.valueOrNull ?? <Category>[])
                        c.id: c
                    };
                    final accMap = {
                      for (final a
                          in accountsAsync.valueOrNull ?? <Account>[])
                        a.id: a
                    };
                    final recent = txns.take(5).toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                      children: [
                        // Recent transactions
                        _SectionHeader(
                          title: 'Recent Transactions',
                          onSeeAll: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const TransactionsScreen(
                                    standalone: true)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (recent.isEmpty)
                          _EmptyState(
                            icon: Icons.receipt_long_outlined,
                            message: 'No transactions this month',
                          )
                        else
                          ...recent.map((t) => _TransactionTile(
                                transaction: t,
                                category: t.categoryId != null
                                    ? catMap[t.categoryId]
                                    : null,
                                account: accMap[t.accountId],
                                toAccount: t.toAccountId != null
                                    ? accMap[t.toAccountId]
                                    : null,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddEditTransactionScreen(
                                        existing: t),
                                    fullscreenDialog: true,
                                  ),
                                ),
                              )),

                        const SizedBox(height: 24),

                        // Budget overview
                        budgetsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (budgets) {
                            if (budgets.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionHeader(
                                  title: 'Budget Overview',
                                  onSeeAll: () =>
                                      Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => const BudgetsScreen()),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...budgets.take(3).map((b) => _BudgetTile(
                                      budget: b,
                                      category: catMap[b.categoryId],
                                      spent: txns
                                          .where((t) =>
                                              t.type == 'expense' &&
                                              t.categoryId == b.categoryId)
                                          .fold(0.0,
                                              (sum, t) => sum + t.amount),
                                    )),
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        ),

                        // Upcoming bills
                        billsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (bills) {
                            final upcoming = bills
                                .where((b) => b.nextDueDate
                                    .isBefore(DateTime.now().add(
                                        const Duration(days: 7))))
                                .take(3)
                                .toList();
                            if (upcoming.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionHeader(
                                  title: 'Upcoming Bills',
                                  onSeeAll: () =>
                                      Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => const BillsScreen()),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...upcoming.map((b) => _BillTile(bill: b)),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DashboardHeader extends ConsumerWidget {
  final DateTime month;
  const _DashboardHeader({required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          const Text(
            'Fine',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Month prev
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () {
              final m = ref.read(selectedMonthProvider);
              ref.read(selectedMonthProvider.notifier).state =
                  DateTime(m.year, m.month - 1);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Text(
            DateFormat('MMM yyyy').format(month),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () {
              final m = ref.read(selectedMonthProvider);
              ref.read(selectedMonthProvider.notifier).state =
                  DateTime(m.year, m.month + 1);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Balance Card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final AsyncValue<double> incomeAsync;
  final AsyncValue<double> expenseAsync;
  final AsyncValue<List<Account>> accountsAsync;

  const _BalanceCard({
    required this.incomeAsync,
    required this.expenseAsync,
    required this.accountsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final totalBalance = accountsAsync.valueOrNull
            ?.fold(0.0, (sum, a) => sum + a.balance) ??
        0.0;
    final income = incomeAsync.valueOrNull ?? 0.0;
    final expense = expenseAsync.valueOrNull ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalanceStat(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Income',
                  amount: income,
                  color: const Color(0xFF9FE1CB),
                ),
              ),
              Container(
                  width: 1,
                  height: 40,
                  color: context.colors.primary),
              Expanded(
                child: _BalanceStat(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Expenses',
                  amount: expense,
                  color: const Color(0xFFF09595),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;

  const _BalanceStat({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.colors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 11)),
              Text(
                CurrencyFormatter.formatCompact(amount),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: TextStyle(
                color: context.colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Transaction Tile ──────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final Account? account;
  final Account? toAccount;
  final VoidCallback? onTap;

  const _TransactionTile({
    required this.transaction,
    this.category,
    this.account,
    this.toAccount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final isTransfer = transaction.type == 'transfer';
    final amountColor = isExpense
        ? context.colors.expense
        : isTransfer
            ? context.colors.primary
            : context.colors.income;
    final amountPrefix = isExpense
        ? '- '
        : isTransfer
            ? '⇄ '
            : '+ ';

    final icon = isTransfer
        ? '🔄'
        : category?.icon ?? '📦';
    final title = isTransfer
        ? 'Transfer'
        : category?.name ?? 'Other';
    final subtitle = account?.name ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
                  '$amountPrefix${CurrencyFormatter.format(transaction.amount)}',
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.formatShortDate(transaction.date),
                  style: TextStyle(
                      color: context.colors.textHint, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Budget Tile ───────────────────────────────────────────────────────────────

class _BudgetTile extends StatelessWidget {
  final BudgetLimit budget;
  final Category? category;
  final double spent;

  const _BudgetTile(
      {required this.budget, this.category, required this.spent});

  @override
  Widget build(BuildContext context) {
    final progress = budget.limitAmount > 0
        ? (spent / budget.limitAmount).clamp(0.0, 1.0)
        : 0.0;
    final isOver = spent > budget.limitAmount;
    final color = isOver
        ? context.colors.expense
        : progress > 0.8
            ? context.colors.warning
            : context.colors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(category?.icon ?? '📦',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category?.name ?? 'Budget',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Text(
                '${CurrencyFormatter.format(spent)} / ${CurrencyFormatter.format(budget.limitAmount)}',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bill Tile ─────────────────────────────────────────────────────────────────

class _BillTile extends StatelessWidget {
  final Bill bill;
  const _BillTile({required this.bill});

  @override
  Widget build(BuildContext context) {
    final daysLeft =
        bill.nextDueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;
    final dueLabelColor =
        isOverdue ? context.colors.expense : context.colors.textSecondary;
    final dueLabel = isOverdue
        ? 'Overdue'
        : daysLeft == 0
            ? 'Due today'
            : 'In $daysLeft days';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          Text(bill.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(dueLabel,
                    style:
                        TextStyle(color: dueLabelColor, fontSize: 12)),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(bill.amount),
            style: TextStyle(
              color: context.colors.expense,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: context.colors.textHint),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
