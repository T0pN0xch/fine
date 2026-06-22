import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/trend_line_chart.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';
import 'category_transactions_screen.dart';
import 'member_transactions_screen.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeframe = ref.watch(insightsTimeframeProvider);
    final viewMode = ref.watch(insightsViewModeProvider);
    final spendingAsync = ref.watch(insightsCategorySpendingProvider);
    final overviewBucketsAsync = ref.watch(insightsOverviewBucketsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final incomeAsync = ref.watch(insightsIncomeProvider);
    final expenseAsync = ref.watch(insightsExpenseProvider);
    final dailySpendingAsync = ref.watch(insightsDailySpendingProvider);
    final memberSpendingAsync = ref.watch(insightsMemberSpendingProvider);
    final membersAsync = ref.watch(membersProvider);

    final categories = {
      for (final c in categoriesAsync.valueOrNull ?? <Category>[]) c.id: c
    };
    final members = {
      for (final m in membersAsync.valueOrNull ?? <Member>[]) m.id: m
    };

    final filterBar = _TimeframeFilterBar(
      timeframe: timeframe,
      viewMode: viewMode,
      onViewModeChanged: (mode) =>
          ref.read(insightsViewModeProvider.notifier).state = mode,
      onTypeChanged: (type) {
        if (type == InsightsTimeframeType.custom) return;
        ref.read(insightsTimeframeProvider.notifier).state =
            InsightsTimeframe(type: type, anchor: DateTime.now());
      },
      onPickCustomRange: () async {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 1),
          initialDateRange:
              DateTimeRange(start: timeframe.start, end: timeframe.end),
        );
        if (picked != null) {
          ref.read(insightsTimeframeProvider.notifier).state =
              InsightsTimeframe(
            type: InsightsTimeframeType.custom,
            anchor: picked.start,
            customStart: picked.start,
            customEnd: DateTime(picked.end.year, picked.end.month,
                picked.end.day, 23, 59, 59),
          );
        }
      },
      onPrev: () => ref.read(insightsTimeframeProvider.notifier).state =
          timeframe.shift(-1),
      onNext: () => ref.read(insightsTimeframeProvider.notifier).state =
          timeframe.shift(1),
    );

    if (viewMode != InsightsViewMode.summary) {
      return Scaffold(
        appBar: AppBar(title: const Text('Insights'), elevation: 0),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            filterBar,
            const SizedBox(height: 16),
            _YearSelector(
              year: ref.watch(insightsTrendYearProvider),
              onPrev: () => ref.read(insightsTrendYearProvider.notifier).state--,
              onNext: () => ref.read(insightsTrendYearProvider.notifier).state++,
            ),
            const SizedBox(height: 16),
            if (viewMode == InsightsViewMode.netWorthTrend)
              const _NetWorthTrendSection()
            else
              const _IncomeExpenseTableSection(),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          filterBar,
          const SizedBox(height: 16),

          _SummaryRow(
            income: incomeAsync.valueOrNull ?? 0,
            expense: expenseAsync.valueOrNull ?? 0,
          ),
          const SizedBox(height: 20),

          _SectionTitle('Spending Trend'),
          const SizedBox(height: 12),
          dailySpendingAsync.when(
            loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (daily) {
              final total = daily.fold(0.0, (s, e) => s + e.value);
              if (total == 0) {
                return const _EmptyChart(
                    message: 'No spending recorded in this period');
              }
              return Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Spendings',
                        style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(total),
                      style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: TrendLineChart(
                        data: daily,
                        color: context.colors.expense,
                        bottomLabel: (d) => DateFormat('d').format(d),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          _SectionTitle(_overviewTitle(timeframe.type)),
          const SizedBox(height: 12),
          overviewBucketsAsync.when(
            loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (buckets) => _OverviewBarChart(
                buckets: buckets, timeframeType: timeframe.type),
          ),
          const SizedBox(height: 24),

          _SectionTitle('Spending by Category'),
          const SizedBox(height: 12),
          spendingAsync.when(
            loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (spending) {
              if (spending.isEmpty) {
                return const _EmptyChart(
                    message: 'No expenses recorded in this period');
              }
              final entries = spending.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final total =
                  entries.fold(0.0, (s, e) => s + e.value);

              return Column(
                children: [
                  _ExpensePieChart(
                      entries: entries, categories: categories),
                  const SizedBox(height: 16),
                  ...entries.map((e) => _CategoryRow(
                        category: categories[e.key],
                        amount: e.value,
                        total: total,
                      )),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          _SectionTitle('Spending by Person'),
          const SizedBox(height: 12),
          memberSpendingAsync.when(
            loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (spending) {
              if (spending.isEmpty) {
                return const _EmptyChart(
                    message: 'No expenses tagged to a person yet');
              }
              final entries = spending.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final total = entries.fold(0.0, (s, e) => s + e.value);

              return Column(
                children: entries.map((e) {
                  final member = members[e.key];
                  if (member == null) return const SizedBox.shrink();
                  return _MemberRow(
                    member: member,
                    amount: e.value,
                    total: total,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _overviewTitle(InsightsTimeframeType type) {
    switch (type) {
      case InsightsTimeframeType.week:
        return 'Daily Overview';
      case InsightsTimeframeType.month:
        return 'Weekly Overview';
      case InsightsTimeframeType.year:
        return 'Monthly Overview';
      case InsightsTimeframeType.custom:
        return 'Overview';
    }
  }
}

// ── Year Selector (Trend / Income-Expense views) ───────────────────────────────

class _YearSelector extends StatelessWidget {
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _YearSelector(
      {required this.year, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: context.colors.textPrimary),
          onPressed: onPrev,
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: Text(
            '$year',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: context.colors.textPrimary),
          onPressed: onNext,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

// ── Net Worth Trend (month-by-month) ────────────────────────────────────────────

class _NetWorthTrendSection extends ConsumerWidget {
  const _NetWorthTrendSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final netWorthAsync = ref.watch(yearlyNetWorthTrendProvider);
    final incomeExpenseAsync = ref.watch(yearlyIncomeExpenseProvider);

    return netWorthAsync.when(
      loading: () => const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const _EmptyChart(message: 'No data available'),
      data: (netWorth) {
        final monthlyDeltas = incomeExpenseAsync.valueOrNull;
        final total = netWorth.isEmpty ? 0.0 : netWorth.last.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Net Worth'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(CurrencyFormatter.format(total),
                      style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: TrendLineChart(
                      data: netWorth,
                      color: context.colors.income,
                      bottomLabel: (d) => DateFormat('MMM').format(d),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle('Monthly Breakdown'),
            const SizedBox(height: 12),
            _BreakdownTable(
              headers: const ['Month', 'Income/Expense', 'Balance'],
              totalLabel: 'Total',
              totalValues: [
                monthlyDeltas == null
                    ? ''
                    : CurrencyFormatter.formatCompact(monthlyDeltas.fold(
                        0.0,
                        (s, m) =>
                            s + (m['income'] as double) - (m['expense'] as double))),
                CurrencyFormatter.format(total),
              ],
              rows: [
                for (int i = netWorth.length - 1; i >= 0; i--)
                  _BreakdownRowData(
                    label: DateFormat('MMM').format(netWorth[i].key),
                    values: [
                      monthlyDeltas != null && i < monthlyDeltas.length
                          ? CurrencyFormatter.formatCompact(
                              (monthlyDeltas[i]['income'] as double) -
                                  (monthlyDeltas[i]['expense'] as double))
                          : '',
                      CurrencyFormatter.format(netWorth[i].value),
                    ],
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ── Income/Expense Table (month-by-month) ───────────────────────────────────────

class _IncomeExpenseTableSection extends ConsumerWidget {
  const _IncomeExpenseTableSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(yearlyIncomeExpenseProvider);

    return monthlyAsync.when(
      loading: () => const SizedBox(
          height: 200, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const _EmptyChart(message: 'No data available'),
      data: (months) {
        if (months.isEmpty || months.every((m) =>
            (m['income'] as double) == 0 && (m['expense'] as double) == 0)) {
          return const _EmptyChart(message: 'No transactions recorded this year');
        }

        final totalIncome =
            months.fold(0.0, (s, m) => s + (m['income'] as double));
        final totalExpense =
            months.fold(0.0, (s, m) => s + (m['expense'] as double));

        final incomeSpots = <FlSpot>[];
        final expenseSpots = <FlSpot>[];
        for (int i = 0; i < months.length; i++) {
          incomeSpots.add(FlSpot(i.toDouble(), months[i]['income'] as double));
          expenseSpots.add(FlSpot(i.toDouble(), months[i]['expense'] as double));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Income vs Expenses'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _LegendDot(color: context.colors.income, label: 'Income'),
                      const SizedBox(width: 16),
                      _LegendDot(color: context.colors.expense, label: 'Expenses'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 20,
                              interval: 2,
                              getTitlesWidget: (value, _) {
                                final idx = value.round();
                                if (idx < 0 || idx >= months.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  DateFormat('MMM').format(DateTime(
                                      months[idx]['year'] as int,
                                      months[idx]['month'] as int)),
                                  style: TextStyle(
                                      color: context.colors.textHint,
                                      fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: incomeSpots,
                            isCurved: true,
                            color: context.colors.income,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                          ),
                          LineChartBarData(
                            spots: expenseSpots,
                            isCurved: true,
                            color: context.colors.expense,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle('Monthly Breakdown'),
            const SizedBox(height: 12),
            _BreakdownTable(
              headers: const ['Month', 'Income', 'Expenses', 'Total'],
              totalLabel: 'Total',
              valueColors: [
                context.colors.income,
                context.colors.expense,
                null,
              ],
              totalValues: [
                CurrencyFormatter.formatCompact(totalIncome),
                CurrencyFormatter.formatCompact(totalExpense),
                CurrencyFormatter.format(totalIncome - totalExpense),
              ],
              rows: [
                for (int i = months.length - 1; i >= 0; i--)
                  if ((months[i]['income'] as double) != 0 ||
                      (months[i]['expense'] as double) != 0)
                    _BreakdownRowData(
                      label: DateFormat('MMM').format(DateTime(
                          months[i]['year'] as int, months[i]['month'] as int)),
                      values: [
                        CurrencyFormatter.formatCompact(months[i]['income'] as double),
                        CurrencyFormatter.formatCompact(months[i]['expense'] as double),
                        CurrencyFormatter.format(
                            (months[i]['income'] as double) -
                                (months[i]['expense'] as double)),
                      ],
                    ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

// ── Shared Breakdown Table ──────────────────────────────────────────────────────

class _BreakdownRowData {
  final String label;
  final List<String> values;
  const _BreakdownRowData({required this.label, required this.values});
}

class _BreakdownTable extends StatelessWidget {
  final List<String> headers;
  final String totalLabel;
  final List<String> totalValues;
  final List<_BreakdownRowData> rows;
  final List<Color?>? valueColors;
  const _BreakdownTable({
    required this.headers,
    required this.totalLabel,
    required this.totalValues,
    required this.rows,
    this.valueColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                    child: Text(headers.first,
                        style: TextStyle(
                            color: context.colors.textHint,
                            fontSize: 11,
                            fontWeight: FontWeight.w700))),
                ...headers.skip(1).map((h) => Expanded(
                      child: Text(h,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: context.colors.textHint,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    )),
              ],
            ),
          ),
          Divider(height: 1, color: context.colors.border),
          _BreakdownRow(
              label: totalLabel,
              values: totalValues,
              valueColors: valueColors,
              bold: true),
          for (final r in rows)
            _BreakdownRow(
                label: r.label, values: r.values, valueColors: valueColors),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final List<String> values;
  final List<Color?>? valueColors;
  final bool bold;
  const _BreakdownRow(
      {required this.label,
      required this.values,
      this.valueColors,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 13,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w600))),
          ...values.asMap().entries.map((entry) => Expanded(
                child: Text(entry.value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: valueColors != null &&
                                entry.key < valueColors!.length &&
                                valueColors![entry.key] != null
                            ? valueColors![entry.key]
                            : context.colors.textPrimary,
                        fontSize: 13,
                        fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
              )),
        ],
      ),
    );
  }
}

// ── Summary Row ───────────────────────────────────────────────────────────────

// ── Timeframe Filter Bar ──────────────────────────────────────────────────────

class _TimeframeFilterBar extends StatelessWidget {
  final InsightsTimeframe timeframe;
  final ValueChanged<InsightsTimeframeType> onTypeChanged;
  final VoidCallback onPickCustomRange;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final InsightsViewMode viewMode;
  final ValueChanged<InsightsViewMode> onViewModeChanged;
  const _TimeframeFilterBar({
    required this.timeframe,
    required this.onTypeChanged,
    required this.onPickCustomRange,
    required this.onPrev,
    required this.onNext,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  static const _chips = [
    (InsightsTimeframeType.week, 'Weekly'),
    (InsightsTimeframeType.month, 'Monthly'),
    (InsightsTimeframeType.year, 'Yearly'),
    (InsightsTimeframeType.custom, 'Custom'),
  ];

  static const _modeChips = [
    (InsightsViewMode.netWorthTrend, 'Trend'),
    (InsightsViewMode.incomeExpenseTable, 'Income/Expense'),
  ];

  @override
  Widget build(BuildContext context) {
    final isSummary = viewMode == InsightsViewMode.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._chips.map((c) {
                final selected = isSummary && c.$1 == timeframe.type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      onViewModeChanged(InsightsViewMode.summary);
                      if (c.$1 == InsightsTimeframeType.custom) {
                        onPickCustomRange();
                      } else {
                        onTypeChanged(c.$1);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? context.colors.primary
                            : context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        c.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 1,
                height: 24,
                color: context.colors.border,
              ),
              const SizedBox(width: 4),
              ..._modeChips.map((c) {
                final selected = c.$1 == viewMode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onViewModeChanged(c.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? context.colors.income
                            : context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        c.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!isSummary)
          const SizedBox.shrink()
        else if (timeframe.type != InsightsTimeframeType.custom)
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: context.colors.textPrimary),
                onPressed: onPrev,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  timeframe.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: context.colors.textPrimary),
                onPressed: onNext,
                visualDensity: VisualDensity.compact,
              ),
            ],
          )
        else
          GestureDetector(
            onTap: onPickCustomRange,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.date_range, size: 16, color: context.colors.textPrimary),
                const SizedBox(width: 6),
                Text(
                  timeframe.label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double income;
  final double expense;
  const _SummaryRow({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Income',
            value: income,
            boxColor: context.colors.incomeSurface,
            textColor: context.colors.income,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: 'Expenses',
            value: expense,
            boxColor: context.colors.expenseSurface,
            textColor: context.colors.expense,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            label: 'Balance',
            value: balance,
            boxColor: context.colors.warningSurface,
            textColor: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final double value;
  final Color boxColor;
  final Color textColor;
  const _StatBox({
    required this.label,
    required this.value,
    required this.boxColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.formatCompact(value.abs()),
            style: TextStyle(
                color: textColor, fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ── Overview Bar Chart ────────────────────────────────────────────────────────

class _OverviewBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> buckets;
  final InsightsTimeframeType timeframeType;
  const _OverviewBarChart({required this.buckets, required this.timeframeType});

  @override
  Widget build(BuildContext context) {
    final maxVal = buckets.fold<double>(0, (m, t) {
      final inc = (t['income'] as double?) ?? 0;
      final exp = (t['expense'] as double?) ?? 0;
      return m > inc
          ? (m > exp ? m : exp)
          : (inc > exp ? inc : exp);
    });

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2 == 0 ? 100 : maxVal * 1.2,
          barTouchData: BarTouchData(enabled: false),
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
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= buckets.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    _bucketLabel(buckets[idx]),
                    style: TextStyle(
                        fontSize: 10, color: context.colors.textSecondary),
                  );
                },
                reservedSize: 20,
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: context.colors.border,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(buckets.length, (i) {
            final income = (buckets[i]['income'] as double?) ?? 0;
            final expense = (buckets[i]['expense'] as double?) ?? 0;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: income,
                  color: context.colors.income,
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: expense,
                  color: context.colors.expense,
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              barsSpace: 4,
            );
          }),
        ),
      ),
    );
  }

  String _bucketLabel(Map<String, dynamic> bucket) {
    switch (timeframeType) {
      case InsightsTimeframeType.week:
        final date = bucket['date'] as DateTime;
        return DateFormat('E').format(date);
      case InsightsTimeframeType.month:
        final date = bucket['date'] as DateTime;
        return DateFormat('d MMM').format(date);
      case InsightsTimeframeType.year:
        return _monthAbbr(bucket['month'] as int);
      case InsightsTimeframeType.custom:
        final date = bucket['date'] as DateTime?;
        if (date != null) return DateFormat('d/M').format(date);
        return _monthAbbr(bucket['month'] as int);
    }
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}

// ── Expense Pie Chart ─────────────────────────────────────────────────────────

class _ExpensePieChart extends StatefulWidget {
  final List<MapEntry<int, double>> entries;
  final Map<int, Category> categories;
  const _ExpensePieChart(
      {required this.entries, required this.categories});

  @override
  State<_ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<_ExpensePieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final total = widget.entries.fold(0.0, (s, e) => s + e.value);

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: List.generate(widget.entries.length, (i) {
                  final e = widget.entries[i];
                  final cat = widget.categories[e.key];
                  final color = AppColors.vividColors[
                      (cat?.colorIndex ?? i) % AppColors.vividColors.length];
                  final isTouched = i == _touchedIndex;
                  return PieChartSectionData(
                    value: e.value,
                    color: color,
                    radius: isTouched ? 90 : 75,
                    title: isTouched
                        ? '${(e.value / total * 100).toStringAsFixed(1)}%'
                        : '',
                    titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  );
                }),
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      setState(() => _touchedIndex = null);
                      return;
                    }
                    setState(() => _touchedIndex =
                        response.touchedSection!.touchedSectionIndex);
                  },
                ),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          // Legend
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.entries.take(5).map((e) {
              final cat = widget.categories[e.key];
              final color = AppColors.vividColors[
                  (cat?.colorIndex ?? 0) % AppColors.vividColors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      cat?.name ?? 'Other',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Category Row ──────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final Category? category;
  final double amount;
  final double total;
  const _CategoryRow(
      {this.category, required this.amount, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? amount / total : 0.0;
    final color = AppColors.categoryColors[
        (category?.colorIndex ?? 0) % AppColors.categoryColors.length];
    final cat = category;

    return GestureDetector(
      onTap: cat == null
          ? null
          : () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CategoryTransactionsScreen(category: cat))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Text(category?.icon ?? '📦',
                          style: const TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(category?.name ?? 'Other',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                Text(
                  CurrencyFormatter.format(amount),
                  style: TextStyle(
                      color: context.colors.expense,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: context.colors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member Row ────────────────────────────────────────────────────────────────

class _MemberRow extends StatelessWidget {
  final Member member;
  final double amount;
  final double total;
  const _MemberRow(
      {required this.member, required this.amount, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? amount / total : 0.0;
    final color =
        AppColors.categoryColors[member.id % AppColors.categoryColors.length];

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MemberTransactionsScreen(member: member))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Text(member.icon,
                          style: const TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(member.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                Text(
                  CurrencyFormatter.format(amount),
                  style: TextStyle(
                      color: context.colors.expense,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: context.colors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                size: 40, color: context.colors.textHint),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(
                    color: context.colors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
