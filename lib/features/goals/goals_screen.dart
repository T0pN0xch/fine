import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bouncy_tap.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(allGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const GoalFormScreen(),
            )),
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allGoals) {
          final active = allGoals.where((g) => !g.isArchived).toList();
          final archived = allGoals.where((g) => g.isArchived).toList();
          final totalSaved =
              active.fold(0.0, (s, g) => s + g.savedAmount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _GoalsSummaryCard(
                  totalSaved: totalSaved, goalCount: active.length),
              const SizedBox(height: 20),
              if (active.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.savings_outlined,
                            size: 56, color: context.colors.textHint),
                        const SizedBox(height: 12),
                        Text('No goals yet',
                            style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Tap + to create your first savings goal',
                            style: TextStyle(
                                color: context.colors.textHint, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                ...active.map((g) => _GoalCard(
                      goal: g,
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  GoalDetailScreen(goal: g))),
                    )),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Archived',
                      style: TextStyle(
                          color: context.colors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  children: archived
                      .map((g) => Opacity(
                            opacity: 0.6,
                            child: _GoalCard(
                              goal: g,
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          GoalDetailScreen(goal: g))),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _GoalsSummaryCard extends StatelessWidget {
  final double totalSaved;
  final int goalCount;
  const _GoalsSummaryCard({required this.totalSaved, required this.goalCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Saved',
              style: TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(totalSaved),
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.warning,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$goalCount goal${goalCount != 1 ? 's' : ''} in progress',
              style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Goal Card ─────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;
  const _GoalCard({required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.goalColors[goal.colorIndex % AppColors.goalColors.length];
    final progress = goal.targetAmount > 0
        ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return BouncyTap(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                      child: Text(goal.icon,
                          style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: context.colors.textPrimary)),
                      if (goal.targetDate != null)
                        Text(
                          'by ${DateFormatter.formatDate(goal.targetDate!)}',
                          style: TextStyle(
                              color: context.colors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.star,
                    color: context.colors.textSecondary, size: 18),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${CurrencyFormatter.format(goal.savedAmount)} from ${CurrencyFormatter.format(goal.targetAmount)}',
              style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
            if (goal.notes != null && goal.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                goal.notes!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: context.colors.textPrimary.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white,
                valueColor:
                    AlwaysStoppedAnimation(context.colors.textPrimary),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Goal Form ─────────────────────────────────────────────────────────────────

class GoalFormScreen extends ConsumerStatefulWidget {
  final Goal? existing;
  const GoalFormScreen({super.key, this.existing});

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _targetCtrl;
  late TextEditingController _notesCtrl;
  late String _icon;
  late int _colorIndex;
  DateTime? _targetDate;
  bool _saving = false;

  static const _icons = [
    '🎯', '🏖️', '🏠', '🚗', '🎓', '💍', '👶', '✈️', '💻', '🎉'
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _targetCtrl =
        TextEditingController(text: e?.targetAmount.toStringAsFixed(2) ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _icon = e?.icon ?? '🎯';
    _colorIndex = e?.colorIndex ?? 0;
    _targetDate = e?.targetDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    final target = double.tryParse(_targetCtrl.text);
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid target amount')));
      return;
    }
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    try {
      final companion = GoalsCompanion(
        name: Value(_nameCtrl.text.trim()),
        icon: Value(_icon),
        colorIndex: Value(_colorIndex),
        targetAmount: Value(target),
        targetDate: Value(_targetDate),
        notes: Value(_notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim()),
      );
      if (widget.existing != null) {
        await db.updateGoal(companion.copyWith(
            id: Value(widget.existing!.id),
            savedAmount: Value(widget.existing!.savedAmount)));
      } else {
        await db.insertGoal(companion);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Goal' : 'New Goal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Icon', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _icons.map((ic) {
              final selected = ic == _icon;
              return GestureDetector(
                onTap: () => setState(() => _icon = ic),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected
                        ? context.colors.primarySurface
                        : context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? Border.all(color: context.colors.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                      child:
                          Text(ic, style: const TextStyle(fontSize: 24))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Goal name'),
          ),
          const SizedBox(height: 14),

          Text('Color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(AppColors.goalColors.length, (i) {
              final selected = _colorIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _colorIndex = i),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.goalColors[i],
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: Colors.black26, width: 3)
                        : null,
                  ),
                  child: selected
                      ? Icon(Icons.check,
                          color: context.colors.textPrimary, size: 16)
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _targetCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Target amount', prefixText: 'RM '),
          ),
          const SizedBox(height: 14),

          Text('Target date (optional)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _targetDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(DateTime.now().year + 20),
              );
              if (picked != null) setState(() => _targetDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 18, color: context.colors.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    _targetDate != null
                        ? DateFormatter.formatDate(_targetDate!)
                        : 'No target date',
                    style: TextStyle(
                        color: _targetDate != null
                            ? context.colors.textPrimary
                            : context.colors.textHint),
                  ),
                  const Spacer(),
                  if (_targetDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _targetDate = null),
                      child: Icon(Icons.close,
                          size: 18, color: context.colors.textHint),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          Text('Notes (optional)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Add a note about this goal...'),
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
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(widget.existing != null
                      ? 'Save Changes'
                      : 'Create Goal'),
            ),
          ),
        ],
      ),
    );
  }
}
