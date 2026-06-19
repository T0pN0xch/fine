import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/csv_export_service.dart';
import '../../providers/providers.dart';
import '../accounts/accounts_screen.dart';
import '../categories/categories_screen.dart';
import '../budgets/budgets_screen.dart';
import '../bills/bills_screen.dart';
import '../transactions/search_screen.dart';
import '../future_plan/future_plan_screen.dart';

class MoreMenuDrawer extends ConsumerWidget {
  const MoreMenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Profile banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: context.colors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                        child: Text('😊', style: TextStyle(fontSize: 28))),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fine',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      Text('Personal Finance',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Manage section
            const _SectionLabel('Manage'),
            _SettingsTile(
              icon: '💳',
              title: 'Accounts',
              subtitle: '${accountsAsync.valueOrNull?.length ?? 0} accounts',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AccountsScreen()));
              },
            ),
            _SettingsTile(
              icon: '🏷️',
              title: 'Categories',
              subtitle: 'Manage your categories',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CategoriesScreen()));
              },
            ),
            _SettingsTile(
              icon: '🎯',
              title: 'Budgets',
              subtitle: 'Set spending limits',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BudgetsScreen()));
              },
            ),
            _SettingsTile(
              icon: '📄',
              title: 'Recurring Bills',
              subtitle: 'Track subscriptions & bills',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BillsScreen()));
              },
            ),
            _SettingsTile(
              icon: '🔍',
              title: 'Search Transactions',
              subtitle: 'Find by note, amount, date & more',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen()));
              },
            ),
            _SettingsTile(
              icon: '🗒️',
              title: 'Future Plan & Commitment',
              subtitle: 'Predict what you can spend this month',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const FuturePlanScreen()));
              },
            ),

            _SettingsTile(
              icon: '📤',
              title: 'Export Data',
              subtitle: 'Export all transactions as CSV',
              onTap: () async {
                final db = ref.read(databaseProvider);
                Navigator.of(context).pop();
                try {
                  await CsvExportService.exportTransactions(db);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Export failed: $e')));
                  }
                }
              },
            ),

            const SizedBox(height: 12),

            // Appearance section
            const _SectionLabel('Appearance'),
            _ThemeToggleTile(current: themeMode, ref: ref),

            const SizedBox(height: 12),

            // App info section
            const _SectionLabel('About'),
            const _SettingsTile(
              icon: 'ℹ️',
              title: 'Version',
              subtitle: '1.0.0',
              onTap: null,
            ),
            _SettingsTile(
              icon: '📧',
              title: 'Feedback',
              subtitle: 'Send us your thoughts',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.colors.textHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          color: context.colors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: context.colors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  final ThemeMode current;
  final WidgetRef ref;
  const _ThemeToggleTile({required this.current, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              const Expanded(
                child: Text('Theme',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ThemeChip(
                  label: 'Light',
                  icon: '☀️',
                  selected: current == ThemeMode.light,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .state = ThemeMode.light),
              const SizedBox(width: 8),
              _ThemeChip(
                  label: 'Dark',
                  icon: '🌙',
                  selected: current == ThemeMode.dark,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .state = ThemeMode.dark),
              const SizedBox(width: 8),
              _ThemeChip(
                  label: 'System',
                  icon: '📱',
                  selected: current == ThemeMode.system,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .state = ThemeMode.system),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeChip(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? context.colors.primarySurface
                : context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: context.colors.primary, width: 1.5)
                : null,
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? context.colors.primary : context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
