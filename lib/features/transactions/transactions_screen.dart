import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';
import 'add_edit_transaction_screen.dart';
import 'search_screen.dart';
import '../settings/more_menu_drawer.dart';
import '../../core/widgets/bouncy_tap.dart';

class TransactionsScreen extends ConsumerWidget {
  /// When true, shown as a standalone pushed route (from Dashboard "See all").
  final bool standalone;
  /// When true, shows the total pocket-money balance banner (Home tab).
  final bool showBalance;
  const TransactionsScreen(
      {super.key, this.standalone = false, this.showBalance = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final txnsAsync = ref.watch(monthlyTransactionsProvider);
    final incomeAsync = ref.watch(monthlyIncomeProvider);
    final expenseAsync = ref.watch(monthlyExpenseProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final totalBalanceAsync = ref.watch(totalBalanceProvider);

    final catMap = {
      for (final c in categoriesAsync.valueOrNull ?? <Category>[]) c.id: c
    };
    final accMap = {
      for (final a in accountsAsync.valueOrNull ?? <Account>[]) a.id: a
    };

    final weeklySpendingAsync = ref.watch(weeklySpendingProvider);

    final headerWidget = showBalance
        ? _HomeHeader(
            balance: totalBalanceAsync.valueOrNull ?? 0,
            income: incomeAsync.valueOrNull ?? 0,
            expense: expenseAsync.valueOrNull ?? 0,
            weeklySpending: weeklySpendingAsync.valueOrNull ?? const [],
          )
        : Container(
            color: context.colors.primary,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                _MonthSelector(month: month, ref: ref),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryChip(
                        label: 'Income',
                        value: incomeAsync.valueOrNull ?? 0,
                        color: const Color(0xFF9FE1CB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryChip(
                        label: 'Expenses',
                        value: expenseAsync.valueOrNull ?? 0,
                        color: const Color(0xFFF09595),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

    Widget body = txnsAsync.when(
      loading: () => Column(
        children: [
          headerWidget,
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
      error: (e, _) => Column(
        children: [
          headerWidget,
          Expanded(child: Center(child: Text('Error: $e'))),
        ],
      ),
      data: (txns) {
        if (txns.isEmpty) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: headerWidget),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 56, color: context.colors.textHint),
                      const SizedBox(height: 12),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                            color: context.colors.textSecondary, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to add your first one',
                        style: TextStyle(
                            color: context.colors.textHint, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // Group by date
        final groups = <DateTime, List<Transaction>>{};
        for (final t in txns) {
          final day = DateTime(t.date.year, t.date.month, t.date.day);
          groups.putIfAbsent(day, () => []).add(t);
        }
        final dates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: headerWidget),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final date = dates[i];
                    final dayTxns = groups[date]!;
                    final dayExpense = dayTxns
                        .where((t) => t.type == 'expense')
                        .fold(0.0, (s, t) => s + t.amount);
                    final dayIncome = dayTxns
                        .where((t) => t.type == 'income')
                        .fold(0.0, (s, t) => s + t.amount);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                DateFormatter.formatDayGroupLabel(date),
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (dayIncome > 0)
                                Text(
                                  '+ ${CurrencyFormatter.format(dayIncome)}',
                                  style: TextStyle(
                                      color: context.colors.income,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              if (dayIncome > 0 && dayExpense > 0)
                                const SizedBox(width: 8),
                              if (dayExpense > 0)
                                Text(
                                  '- ${CurrencyFormatter.format(dayExpense)}',
                                  style: TextStyle(
                                      color: context.colors.expense,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ),
                        ...dayTxns.map((t) => _TransactionItem(
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
                                  builder: (_) =>
                                      AddEditTransactionScreen(existing: t),
                                  fullscreenDialog: true,
                                ),
                              ),
                              onDelete: () async {
                                final db = ref.read(databaseProvider);
                                await db
                                    .deleteTransactionWithBalanceUpdate(t);
                              },
                            )),
                      ],
                    );
                  },
                  childCount: dates.length,
                ),
              ),
            ),
          ],
        );
      },
    );

