import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';
import 'add_edit_transaction_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final catMap = {
      for (final c in categoriesAsync.valueOrNull ?? <Category>[]) c.id: c
    };
    final accMap = {
      for (final a in accountsAsync.valueOrNull ?? <Account>[]) a.id: a
    };

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Search notes, amount, category...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            ref.read(searchFiltersProvider.notifier).state =
                filters.copyWith(query: value);
          },
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                ref.read(searchFiltersProvider.notifier).state =
                    filters.copyWith(query: '');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(filters: filters),
          Expanded(
            child: filters.isEmpty
                ? Center(
                    child: Text(
                      'Start typing or set filters to search',
                      style: TextStyle(color: context.colors.textHint),
                    ),
                  )
                : resultsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (results) {
                      if (results.isEmpty) {
                        return Center(
                          child: Text(
                            'No matching transactions',
                            style: TextStyle(color: context.colors.textHint),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: results.length,
                        itemBuilder: (context, i) {
                          final t = results[i];
                          final category =
                              t.categoryId != null ? catMap[t.categoryId] : null;
                          final account = accMap[t.accountId];
                          final isExpense = t.type == 'expense';
                          final isTransfer = t.type == 'transfer';
                          final amountColor = isExpense
                              ? context.colors.expense
                              : isTransfer
                                  ? context.colors.primary
                                  : context.colors.income;
                          final sign = isExpense
                              ? '- '
                              : isTransfer
                                  ? '⇄ '
                                  : '+ ';

                          return ListTile(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddEditTransactionScreen(existing: t),
                                fullscreenDialog: true,
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: context.colors.surfaceVariant,
                              child: Text(
                                isTransfer ? '🔄' : category?.icon ?? '📦',
                              ),
                            ),
                            title: Text(
                                isTransfer ? 'Transfer' : category?.name ?? 'Other'),
                            subtitle: Text(
                              '${t.note?.isNotEmpty == true ? '${t.note} • ' : ''}${account?.name ?? ''} • ${DateFormatter.formatShortDate(t.date)}',
                            ),
                            trailing: Text(
                              '$sign${CurrencyFormatter.format(t.amount)}',
                              style: TextStyle(
                                  color: amountColor,
                                  fontWeight: FontWeight.w700),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  final SearchFilters filters;
  const _FilterBar({required this.filters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: filters.type == null
                ? 'Type'
                : filters.type!.toUpperCase(),
            active: filters.type != null,
            onTap: () async {
              final selected = await showModalBottomSheet<String?>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                          title: const Text('All'),
                          onTap: () => Navigator.pop(ctx, '')),
                      ListTile(
                          title: const Text('Expense'),
                          onTap: () => Navigator.pop(ctx, 'expense')),
                      ListTile(
                          title: const Text('Income'),
                          onTap: () => Navigator.pop(ctx, 'income')),
                      ListTile(
                          title: const Text('Transfer'),
                          onTap: () => Navigator.pop(ctx, 'transfer')),
                    ],
                  ),
                ),
              );
              if (selected != null) {
                ref.read(searchFiltersProvider.notifier).state =
                    selected.isEmpty
                        ? filters.copyWith(clearType: true)
                        : filters.copyWith(type: selected);
              }
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filters.startDate == null
                ? 'Date range'
                : '${DateFormatter.formatShortDate(filters.startDate!)} - ${DateFormatter.formatShortDate(filters.endDate!)}',
            active: filters.startDate != null,
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (range != null) {
                ref.read(searchFiltersProvider.notifier).state =
                    filters.copyWith(
                  startDate: range.start,
                  endDate: DateTime(range.end.year, range.end.month,
                      range.end.day, 23, 59, 59),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: filters.minAmount == null && filters.maxAmount == null
                ? 'Amount'
                : '${filters.minAmount?.toStringAsFixed(0) ?? '0'} - ${filters.maxAmount?.toStringAsFixed(0) ?? '∞'}',
            active: filters.minAmount != null || filters.maxAmount != null,
            onTap: () async {
              final result = await showDialog<Map<String, double?>>(
                context: context,
                builder: (ctx) {
                  final minCtl = TextEditingController(
                      text: filters.minAmount?.toStringAsFixed(0) ?? '');
                  final maxCtl = TextEditingController(
                      text: filters.maxAmount?.toStringAsFixed(0) ?? '');
                  return AlertDialog(
                    title: const Text('Amount range'),
                    content: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minCtl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'Min'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxCtl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'Max'),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, {
                          'min': double.tryParse(minCtl.text),
                          'max': double.tryParse(maxCtl.text),
                        }),
                        child: const Text('Apply'),
                      ),
                    ],
                  );
                },
              );
              if (result != null) {
                ref.read(searchFiltersProvider.notifier).state =
                    filters.copyWith(
                  minAmount: result['min'],
                  maxAmount: result['max'],
                );
              }
            },
          ),
          if (!filters.isEmpty) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Clear',
              active: false,
              onTap: () {
                ref.read(searchFiltersProvider.notifier).state =
                    const SearchFilters();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? context.colors.primarySurface : context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? context.colors.primary : context.colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? context.colors.primary : context.colors.textSecondary,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
