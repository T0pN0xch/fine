import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/database/app_database.dart';

// ── Database ──────────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── App state ─────────────────────────────────────────────────────────────────

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// ── Accounts ──────────────────────────────────────────────────────────────────

final accountsProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(databaseProvider).watchAllAccounts();
});

final totalBalanceProvider = FutureProvider<double>((ref) async {
  ref.watch(accountsProvider);
  return ref.read(databaseProvider).getTotalBalance();
});

final netWorthProvider = FutureProvider<double>((ref) async {
  ref.watch(accountsProvider);
  return ref.read(databaseProvider).getNetWorth();
});

final netWorthBreakdownProvider =
    FutureProvider<Map<String, double>>((ref) async {
  ref.watch(accountsProvider);
  return ref.read(databaseProvider).getNetWorthBreakdown();
});

/// Historical net worth, keyed by lookback range label ('1M','3M','6M','1Y','ALL').
final netWorthHistoryProvider =
    FutureProvider.family<List<MapEntry<DateTime, double>>, String>(
        (ref, range) async {
  ref.watch(accountsProvider);
  final now = DateTime.now();
  final from = switch (range) {
    '1M' => DateTime(now.year, now.month - 1, now.day),
    '3M' => DateTime(now.year, now.month - 3, now.day),
    '6M' => DateTime(now.year, now.month - 6, now.day),
    '1Y' => DateTime(now.year - 1, now.month, now.day),
    _ => DateTime(2000),
  };
  return ref.read(databaseProvider).getNetWorthHistory(from);
});

final transactionsForAccountProvider =
    StreamProvider.family<List<Transaction>, int>((ref, accountId) {
  return ref.watch(databaseProvider).watchTransactionsForAccount(accountId);
});

// ── Categories ────────────────────────────────────────────────────────────────

final allCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(databaseProvider).watchAllCategories();
});

final expenseCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(databaseProvider).watchCategoriesByType('expense');
});

final incomeCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(databaseProvider).watchCategoriesByType('income');
});

// ── Transactions ──────────────────────────────────────────────────────────────

final monthlyTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);
  return db.watchTransactionsByMonth(month.year, month.month);
});

/// Unfiltered transactions stream — every transaction ever recorded, newest
/// first. Used both as the data source for the Home tab's full history list
/// and as a change-invalidation signal for FutureProviders whose range can
/// span beyond one month.
final allTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(databaseProvider).watchAllTransactions();
});

final monthlyIncomeProvider = FutureProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);
  ref.watch(monthlyTransactionsProvider);
  return db.getTotalByTypeAndMonth('income', month.year, month.month);
});

final monthlyExpenseProvider = FutureProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);
  ref.watch(monthlyTransactionsProvider);
  return db.getTotalByTypeAndMonth('expense', month.year, month.month);
});

// ── Bills ─────────────────────────────────────────────────────────────────────

final activeBillsProvider = StreamProvider<List<Bill>>((ref) {
  return ref.watch(databaseProvider).watchActiveBills();
});

// ── Budgets ───────────────────────────────────────────────────────────────────

final budgetsProvider = StreamProvider<List<BudgetLimit>>((ref) {
  final db = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);
  return db.watchBudgetsByMonth(month.year, month.month);
});

// ── Goals ─────────────────────────────────────────────────────────────────────

final allGoalsProvider = StreamProvider<List<Goal>>((ref) {
  return ref.watch(databaseProvider).watchAllGoals(includeArchived: true);
});

final goalTopUpsProvider =
    StreamProvider.family<List<GoalTopUp>, int>((ref, goalId) {
  return ref.watch(databaseProvider).watchTopUpsForGoal(goalId);
});

// ── Reports / Insights ────────────────────────────────────────────────────────

final categorySpendingProvider = FutureProvider<Map<int, double>>((ref) {
  final db = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);
  ref.watch(allTransactionsProvider);
  return db.getCategorySpending(month.year, month.month);
});

