import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';
import '../transactions/add_edit_transaction_screen.dart';

class AccountDetailScreen extends ConsumerWidget {
  final Account account;
  const AccountDetailScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(transactionsForAccountProvider(account.id));
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final catMap = {
      for (final c in categoriesAsync.valueOrNull ?? <Category>[]) c.id: c
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          if (account.balance == 0 && !account.isArchived)
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Archive',
              onPressed: () => _confirmArchive(context, ref, true),
            ),
          if (account.isArchived)
            IconButton(
              icon: const Icon(Icons.unarchive_outlined),
              tooltip: 'Unarchive',
              onPressed: () => _confirmArchive(context, ref, false),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const AddEditTransactionScreen(),
          fullscreenDialog: true,
        )),
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: txnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txns) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _BalanceHeader(account: account),
              const SizedBox(height: 20),
              if (txns.isNotEmpty) ...[
                Text('Money Flow', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _MoneyFlowChart(
                  transactions: txns,
                  accountId: account.id,
                  color: AppColors.categoryColors[
                      account.colorIndex % AppColors.categoryColors.length],
                ),
                const SizedBox(height: 24),
              ],
              Text('Transactions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (txns.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('No transactions yet',
                        style: TextStyle(color: context.colors.textHint)),
                  ),
                )
              else
                ...txns.map((t) => _TxnTile(
                      transaction: t,
                      category:
                          t.categoryId != null ? catMap[t.categoryId] : null,
                      accountId: account.id,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddEditTransactionScreen(existing: t),
                          fullscreenDialog: true,
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmArchive(
      BuildContext context, WidgetRef ref, bool archive) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(archive ? 'Archive account?' : 'Unarchive account?'),
        content: Text(archive
            ? 'This account has a zero balance. Move it to the archived section?'
            : 'Restore this account to the active wallet sections?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(archive ? 'Archive' : 'Unarchive'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(databaseProvider).archiveAccount(account.id, archived: archive);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

// ── Balance Header ────────────────────────────────────────────────────────────

class _BalanceHeader extends StatelessWidget {
  final Account account;
  const _BalanceHeader({required this.account});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[
        account.colorIndex % AppColors.categoryColors.length];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(account.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(account.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              if (account.isArchived) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Archived',
                      style: TextStyle(color: context.colors.textPrimary, fontSize: 10)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.format(account.balance),
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Money Flow Chart ──────────────────────────────────────────────────────────

class _MoneyFlowChart extends StatefulWidget {
  final List<Transaction> transactions;
  final int accountId;
  final Color color;
  const _MoneyFlowChart(
      {required this.transactions,
      required this.accountId,
      required this.color});

  @override
  State<_MoneyFlowChart> createState() => _MoneyFlowChartState();
}

class _MoneyFlowChartState extends State<_MoneyFlowChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.transactions]
      ..sort((a, b) => a.date.compareTo(b.date));
    double running = 0;
    final spots = <FlSpot>[];
    final dates = <DateTime>[];
    for (int i = 0; i < sorted.length; i++) {
      final t = sorted[i];
      final isOutgoing = t.accountId == widget.accountId &&
          (t.type == 'expense' || t.type == 'transfer');
      final isIncoming = t.type == 'income' ||
          (t.type == 'transfer' && t.toAccountId == widget.accountId);
      if (isOutgoing) {
        running -= t.amount;
      } else if (isIncoming) {
        running += t.amount;
      }
      spots.add(FlSpot(i.toDouble(), running));
      dates.add(t.date);
    }

    final color = AppColors.progressFillFor(widget.color);
    final labelInterval = (dates.length / 5).ceil().clamp(1, 1000).toDouble();
    final defaultIndex = spots.length - 1;
    final activeIndex = _touchedIndex ?? defaultIndex;

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: labelInterval,
                getTitlesWidget: (value, _) {
                  final idx = value.round();
                  if (idx < 0 || idx >= dates.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    DateFormatter.formatShortDate(dates[idx]),
                    style: TextStyle(
                        color: context.colors.textHint, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          showingTooltipIndicators: [
            ShowingTooltipIndicators([
              LineBarSpot(
                LineChartBarData(spots: spots),
                0,
                spots[activeIndex],
              ),
            ]),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchSpotThreshold: 40,
            handleBuiltInTouches: false,
            touchCallback: (event, response) {
              final spot = response?.lineBarSpots?.firstOrNull;
              if (spot == null) return;
              if (event is FlTapUpEvent ||
                  event is FlPanEndEvent ||
                  event is FlLongPressEnd) {
                setState(() => _touchedIndex = spot.x.toInt());
              } else if (event is FlPanUpdateEvent ||
                  event is FlPointerHoverEvent ||
                  event is FlTapDownEvent ||
                  event is FlLongPressMoveUpdate) {
                setState(() => _touchedIndex = spot.x.toInt());
              }
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => color,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              tooltipMargin: 12,
              getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                final idx = s.x.toInt();
                final date = idx >= 0 && idx < dates.length ? dates[idx] : null;
                return LineTooltipItem(
                  CurrencyFormatter.formatCompact(s.y),
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                  children: date != null
                      ? [
                          TextSpan(
                            text: '\n${DateFormatter.formatDate(date)}',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w500),
                          ),
                        ]
                      : null,
                );
              }).toList(),
            ),
            getTouchedSpotIndicator: (barData, indicators) {
              return indicators.map((i) {
                return TouchedSpotIndicatorData(
                  FlLine(color: color, strokeWidth: 1.5),
                  FlDotData(
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 5,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: color,
                    ),
                  ),
                );
              }).toList();
            },
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: color,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: color,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: context.colors.surfaceVariant,
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

// ── Transaction Tile ──────────────────────────────────────────────────────────

class _TxnTile extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final int accountId;
  final VoidCallback onTap;

  const _TxnTile({
    required this.transaction,
    this.category,
    required this.accountId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTransfer = transaction.type == 'transfer';
    final isOutgoing = transaction.accountId == accountId &&
        (transaction.type == 'expense' || isTransfer);
    final amountColor = isOutgoing ? context.colors.expense : context.colors.income;
    final prefix = isOutgoing ? '- ' : '+ ';

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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(isTransfer ? '🔄' : category?.icon ?? '📦',
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTransfer ? 'Transfer' : category?.name ?? 'Other',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    DateFormatter.formatShortDate(transaction.date),
                    style: TextStyle(color: context.colors.textHint, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '$prefix${CurrencyFormatter.format(transaction.amount)}',
              style: TextStyle(
                  color: amountColor, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
