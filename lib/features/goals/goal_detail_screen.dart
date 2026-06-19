import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouncy_tap.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';
import 'goals_screen.dart';

class GoalDetailScreen extends ConsumerWidget {
  final Goal goal;
  const GoalDetailScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(allGoalsProvider);
    final currentGoal = goalsAsync.valueOrNull
            ?.where((g) => g.id == goal.id)
            .cast<Goal?>()
            .firstOrNull ??
        goal;
    final topUpsAsync = ref.watch(goalTopUpsProvider(goal.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(currentGoal.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editGoal(context, currentGoal);
              } else if (value == 'archive') {
                _confirmArchive(context, ref, currentGoal, !currentGoal.isArchived);
              } else if (value == 'delete') {
                _confirmDelete(context, ref, currentGoal);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                  value: 'archive',
                  child: Text(currentGoal.isArchived ? 'Unarchive' : 'Archive')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _topUp(context, ref, currentGoal),
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Top Up'),
      ),
      body: topUpsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (topUps) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _GoalHeader(goal: currentGoal),
              const SizedBox(height: 20),
              if (topUps.isNotEmpty) ...[
                Text('Savings Progress',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _SavingsChart(topUps: topUps),
                const SizedBox(height: 24),
              ],
              Text('Top-Ups', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (topUps.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('No top-ups yet',
                        style: TextStyle(color: context.colors.textHint)),
                  ),
                )
              else
                ...topUps.map((t) => _TopUpTile(topUp: t)),
            ],
          );
        },
      ),
    );
  }

  void _editGoal(BuildContext context, Goal currentGoal) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GoalFormScreen(existing: currentGoal),
    ));
  }

  Future<void> _topUp(BuildContext context, WidgetRef ref, Goal currentGoal) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top up "${currentGoal.name}"',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Amount', prefixText: 'RM '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountCtrl.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Enter a valid amount')));
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Add Top-Up'),
              ),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      final amount = double.tryParse(amountCtrl.text);
      if (amount != null && amount > 0) {
        final wasComplete = currentGoal.targetAmount > 0 &&
            currentGoal.savedAmount >= currentGoal.targetAmount;
        await ref.read(databaseProvider).addGoalTopUp(GoalTopUpsCompanion(
              goalId: Value(currentGoal.id),
              amount: Value(amount),
              note: Value(noteCtrl.text.trim().isEmpty
                  ? null
                  : noteCtrl.text.trim()),
            ));
        final nowComplete = currentGoal.targetAmount > 0 &&
            (currentGoal.savedAmount + amount) >= currentGoal.targetAmount;
        if (!wasComplete && nowComplete && context.mounted) {
          showCelebrationOverlay(context, color: context.colors.income);
        }
      }
    }
  }

  Future<void> _confirmArchive(
      BuildContext context, WidgetRef ref, Goal currentGoal, bool archive) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(archive ? 'Archive goal?' : 'Unarchive goal?'),
        content: Text(archive
            ? 'This goal will be moved to the archived section.'
            : 'Restore this goal to your active goals?'),
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
      await ref
          .read(databaseProvider)
          .archiveGoal(currentGoal.id, archived: archive);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Goal currentGoal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text(
            'This will permanently delete "${currentGoal.name}" and all its top-up history. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(databaseProvider).deleteGoal(currentGoal.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

// ── Goal Header ───────────────────────────────────────────────────────────────

class _GoalHeader extends StatelessWidget {
  final Goal goal;
  const _GoalHeader({required this.goal});

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.goalColors[goal.colorIndex % AppColors.goalColors.length];
    final progress = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final remaining = (goal.targetAmount - goal.savedAmount).clamp(
        0.0, goal.targetAmount);

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
              Text(goal.icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(goal.name,
                    style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
              if (goal.isArchived)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Archived',
                      style: TextStyle(
                          color: context.colors.textPrimary, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.format(goal.savedAmount),
            style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w700),
          ),
          Text(
            'of ${CurrencyFormatter.format(goal.targetAmount)} target',
            style: TextStyle(
                color: context.colors.textPrimary.withOpacity(0.7), fontSize: 13),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white,
              valueColor:
                  AlwaysStoppedAnimation(AppColors.progressFillFor(color)),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('${(progress * 100).toStringAsFixed(0)}% saved',
                  style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (remaining > 0)
                Text('${CurrencyFormatter.format(remaining)} to go',
                    style: TextStyle(
                        color: context.colors.textPrimary.withOpacity(0.7),
                        fontSize: 12)),
              if (goal.targetDate != null) ...[
                const SizedBox(width: 8),
                Text('• by ${DateFormatter.formatDate(goal.targetDate!)}',
                    style: TextStyle(
                        color: context.colors.textPrimary.withOpacity(0.7),
                        fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Savings Chart ─────────────────────────────────────────────────────────────

class _SavingsChart extends StatelessWidget {
  final List<GoalTopUp> topUps;
  const _SavingsChart({required this.topUps});

  @override
  Widget build(BuildContext context) {
    final sorted = [...topUps]..sort((a, b) => a.date.compareTo(b.date));
    double running = 0;
    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      running += sorted[i].amount;
      spots.add(FlSpot(i.toDouble(), running));
    }

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
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: context.colors.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: context.colors.surfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top-Up Tile ───────────────────────────────────────────────────────────────

class _TopUpTile extends StatelessWidget {
  final GoalTopUp topUp;
  const _TopUpTile({required this.topUp});

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.incomeSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(Icons.savings_outlined,
                  color: context.colors.income, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topUp.note?.isNotEmpty == true ? topUp.note! : 'Top-up',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  DateFormatter.formatShortDate(topUp.date),
                  style: TextStyle(color: context.colors.textHint, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '+ ${CurrencyFormatter.format(topUp.amount)}',
            style: TextStyle(
                color: context.colors.income,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}
