import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';
import '../transactions/add_edit_transaction_screen.dart';

/// Lists every transaction in [category] within the Insights screen's
/// currently selected timeframe (week/month/year/custom).
class CategoryTransactionsScreen extends ConsumerWidget {
  final Category category;
  const CategoryTransactionsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeframe = ref.watch(insightsTimeframeProvider);
    final txnsAsync =
        ref.watch(insightsCategoryTransactionsProvider(category.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              timeframe.label,
              style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: txnsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (txns) {
                if (txns.isEmpty) {
                  return Center(
                    child: Text('No transactions in this period',
                        style: TextStyle(color: context.colors.textHint)),
                  );
                }
                final total =
                    txns.fold(0.0, (s, t) => s + t.amount);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.expenseSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total (${txns.length})',
                              style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            CurrencyFormatter.format(total),
                            style: TextStyle(
                                color: context.colors.expense,
                                fontWeight: FontWeight.w800,
                                fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    ...txns.map((t) => _TransactionRow(
                          transaction: t,
                          category: category,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      AddEditTransactionScreen(existing: t))),
                        )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final Category category;
  final VoidCallback onTap;
  const _TransactionRow({
    required this.transaction,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                child: Text(category.icon, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.note?.isNotEmpty == true
                        ? transaction.note!
                        : category.name,
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
              '- ${CurrencyFormatter.format(transaction.amount)}',
              style: TextStyle(
                  color: context.colors.expense,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