    final searchAction = IconButton(
      icon: const Icon(Icons.search),
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const SearchScreen(),
      )),
    );

    if (standalone) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transactions'),
          actions: [searchAction],
        ),
        body: body,
        floatingActionButton: BouncyTap(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const AddEditTransactionScreen(),
            fullscreenDialog: true,
          )),
          child: FloatingActionButton(
            onPressed: null,
            backgroundColor: context.colors.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ),
      );
    }

    return Scaffold(
      drawer: showBalance ? const MoreMenuDrawer() : null,
      appBar: AppBar(
        leading: showBalance
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        title: Text(showBalance ? 'Home' : 'Transactions'),
        actions: [searchAction],
      ),
      body: body,
      floatingActionButton: showBalance
          ? BouncyTap(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AddEditTransactionScreen(),
                fullscreenDialog: true,
              )),
              child: FloatingActionButton(
                onPressed: null,
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime month;
  final WidgetRef ref;
  const _MonthSelector({required this.month, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () {
            final m = ref.read(selectedMonthProvider);
            ref.read(selectedMonthProvider.notifier).state =
                DateTime(m.year, m.month - 1);
          },
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: month,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              initialDatePickerMode: DatePickerMode.year,
            );
            if (picked != null) {
              ref.read(selectedMonthProvider.notifier).state =
                  DateTime(picked.year, picked.month);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              DateFormat('MMMM yyyy').format(month),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          onPressed: () {
            final m = ref.read(selectedMonthProvider);
            ref.read(selectedMonthProvider.notifier).state =
                DateTime(m.year, m.month + 1);
          },
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  final List<MapEntry<DateTime, double>> weeklySpending;
  const _HomeHeader({
    required this.balance,
    required this.income,
    required this.expense,
    required this.weeklySpending,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.primary,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$_greeting 👋',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(balance),
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          const Text('Balance this month',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.arrow_downward,
                  label: 'Income',
                  value: income,
                  boxColor: context.colors.incomeSurface,
                  textColor: context.colors.income,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  icon: Icons.arrow_upward,
                  label: 'Expenses',
                  value: expense,
                  boxColor: context.colors.expenseSurface,
                  textColor: context.colors.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: context.colors.warningSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SPENDING THIS WEEK',
                    style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 130,
                  child: weeklySpending.isEmpty
                      ? const SizedBox.shrink()
                      : _WeeklyBarChart(data: weeklySpending),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color boxColor;
  final Color textColor;
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.boxColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: context.colors.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(value),
                  style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> data;
  const _WeeklyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    final today = DateTime.now();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal == 0 ? 100 : maxVal * 1.3,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => context.colors.surfaceVariant,
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              CurrencyFormatter.formatCompact(rod.toY),
              TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(
          show: true,
          border: Border(
              bottom: BorderSide(color: context.colors.border, width: 1)),
        ),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                final day = data[idx].key;
                final isToday = day.year == today.year &&
                    day.month == today.month &&
                    day.day == today.day;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('E').format(day).substring(0, 3),
                    style: TextStyle(
                      color: isToday
                          ? context.colors.primary
                          : context.colors.textSecondary,
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(data.length, (i) {
          final hasSpending = data[i].value > 0;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: hasSpending ? data[i].value : maxVal * 0.02,
                color: hasSpending
                    ? AppColors.categoryColors[
                        i % AppColors.categoryColors.length]
                    : context.colors.border,
                width: 18,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.format(value),
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final Account? account;
  final Account? toAccount;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _TransactionItem({
    required this.transaction,
    this.category,
    this.account,
    this.toAccount,
    this.onTap,
    this.onDelete,
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
    final amountText = isExpense
        ? '- ${CurrencyFormatter.format(transaction.amount)}'
        : isTransfer
            ? '⇄ ${CurrencyFormatter.format(transaction.amount)}'
            : '+ ${CurrencyFormatter.format(transaction.amount)}';

    final icon = isTransfer ? '🔄' : category?.icon ?? '📦';
    final title = isTransfer ? 'Transfer' : category?.name ?? 'Other';
    final subtitle = isTransfer && toAccount != null
        ? '${account?.name ?? ''} → ${toAccount!.name}'
        : account?.name ?? '';

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: context.colors.expense,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete transaction?'),
            content:
                const Text('This will also reverse the account balance.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Delete',
                      style: TextStyle(color: context.colors.expense))),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: GestureDetector(
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
                    child: Text(icon,
                        style: const TextStyle(fontSize: 22))),
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
                    Text(subtitle,
                        style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(amountText,
                      style: TextStyle(
                          color: amountColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatTime(transaction.date),
                    style: TextStyle(
                        color: context.colors.textHint, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
