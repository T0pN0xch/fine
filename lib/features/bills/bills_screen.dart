import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(activeBillsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Bills')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const _BillFormScreen())),
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bills) {
          if (bills.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_outlined,
                      size: 56, color: context.colors.textHint),
                  const SizedBox(height: 12),
                  Text('No recurring bills',
                      style: TextStyle(
                          color: context.colors.textSecondary, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Tap + to track subscriptions & bills',
                      style:
                          TextStyle(color: context.colors.textHint, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: bills.length,
            itemBuilder: (_, i) => _BillCard(
              bill: bills[i],
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _BillFormScreen(existing: bills[i]))),
            ),
          );
        },
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback onTap;
  const _BillCard({required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final daysLeft = bill.nextDueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysLeft < 0;
    final isDueSoon = daysLeft >= 0 && daysLeft <= 3;
    final statusColor = isOverdue
        ? context.colors.expense
        : isDueSoon
            ? context.colors.warning
            : context.colors.textSecondary;
    final dueLabel = isOverdue
        ? 'Overdue by ${(-daysLeft)} day${-daysLeft != 1 ? 's' : ''}'
        : daysLeft == 0
            ? 'Due today'
            : 'Due in $daysLeft day${daysLeft != 1 ? 's' : ''}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isOverdue ? context.colors.expenseLight : context.colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child:
                      Text(bill.icon, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12, color: statusColor),
                      const SizedBox(width: 3),
                      Text(dueLabel,
                          style: TextStyle(
                              color: statusColor, fontSize: 11)),
                      const SizedBox(width: 8),
                      Text('·',
                          style:
                              TextStyle(color: context.colors.textHint)),
                      const SizedBox(width: 8),
                      Text(
                        _intervalLabel(bill.repeatInterval),
                        style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(bill.amount),
              style: TextStyle(
                  color: context.colors.expense,
                  fontWeight: FontWeight.w700,
                  fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  String _intervalLabel(String interval) {
    switch (interval.toLowerCase()) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'yearly':
        return 'Yearly';
      default:
        return 'Monthly';
    }
  }
}

// ── Bill Form ─────────────────────────────────────────────────────────────────

class _BillFormScreen extends ConsumerStatefulWidget {
  final Bill? existing;
  const _BillFormScreen({this.existing});

  @override
  ConsumerState<_BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends ConsumerState<_BillFormScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late String _icon;
  late String _interval;
  late DateTime _nextDue;
  bool _saving = false;

  static const _icons = [
    '📄', '📱', '🌐', '💡', '🚰', '🏠', '🎵', '🎬', '📺', '🏋️',
    '☁️', '🛡️', '🚗', '📦', '🏥', '📚', '💳', '🎮', '🍕', '☕',
  ];

  static const _intervals = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _amountCtrl = TextEditingController(
        text: e?.amount.toStringAsFixed(2) ?? '');
    _icon = e?.icon ?? '📄';
    _interval = e?.repeatInterval ?? 'Monthly';
    _nextDue = e?.nextDueDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name is required')));
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
      final companion = BillsCompanion(
        name: Value(_nameCtrl.text.trim()),
        icon: Value(_icon),
        amount: Value(amount),
        repeatInterval: Value(_interval),
        nextDueDate: Value(_nextDue),
        currency: const Value('MYR'),
        isActive: const Value(true),
        reminderEnabled: const Value(true),
        reminderDaysBefore: const Value(1),
      );
      if (widget.existing != null) {
        await db
            .updateBill(companion.copyWith(id: Value(widget.existing!.id)));
      } else {
        await db.insertBill(companion);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    await ref.read(databaseProvider).deleteBill(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Bill' : 'Add Bill'),
        actions: [
          if (widget.existing != null)
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Icon
          Text('Icon', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _icons.map((ic) {
              final sel = ic == _icon;
              return GestureDetector(
                onTap: () => setState(() => _icon = ic),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: sel
                        ? context.colors.primarySurface
                        : context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: sel
                        ? Border.all(color: context.colors.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                      child: Text(ic,
                          style: const TextStyle(fontSize: 22))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Name
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Bill name'),
          ),
          const SizedBox(height: 14),

          // Amount
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Amount', prefixText: 'RM '),
          ),
          const SizedBox(height: 20),

          // Repeat interval
          Text('Repeat', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _intervals.map((iv) {
              final sel = _interval == iv;
              return ChoiceChip(
                label: Text(iv),
                selected: sel,
                onSelected: (_) => setState(() => _interval = iv),
                selectedColor: context.colors.primarySurface,
                labelStyle: TextStyle(
                    color: sel ? context.colors.primary : context.colors.textPrimary,
                    fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Next due date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Text('📅', style: TextStyle(fontSize: 24)),
            title: const Text('Next due date'),
            subtitle: Text(DateFormatter.formatDate(_nextDue)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _nextDue,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _nextDue = picked);
            },
          ),
          const Divider(),
          const SizedBox(height: 24),

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
                  : Text(
                      widget.existing != null ? 'Save Changes' : 'Add Bill'),
            ),
          ),
        ],
      ),
    );
  }
}