final weeklySpendingProvider =
    FutureProvider<List<MapEntry<DateTime, double>>>((ref) {
  ref.watch(monthlyTransactionsProvider);
  return ref.watch(databaseProvider).getWeeklySpending();
});

final dailySpendingForMonthProvider =
    FutureProvider<List<MapEntry<DateTime, double>>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  ref.watch(monthlyTransactionsProvider);
  return ref
      .watch(databaseProvider)
      .getDailySpendingForMonth(month.year, month.month);
});

/// Insights screen timeframe filter: week / month / year / a custom date range.
enum InsightsTimeframeType { week, month, year, custom }

class InsightsTimeframe {
  final InsightsTimeframeType type;
  final DateTime anchor;
  final DateTime? customStart;
  final DateTime? customEnd;

  const InsightsTimeframe({
    required this.type,
    required this.anchor,
    this.customStart,
    this.customEnd,
  });

  factory InsightsTimeframe.initial() =>
      InsightsTimeframe(type: InsightsTimeframeType.month, anchor: DateTime.now());

  DateTime get start {
    switch (type) {
      case InsightsTimeframeType.week:
        final today = DateTime(anchor.year, anchor.month, anchor.day);
        return today.subtract(Duration(days: today.weekday - 1));
      case InsightsTimeframeType.month:
        return DateTime(anchor.year, anchor.month, 1);
      case InsightsTimeframeType.year:
        return DateTime(anchor.year, 1, 1);
      case InsightsTimeframeType.custom:
        return customStart ?? anchor;
    }
  }

  DateTime get end {
    switch (type) {
      case InsightsTimeframeType.week:
        return start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      case InsightsTimeframeType.month:
        final daysInMonth = DateTime(anchor.year, anchor.month + 1, 0).day;
        return DateTime(anchor.year, anchor.month, daysInMonth, 23, 59, 59);
      case InsightsTimeframeType.year:
        return DateTime(anchor.year, 12, 31, 23, 59, 59);
      case InsightsTimeframeType.custom:
        return customEnd ?? anchor;
    }
  }

  String get label {
    switch (type) {
      case InsightsTimeframeType.week:
        return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)}';
      case InsightsTimeframeType.month:
        return DateFormat('MMMM yyyy').format(anchor);
      case InsightsTimeframeType.year:
        return DateFormat('yyyy').format(anchor);
      case InsightsTimeframeType.custom:
        return '${DateFormat('d MMM yyyy').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
    }
  }

  InsightsTimeframe shift(int amount) {
    switch (type) {
      case InsightsTimeframeType.week:
        return InsightsTimeframe(
            type: type, anchor: anchor.add(Duration(days: 7 * amount)));
      case InsightsTimeframeType.month:
        return InsightsTimeframe(
            type: type, anchor: DateTime(anchor.year, anchor.month + amount, 1));
      case InsightsTimeframeType.year:
        return InsightsTimeframe(
            type: type, anchor: DateTime(anchor.year + amount, anchor.month, 1));
      case InsightsTimeframeType.custom:
        return this;
    }
  }
}

final insightsTimeframeProvider =
    StateProvider<InsightsTimeframe>((ref) => InsightsTimeframe.initial());

final insightsIncomeProvider = FutureProvider<double>((ref) {
  final tf = ref.watch(insightsTimeframeProvider);
  ref.watch(allTransactionsProvider);
  return ref.watch(databaseProvider).getTotalByTypeAndRange('income', tf.start, tf.end);
});

final insightsExpenseProvider = FutureProvider<double>((ref) {
  final tf = ref.watch(insightsTimeframeProvider);
  ref.watch(allTransactionsProvider);
  return ref.watch(databaseProvider).getTotalByTypeAndRange('expense', tf.start, tf.end);
});

final insightsCategorySpendingProvider = FutureProvider<Map<int, double>>((ref) {
  final tf = ref.watch(insightsTimeframeProvider);
  ref.watch(allTransactionsProvider);
  return ref.watch(databaseProvider).getCategorySpendingByRange(tf.start, tf.end);
});

