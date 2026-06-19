import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountForm(context, ref, null),
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) {
          final total = accounts.fold(0.0, (s, a) => s + a.balance);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // Total balance card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(total),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${accounts.length} account${accounts.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('My Accounts',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),

              if (accounts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 48, color: context.colors.textHint),
                        const SizedBox(height: 12),
                        Text('No accounts yet',
                            style: TextStyle(
                                color: context.colors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                ...accounts.map((a) => _AccountCard(
                      account: a,
                      onTap: () => _showAccountForm(context, ref, a),
                    )),
            ],
          );
        },
      ),
    );
  }

  void _showAccountForm(
      BuildContext context, WidgetRef ref, Account? existing) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _AccountFormScreen(existing: existing),
    ));
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;
  const _AccountCard({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
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
                child: Text(account.icon,
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(account.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      if (account.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.colors.primarySurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Default',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(_typeLabel(account.type),
                      style: TextStyle(
                          color: context.colors.textSecondary, fontSize: 12)),
                  if (account.notes != null && account.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(account.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: context.colors.textHint,
                            fontSize: 11,
                            fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(account.balance),
              style: TextStyle(
                color: account.balance >= 0
                    ? context.colors.textPrimary
                    : context.colors.expense,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'bank':
        return 'Bank Account';
      case 'ewallet':
        return 'E-Wallet';
      case 'payable':
        return 'Account Payable';
      case 'receivable':
        return 'Account Receivable';
      case 'investment':
        return 'Investment';
      case 'card':
        return 'Debit/Credit Card';
      default:
        return 'Cash';
    }
  }
}

// ── Malaysian Banks ───────────────────────────────────────────────────────────

class MalaysianBank {
  final String name;
  final String initials;
  final Color color;
  const MalaysianBank(
      {required this.name, required this.initials, required this.color});
}

const malaysianBanks = [
  MalaysianBank(name: 'Maybank', initials: 'MB', color: Color(0xFFFFC726)),
  MalaysianBank(name: 'CIMB Bank', initials: 'CB', color: Color(0xFFE3122C)),
  MalaysianBank(name: 'Public Bank', initials: 'PB', color: Color(0xFFC8102E)),
  MalaysianBank(name: 'RHB Bank', initials: 'RHB', color: Color(0xFF003D79)),
  MalaysianBank(name: 'Hong Leong Bank', initials: 'HLB', color: Color(0xFF003876)),
  MalaysianBank(name: 'AmBank', initials: 'AMB', color: Color(0xFFEE2E24)),
  MalaysianBank(name: 'Bank Islam', initials: 'BI', color: Color(0xFF00833E)),
  MalaysianBank(name: 'Bank Rakyat', initials: 'BR', color: Color(0xFF005BAC)),
  MalaysianBank(name: 'BSN', initials: 'BSN', color: Color(0xFF8E1537)),
  MalaysianBank(name: 'Affin Bank', initials: 'AB', color: Color(0xFF6A2C70)),
  MalaysianBank(name: 'UOB Malaysia', initials: 'UOB', color: Color(0xFF0D2B5B)),
  MalaysianBank(name: 'OCBC Bank', initials: 'OCBC', color: Color(0xFFD2122E)),
  MalaysianBank(name: 'HSBC Bank', initials: 'HSBC', color: Color(0xFFDB0011)),
  MalaysianBank(name: 'Standard Chartered', initials: 'SC', color: Color(0xFF0473EA)),
  MalaysianBank(name: 'Alliance Bank', initials: 'ALB', color: Color(0xFF004B87)),
  MalaysianBank(name: 'Bank Muamalat', initials: 'BM', color: Color(0xFF7A1F2B)),
  MalaysianBank(name: 'Agrobank', initials: 'AGB', color: Color(0xFF1E7B34)),
];

class BankBadge extends StatelessWidget {
  final MalaysianBank bank;
  final double size;
  const BankBadge({super.key, required this.bank, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bank.color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          bank.initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.28,
          ),
        ),
      ),
    );
  }
}

class _BankPicker extends StatelessWidget {
  const _BankPicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Choose your bank',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: malaysianBanks.length,
              itemBuilder: (_, i) {
                final bank = malaysianBanks[i];
                return ListTile(
                  leading: BankBadge(bank: bank, size: 38),
                  title: Text(bank.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context, bank),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Investment Platforms ──────────────────────────────────────────────────────

class InvestmentPlatform {
  final String name;
  final String initials;
  final String icon;
  final Color color;
  const InvestmentPlatform(
      {required this.name,
      required this.initials,
      required this.icon,
      required this.color});
}

const investmentPlatforms = [
  InvestmentPlatform(
      name: 'Moomoo', initials: 'MOO', icon: '📈', color: Color(0xFFFF6A39)),
  InvestmentPlatform(
      name: 'ASNB', initials: 'ASNB', icon: '🏦', color: Color(0xFF00833E)),
  InvestmentPlatform(
      name: 'Crypto', initials: '₿', icon: '🪙', color: Color(0xFFF7931A)),
  InvestmentPlatform(
      name: 'Rakuten Trade',
      initials: 'RT',
      icon: '📊',
      color: Color(0xFFBF0000)),
  InvestmentPlatform(
      name: 'StashAway', initials: 'SA', icon: '💼', color: Color(0xFF00A19A)),
  InvestmentPlatform(
      name: 'Versa', initials: 'VR', icon: '💰', color: Color(0xFF6C5CE7)),
  InvestmentPlatform(
      name: 'Tng GO+', initials: 'GO+', icon: '🟦', color: Color(0xFF0070EB)),
  InvestmentPlatform(
      name: 'KWSP/EPF', initials: 'EPF', icon: '🛡️', color: Color(0xFF8E1537)),
  InvestmentPlatform(
      name: 'Bursa Malaysia',
      initials: 'BM',
      icon: '📉',
      color: Color(0xFF003D79)),
];

class InvestmentBadge extends StatelessWidget {
  final InvestmentPlatform platform;
  final double size;
  const InvestmentBadge({super.key, required this.platform, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: platform.color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          platform.initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.24,
          ),
        ),
      ),
    );
  }
}

class _InvestmentPlatformPicker extends StatelessWidget {
  const _InvestmentPlatformPicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Choose investment platform',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: investmentPlatforms.length,
              itemBuilder: (_, i) {
                final platform = investmentPlatforms[i];
                return ListTile(
                  leading: InvestmentBadge(platform: platform, size: 38),
                  title: Text(platform.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context, platform),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Malaysian E-Wallets ────────────────────────────────────────────────────────

class EWalletProvider {
  final String name;
  final String initials;
  final String icon;
  final Color color;
  const EWalletProvider(
      {required this.name,
      required this.initials,
      required this.icon,
      required this.color});
}

const eWalletProviders = [
  EWalletProvider(
      name: "Touch 'n Go eWallet",
      initials: 'TNG',
      icon: '📱',
      color: Color(0xFF0070EB)),
  EWalletProvider(
      name: 'GrabPay', initials: 'GP', icon: '🚗', color: Color(0xFF00B14F)),
  EWalletProvider(
      name: 'Boost', initials: 'BST', icon: '⚡', color: Color(0xFFE6231E)),
  EWalletProvider(
      name: 'ShopeePay', initials: 'SP', icon: '🛍️', color: Color(0xFFEE4D2D)),
  EWalletProvider(
      name: 'BigPay', initials: 'BP', icon: '💳', color: Color(0xFFD4202C)),
  EWalletProvider(
      name: 'MAE by Maybank',
      initials: 'MAE',
      icon: '🐝',
      color: Color(0xFFFFC726)),
  EWalletProvider(
      name: 'Setel', initials: 'SET', icon: '⛽', color: Color(0xFF00A19A)),
  EWalletProvider(
      name: 'WeChat Pay', initials: 'WC', icon: '💬', color: Color(0xFF09BB07)),
  EWalletProvider(
      name: 'Alipay', initials: 'AP', icon: '🅰️', color: Color(0xFF1678FF)),
];

class EWalletBadge extends StatelessWidget {
  final EWalletProvider provider;
  final double size;
  const EWalletBadge({super.key, required this.provider, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(color: provider.color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          provider.initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.24,
          ),
        ),
      ),
    );
  }
}

class _EWalletPicker extends StatelessWidget {
  const _EWalletPicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Choose your e-wallet',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: eWalletProviders.length,
              itemBuilder: (_, i) {
                final provider = eWalletProviders[i];
                return ListTile(
                  leading: EWalletBadge(provider: provider, size: 38),
                  title: Text(provider.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context, provider),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Account Form ──────────────────────────────────────────────────────────────

class _AccountFormScreen extends ConsumerStatefulWidget {
  final Account? existing;
  const _AccountFormScreen({this.existing});

  @override
  ConsumerState<_AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<_AccountFormScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _balanceCtrl;
  late TextEditingController _notesCtrl;
  late String _icon;
  late String _type;
  late int _colorIndex;
  late bool _isDefault;
  bool _saving = false;

  static const _icons = [
    '💵', '🏦', '📱', '💳', '💰', '🏧', '💼', '🪙', '🏪', '📊'
  ];
  static const _types = [
    'cash',
    'bank',
    'ewallet',
    'payable',
    'receivable',
    'investment',
    'card'
  ];
  static const _typeLabels = [
    'Cash',
    'Bank',
    'E-Wallet',
    'Account Payable',
    'Account Receivable',
    'Investment',
    'Debit/Credit Card'
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _balanceCtrl =
        TextEditingController(text: e?.balance.toStringAsFixed(2) ?? '0.00');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _icon = e?.icon ?? '💵';
    _type = e?.type ?? 'cash';
    _colorIndex = e?.colorIndex ?? 0;
    _isDefault = e?.isDefault ?? false;
  }

  Future<void> _pickBank() async {
    final bank = await showModalBottomSheet<MalaysianBank>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BankPicker(),
    );
    if (bank != null) {
      setState(() {
        _nameCtrl.text = bank.name;
        _icon = '🏦';
      });
    }
  }

  Future<void> _pickInvestmentPlatform() async {
    final platform = await showModalBottomSheet<InvestmentPlatform>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _InvestmentPlatformPicker(),
    );
    if (platform != null) {
      setState(() {
        _nameCtrl.text = platform.name;
        _icon = platform.icon;
      });
    }
  }

  Future<void> _pickEWallet() async {
    final provider = await showModalBottomSheet<EWalletProvider>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EWalletPicker(),
    );
    if (provider != null) {
      setState(() {
        _nameCtrl.text = provider.name;
        _icon = provider.icon;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    final balance = double.tryParse(_balanceCtrl.text) ?? 0.0;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);

    try {
      final companion = AccountsCompanion(
        name: Value(_nameCtrl.text.trim()),
        icon: Value(_icon),
        type: Value(_type),
        colorIndex: Value(_colorIndex),
        balance: Value(balance),
        currency: const Value('MYR'),
        isDefault: Value(_isDefault),
        notes: Value(_notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim()),
      );
      if (widget.existing != null) {
        await db.updateAccount(
            companion.copyWith(id: Value(widget.existing!.id)));
      } else {
        await db.insertAccount(companion);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This will delete the account. Transactions linked to it will remain.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: TextStyle(color: context.colors.expense))),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(databaseProvider).deleteAccount(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Account' : 'Add Account'),
        actions: [
          if (widget.existing != null)
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Icon picker
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
                      child: Text(ic,
                          style: const TextStyle(fontSize: 24))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Name
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Account name'),
          ),
          const SizedBox(height: 14),

          // Type
          Text('Type', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(_types.length, (i) {
              final selected = _type == _types[i];
              return ChoiceChip(
                label: Text(_typeLabels[i]),
                selected: selected,
                onSelected: (_) => setState(() => _type = _types[i]),
                selectedColor: context.colors.primarySurface,
                labelStyle: TextStyle(
                    color: selected ? context.colors.primary : context.colors.textPrimary,
                    fontWeight: FontWeight.w600),
              );
            }),
          ),
          const SizedBox(height: 14),

          // Color
          Text('Color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(AppColors.categoryColors.length, (i) {
              final selected = _colorIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _colorIndex = i),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.categoryColors[i],
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: Colors.black26, width: 3)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 16)
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 14),

          // Bank picker (only for type == bank)
          if (_type == 'bank') ...[
            GestureDetector(
              onTap: _pickBank,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance, color: context.colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Choose your bank',
                          style: TextStyle(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ),
                    Icon(Icons.chevron_right, color: context.colors.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // E-wallet picker (only for type == ewallet)
          if (_type == 'ewallet') ...[
            GestureDetector(
              onTap: _pickEWallet,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.smartphone, color: context.colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Choose your e-wallet',
                          style: TextStyle(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ),
                    Icon(Icons.chevron_right, color: context.colors.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Investment platform picker (only for type == investment)
          if (_type == 'investment') ...[
            GestureDetector(
              onTap: _pickInvestmentPlatform,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: context.colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Choose investment platform',
                          style: TextStyle(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ),
                    Icon(Icons.chevron_right, color: context.colors.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Balance
          TextField(
            controller: _balanceCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(
                labelText: 'Current balance', prefixText: 'RM '),
          ),
          const SizedBox(height: 14),

          // Notes
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add a note about this account...'),
          ),
          const SizedBox(height: 14),

          // Default toggle
          SwitchListTile(
            value: _isDefault,
            onChanged: (v) => setState(() => _isDefault = v),
            title: const Text('Set as default account'),
            contentPadding: EdgeInsets.zero,
            activeColor: context.colors.primary,
          ),
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
                  : Text(widget.existing != null
                      ? 'Save Changes'
                      : 'Add Account'),
            ),
          ),
        ],
      ),
    );
  }
}
