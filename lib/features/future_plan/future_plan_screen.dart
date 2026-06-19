import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouncy_tap.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';

class FuturePlanScreen extends ConsumerWidget {
  const FuturePlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final planAsync = ref.watch(monthlyPlanProvider);
    final commitmentsAsync = ref.watch(commitmentsForMonthProvider);
    final projectedAsync = ref.watch(projectedRemainingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Future Plan & Commitment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CommitmentFormScreen(year: month.year, month: month.month),
            )),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _MonthStepper(month: month, ref: ref),
          const SizedBox(height: 16),
          planAsync.when(
            loading: () => const SizedBox(
                height: 100, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
            data: (plan) => _SalaryCard(
              plan: plan,
              year: month.year,
              month: month.month,
            ),
          ),
          const SizedBox(height: 16),
          projectedAsync.when(
            loading: () => const SizedBox(
                height: 90, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
            data: (projected) => _ProjectedRemainingBanner(projected: projected),
          ),
          const SizedBox(height: 20),
          Text('Commitments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          commitmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (commitments) {
              if (commitments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_note_outlined,
                            size: 56, color: context.colors.textHint),
                        const SizedBox(height: 12),
                        Text('No commitments yet',
                            style: TextStyle(
                                color: context.colors.textSecondary, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Tap + to add an upcoming bill or expense',
                            style:
                                TextStyle(color: context.colors.textHint, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: commitments
                    .map((c) => _CommitmentRow(
                          commitment: c,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => CommitmentFormScreen(
                                year: month.year, month: month.month, existing: c),
                          )),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Month Stepper ─────────────────────────────────────────────────────────────

class _MonthStepper extends StatelessWidget {
  final DateTime month;
  final WidgetRef ref;
  const _MonthStepper({required this.month, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: context.colors.textPrimary),
          onPressed: () => ref.read(selectedMonthProvider.notifier).state =
              DateTime(month.year, month.month - 1),
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: Text(
            DateFormatter.formatMonthYear(month),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: context.colors.textPrimary),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: context.colors.textPrimary),
          onPressed: () => ref.read(selectedMonthProvider.notifier).state =
              DateTime(month.year, month.month + 1),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

// ── Salary Card ────────────────────────────────────────────────────────────────

class _SalaryCard extends ConsumerWidget {
  final MonthlyPlan? plan;
  final int year;
  final int month;
  const _SalaryCard({required this.plan, required this.year, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salary = plan?.expectedSalary ?? 0.0;
    final salaryDay = plan?.salaryDay ?? 1;

    return GestureDetector(
      onTap: () => _showEditSalarySheet(context, ref),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.colors.incomeSurface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.colors.income,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                  child: Icon(Icons.payments_outlined, color: Colors.white)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Expected Salary',
                      style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(CurrencyFormatter.format(salary),
                      style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text('Comes in on day $salaryDay of the month',
                      style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, color: context.colors.income, size: 20),
          ],
        ),
      ),
    );
  }

  void _showEditSalarySheet(BuildContext context, WidgetRef ref) {
    final salaryCtrl =
        TextEditingController(text: plan?.expectedSalary.toStringAsFixed(2) ?? '');
    int salaryDay = plan?.salaryDay ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Expected Salary',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: salaryCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Expected salary', prefixText: 'RM '),
              ),
              const SizedBox(height: 14),
              Text('Salary day of month', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [1, 5, 10, 15, 20, 25, 28, 30].map((d) {
                  final selected = salaryDay == d;
                  return BouncyTap(
                    onTap: () => setSheetState(() => salaryDay = d),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? context.colors.primary
                            : context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('$d',
                            style: TextStyle(
                                color: selected ? Colors.white : context.colors.textPrimary,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final salary = double.tryParse(salaryCtrl.text) ?? 0.0;
                    final db = ref.read(databaseProvider);
                    await db.upsertMonthlyPlan(MonthlyPlansCompanion.insert(
                      year: year,
                      month: month,
                      expectedSalary: Value(salary),
                      salaryDay: Value(salaryDay),
                    ));
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Projected Remaining Banner ───────────────────────────────────────────────

class _ProjectedRemainingBanner extends StatelessWidget {
  final double projected;
  const _ProjectedRemainingBanner({required this.projected});

  @override
  Widget build(BuildContext context) {
    final positive = projected >= 0;
    final bg = positive ? context.colors.incomeSurface : context.colors.expenseSurface;
    final fg = positive ? context.colors.income : context.colors.expense;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Projected Remaining This Month',
              style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(projected),
            style: TextStyle(color: fg, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Salary minus what you\'ve spent and what\'s still owed',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Commitment Row ────────────────────────────────────────────────────────────

class _CommitmentRow extends ConsumerWidget {
  final Commitment commitment;
  final VoidCallback onTap;
  const _CommitmentRow({required this.commitment, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: BouncyTap(
          onTap: () {
            final markingPaid = !commitment.isPaid;
            final db = ref.read(databaseProvider);
            db.updateCommitment(CommitmentsCompanion(
              id: Value(commitment.id),
              isPaid: Value(markingPaid),
            ));
            if (markingPaid) {
              showCelebrationOverlay(context, color: context.colors.income);
            }
          },
          child: Icon(
            commitment.isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
            color: commitment.isPaid ? context.colors.income : context.colors.textHint,
          ),
        ),
        title: Text(
          commitment.name,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            decoration: commitment.isPaid ? TextDecoration.lineThrough : null,
            color: commitment.isPaid ? context.colors.textHint : context.colors.textPrimary,
          ),
        ),
        subtitle: commitment.dueDay != null
            ? Text('Due day ${commitment.dueDay}',
                style: TextStyle(color: context.colors.textSecondary, fontSize: 12))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(CurrencyFormatter.format(commitment.amount),
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: commitment.isPaid
                        ? context.colors.textHint
                        : context.colors.expense)),
            IconButton(
              icon: Icon(Icons.delete_outline, color: context.colors.textHint, size: 20),
              onPressed: () => ref.read(databaseProvider).deleteCommitment(commitment.id),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Commitment Form ───────────────────────────────────────────────────────────

class CommitmentFormScreen extends ConsumerStatefulWidget {
  final int year;
  final int month;
  final Commitment? existing;
  const CommitmentFormScreen(
      {super.key, required this.year, required this.month, this.existing});

  @override
  ConsumerState<CommitmentFormScreen> createState() => _CommitmentFormScreenState();
}

class _CommitmentFormScreenState extends ConsumerState<CommitmentFormScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  int? _dueDay;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _amountCtrl = TextEditingController(text: e?.amount.toStringAsFixed(2) ?? '');
    _dueDay = e?.dueDay;
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    try {
      if (widget.existing != null) {
        await db.updateCommitment(CommitmentsCompanion(
          id: Value(widget.existing!.id),
          year: Value(widget.year),
          month: Value(widget.month),
          name: Value(_nameCtrl.text.trim()),
          amount: Value(amount),
          dueDay: Value(_dueDay),
          isPaid: Value(widget.existing!.isPaid),
        ));
      } else {
        await db.insertCommitment(CommitmentsCompanion.insert(
          year: widget.year,
          month: widget.month,
          name: _nameCtrl.text.trim(),
          amount: amount,
          dueDay: Value(_dueDay),
        ));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Commitment' : 'New Commitment'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Name (e.g. Rent, Car loan)'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount', prefixText: 'RM '),
          ),
          const SizedBox(height: 14),
          Text('Due day (optional)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GestureDetector(
                onTap: () => setState(() => _dueDay = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _dueDay == null
                        ? context.colors.primary
                        : context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('None',
                      style: TextStyle(
                          color: _dueDay == null ? Colors.white : context.colors.textPrimary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              ...[1, 5, 10, 15, 20, 25, 28, 30].map((d) {
                final selected = _dueDay == d;
                return GestureDetector(
                  onTap: () => setState(() => _dueDay = d),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected ? context.colors.primary : context.colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('$d',
                          style: TextStyle(
                              color: selected ? Colors.white : context.colors.textPrimary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                );
              }),
            ],
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
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.existing != null ? 'Save Changes' : 'Add Commitment'),
            ),
          ),
        ],
      ),
    );
  }
}
