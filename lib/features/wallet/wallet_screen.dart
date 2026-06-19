import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/trend_line_chart.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';
import '../accounts/accounts_screen.dart';
import 'account_detail_screen.dart';

final _netWorthRangeProvider = StateProvider<String>((ref) => '1M');

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final netWorthAsync = ref.watch(netWorthProvider);
    final range = ref.watch(_netWorthRangeProvider);
    final historyAsync = ref.watch(netWorthHistoryProvider(range));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const AccountsScreen(),
            )),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allAccounts) {
          final active = allAccounts.where((a) => !a.isArchived).toList();
          final archived = allAccounts.where((a) => a.isArchived).toList();

          final sections = <_WalletSectionData>[
            _WalletSectionData(
              type: 'cash',
              title: 'Cash',
              icon: '💵',
              accentColor: AppColors.categoryColors[1],
              accounts: active
                  .where((a) => a.type == 'cash' || a.type == 'bank' || a.type == 'ewallet')
                  .toList(),
            ),
            _WalletSectionData(
              type: 'receivable',
              title: 'Account Receivable',
              icon: '📥',
              accentColor: AppColors.categoryColors[4],
              accounts: active.where((a) => a.type == 'receivable').toList(),
            ),
            _WalletSectionData(
              type: 'payable',
              title: 'Account Payable',
              icon: '📤',
              accentColor: AppColors.categoryColors[2],
              accounts: active.where((a) => a.type == 'payable').toList(),
            ),
            _WalletSectionData(
              type: 'investment',
              title: 'Investment',
              icon: '📈',
              accentColor: AppColors.categoryColors[6],
              accounts: active.where((a) => a.type == 'investment').toList(),
            ),
            _WalletSectionData(
              type: 'card',
              title: 'Debit & Credit Card',
              icon: '💳',
              accentColor: AppColors.categoryColors[7],
              accounts: active.where((a) => a.type == 'card').toList(),
            ),
          ];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _NetWorthCard(
                netWorthAsync: netWorthAsync,
                historyAsync: historyAsync,
                range: range,
                onRangeChanged: (r) =>
                    ref.read(_netWorthRangeProvider.notifier).state = r,
              ),
              const SizedBox(height: 20),
              ...sections.map((s) => _WalletSection(
                    data: s,
                    onAccountTap: (a) => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => AccountDetailScreen(account: a)),
                    ),
                  )),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ArchivedSection(
                  accounts: archived,
                  onAccountTap: (a) => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => AccountDetailScreen(account: a)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _WalletSectionData {
  final String type;
  final String title;
  final String icon;
  final Color accentColor;
  final List<Account> accounts;
  _WalletSectionData(
      {required this.type,
      required this.title,
      required this.icon,
      required this.accentColor,
      required this.accounts});
}

// ── Net Worth Card ────────────────────────────────────────────────────────────

class _NetWorthCard extends StatelessWidget {
  final AsyncValue<double> netWorthAsync;
  final AsyncValue<List<MapEntry<DateTime, double>>> historyAsync;
  final String range;
  final ValueChanged<String> onRangeChanged;
  const _NetWorthCard({
    required this.netWorthAsync,
    required this.historyAsync,
    required this.range,
    required this.onRangeChanged,
  });

  static const _ranges = ['1M', '3M', '6M', '1Y', 'ALL'];

  @override
  Widget build(BuildContext context) {
    final netWorth = netWorthAsync.valueOrNull ?? 0.0;
    final history = historyAsync.valueOrNull ?? const [];
    final first = history.isNotEmpty ? history.first.value : netWorth;
    final delta = netWorth - first;
    final deltaPct = first != 0 ? (delta / first.abs()) * 100 : 0.0;
    final isUp = delta >= 0;
    final deltaColor = isUp ? context.colors.income : context.colors.expense;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Net Worth',
              style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(netWorth),
            style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          if (history.length > 1)
            Row(
              children: [
                Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                    color: deltaColor, size: 14),
                const SizedBox(width: 2),
                Text(
                  '${CurrencyFormatter.format(delta.abs())} (${deltaPct.abs().toStringAsFixed(1)}%)',
                  style: TextStyle(
                      color: deltaColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text(_rangeLabel(range),
                    style:
                        TextStyle(color: context.colors.textHint, fontSize: 12)),
              ],
            )
          else
            Text('Assets - Liabilities',
                style: TextStyle(color: context.colors.textHint, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: history.length > 1
                ? TrendLineChart(
                    data: history,
                    color: deltaColor,
                    bottomLabel: (d) => DateFormat('d/M').format(d),
                  )
                : Center(
                    child: Text('Not enough history yet',
                        style: TextStyle(
                            color: context.colors.textHint, fontSize: 12)),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _ranges
                .map((r) => _RangeTab(
                      label: r,
                      selected: r == range,
                      onTap: () => onRangeChanged(r),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  String _rangeLabel(String r) {
    switch (r) {
      case '1M':
        return '1 month';
      case '3M':
        return '3 months';
      case '6M':
        return '6 months';
      case '1Y':
        return '1 year';
      default:
        return 'all time';
    }
  }
}

class _RangeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RangeTab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? context.colors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? context.colors.primary : context.colors.textHint,
          ),
        ),
      ),
    );
  }
}

// ── Wallet Section ────────────────────────────────────────────────────────────

class _WalletSection extends StatelessWidget {
  final _WalletSectionData data;
  final ValueChanged<Account> onAccountTap;
  const _WalletSection({required this.data, required this.onAccountTap});

  @override
  Widget build(BuildContext context) {
    if (data.accounts.isEmpty) return const SizedBox.shrink();

    final total = data.accounts.fold(0.0, (s, a) => s + a.balance);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: data.accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Text(data.icon,
                          style: const TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 10),
                Text(data.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text(
                  CurrencyFormatter.format(total),
                  style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...data.accounts.map((a) => _AccountTile(
                  account: a,
                  onTap: () => onAccountTap(a),
                )),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;
  const _AccountTile({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.categoryColors[
                    account.colorIndex % AppColors.categoryColors.length],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(account.icon,
                      style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(account.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            Text(
              CurrencyFormatter.format(account.balance),
              style: TextStyle(
                color: account.balance >= 0
                    ? context.colors.textPrimary
                    : context.colors.expense,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Icon(Icons.chevron_right, color: context.colors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Archived Section ──────────────────────────────────────────────────────────

class _ArchivedSection extends StatelessWidget {
  final List<Account> accounts;
  final ValueChanged<Account> onAccountTap;
  const _ArchivedSection(
      {required this.accounts, required this.onAccountTap});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('Archived',
          style: TextStyle(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 14)),
      children: accounts
          .map((a) => Opacity(
                opacity: 0.6,
                child: _AccountTile(
                    account: a, onTap: () => onAccountTap(a)),
              ))
          .toList(),
    );
  }
}