/// Transactions for a single category within the current insights timeframe.
final insightsCategoryTransactionsProvider =
    FutureProvider.family<List<Transaction>, int>((ref, categoryId) {
  final tf = ref.watch(insightsTimeframeProvider);
  ref.watch(allTransactionsProvider);
  return ref
      .watch(databaseProvider)
      .getTransactionsByCategoryAndRange(categoryId, tf.start, tf.end);
});

/// Spending trend for the chart on the Insights summary view, bucketed at a
/// granularity matching the current timeframe so a Yearly view shows ~12
/// monthly points instead of 365 cramped daily ones.
final insightsDailySpendingProvider =
    FutureProvider<List<MapEntry<DateTime, double>>>((ref) async {
  final tf = ref.watch(insightsTimeframeProvider);
  final db = ref.watch(databaseProvider);
  ref.watch(allTransactionsProvider);

  switch (tf.type) {
    case InsightsTimeframeType.week:
      return db.getDailySpendingByRange(tf.start, tf.end);
    case InsightsTimeframeType.month:
      final weeks = await db.getIncomeExpenseByWeekRange(tf.start, tf.end);
      return [
        for (final w in weeks)
          MapEntry(w['date'] as DateTime, w['expense'] as double)
      ];
    case InsightsTimeframeType.year:
      final months = await db.getIncomeExpenseByMonthRange(tf.start, tf.end);
      return [
        for (final m in months)
          MapEntry(
              DateTime(m['year'] as int, m['month'] as int), m['expense'] as double)
      ];
    case InsightsTimeframeType.custom:
      final days = tf.end.difference(tf.start).inDays;
      if (days <= 31) return db.getDailySpendingByRange(tf.start, tf.end);
      if (days <= 120) {
        final weeks = await db.getIncomeExpenseByWeekRange(tf.start, tf.end);
        return [
          for (final w in weeks)
            MapEntry(w['date'] as DateTime, w['expense'] as double)
        ];
      }
      final months = await db.getIncomeExpenseByMonthRange(tf.start, tf.end);
      return [
        for (final m in months)
          MapEntry(
              DateTime(m['year'] as int, m['month'] as int), m['expense'] as double)
      ];
  }
});

/// Income/expense totals bucketed at a granularity matching the current
/// Insights timeframe: by day for "week", by week for "month", by month
/// for "year" (and for a custom range, sized to roughly fit ~6-8 buckets).
final insightsOverviewBucketsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final tf = ref.watch(insightsTimeframeProvider);
  final db = ref.watch(databaseProvider);
  ref.watch(allTransactionsProvider);
  switch (tf.type) {
    case InsightsTimeframeType.week:
      return db.getIncomeExpenseByDayRange(tf.start, tf.end);
    case InsightsTimeframeType.month:
      return db.getIncomeExpenseByWeekRange(tf.start, tf.end);
    case InsightsTimeframeType.year:
      return db.getIncomeExpenseByMonthRange(tf.start, tf.end);
    case InsightsTimeframeType.custom:
      final days = tf.end.difference(tf.start).inDays;
      if (days <= 31) return db.getIncomeExpenseByDayRange(tf.start, tf.end);
      if (days <= 120) return db.getIncomeExpenseByWeekRange(tf.start, tf.end);
      return db.getIncomeExpenseByMonthRange(tf.start, tf.end);
  }
});

/// Insights screen display mode: the default summary view, or one of the
/// two month-by-month comparison views (income/expense table, net worth
/// trend), both of which are anchored to a calendar year rather than the
/// Weekly/Monthly/Yearly/Custom timeframe.
enum InsightsViewMode { summary, incomeExpenseTable, netWorthTrend }

final insightsViewModeProvider =
    StateProvider<InsightsViewMode>((ref) => InsightsViewMode.summary);

final insightsTrendYearProvider =
    StateProvider<int>((ref) => DateTime.now().year);

/// Income/expense totals per month for the selected trend year.
final yearlyIncomeExpenseProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  final year = ref.watch(insightsTrendYearProvider);
  ref.watch(allTransactionsProvider);
  return ref
      .watch(databaseProvider)
      .getIncomeExpenseByMonthRange(DateTime(year, 1, 1), DateTime(year, 12, 1));
});

/// Net worth sampled at the end of each month for the selected trend year.
final yearlyNetWorthTrendProvider =
    FutureProvider<List<MapEntry<DateTime, double>>>((ref) {
  final year = ref.watch(insightsTrendYearProvider);
  ref.watch(allTransactionsProvider);
  ref.watch(accountsProvider);
  return ref
      .watch(databaseProvider)
      .getNetWorthByMonthRange(DateTime(year, 1, 1), DateTime(year, 12, 1));
});

// ── Future Plan & Commitment ─────────────────────────────────────────────────

final monthlyPlanProvider = StreamProvider<MonthlyPlan?>((ref) {
  final db = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);
  return db.watchMonthlyPlan(month.year, month.month);
});

final commitmentsForMonthProvider = StreamProvider<List<Commitment>>((ref) {
  final db = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);
  return db.watchCommitmentsForMonth(month.year, month.month);
});

final projectedRemainingProvider = FutureProvider<double>((ref) async {
  final plan = await ref.watch(monthlyPlanProvider.future);
  final commitmentsList = await ref.watch(commitmentsForMonthProvider.future);
  final db = ref.watch(databaseProvider);
  final month = ref.watch(selectedMonthProvider);
  final spent = await db.getTotalByTypeAndMonth('expense', month.year, month.month);
  final unpaidCommitments =
      commitmentsList.where((c) => !c.isPaid).fold(0.0, (s, c) => s + c.amount);
  final salary = plan?.expectedSalary ?? 0.0;
  return salary - unpaidCommitments - spent;
});

// ── Members (spend-by-person) ────────────────────────────────────────────────

final membersProvider = StreamProvider<List<Member>>((ref) {
  return ref.watch(databaseProvider).watchAllMembers();
});

/// Selected member filter on the Insights screen. Null means "all people".
final insightsMemberFilterProvider = StateProvider<int?>((ref) => null);

final insightsMemberSpendingProvider =
    FutureProvider<Map<int, double>>((ref) {
  final tf = ref.watch(insightsTimeframeProvider);
  return ref.watch(databaseProvider).getMemberSpendingByRange(tf.start, tf.end);
});

final insightsMemberTransactionsProvider =
    FutureProvider.family<List<Transaction>, int>((ref, memberId) {
  final tf = ref.watch(insightsTimeframeProvider);
  return ref
      .watch(databaseProvider)
      .getTransactionsByMemberAndRange(memberId, tf.start, tf.end);
});

// ── Tags ──────────────────────────────────────────────────────────────────────

final allTagsProvider = StreamProvider<List<Tag>>((ref) {
  return ref.watch(databaseProvider).watchAllTags();
});

// ── Search ────────────────────────────────────────────────────────────────────

class SearchFilters {
  final String query;
  final String? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;

  const SearchFilters({
    this.query = '',
    this.type,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
  });

  bool get isEmpty =>
      query.isEmpty &&
      type == null &&
      startDate == null &&
      endDate == null &&
      minAmount == null &&
      maxAmount == null;

  SearchFilters copyWith({
    String? query,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    bool clearType = false,
    bool clearDates = false,
    bool clearAmounts = false,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      type: clearType ? null : (type ?? this.type),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      minAmount: clearAmounts ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmounts ? null : (maxAmount ?? this.maxAmount),
    );
  }
}

final searchFiltersProvider = StateProvider<SearchFilters>((ref) {
  return const SearchFilters();
});

final searchResultsProvider = FutureProvider<List<Transaction>>((ref) async {
  final filters = ref.watch(searchFiltersProvider);
  if (filters.isEmpty) return [];
  final db = ref.watch(databaseProvider);
  return db.searchTransactions(
    query: filters.query,
    type: filters.type,
    startDate: filters.startDate,
    endDate: filters.endDate,
    minAmount: filters.minAmount,
    maxAmount: filters.maxAmount,
  );
});
