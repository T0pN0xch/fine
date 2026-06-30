import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/theme/app_theme.dart';
import '../../core/services/home_widget_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? existing;
  const AddEditTransactionScreen({super.key, this.existing});

  @override
  ConsumerState<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState
    extends ConsumerState<AddEditTransactionScreen> {
  late String _type; // expense | income | transfer
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  final TextEditingController _tagInputController = TextEditingController();
  late DateTime _date;
  Category? _selectedCategory;
  Account? _selectedAccount;
  Account? _selectedToAccount;
  Member? _selectedMember;
  bool _memberInitialized = false;
  List<String> _tags = [];
  bool _saving = false;
  bool _tagsLoaded = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? 'expense';
    _amountController = TextEditingController(
        text: e != null ? e.amount.toStringAsFixed(2) : '');
    _noteController = TextEditingController(text: e?.note ?? '');
    _date = e?.date ?? DateTime.now();

    if (e != null) {
      ref.read(databaseProvider).getTagsForTransaction(e.id).then((tags) {
        if (mounted) {
          setState(() {
            _tags = tags.map((t) => t.name).toList();
            _tagsLoaded = true;
          });
        }
      });
    } else {
      _tagsLoaded = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final value = raw.trim();
    _tagInputController.clear();
    if (value.isEmpty) return;
    if (_tags.any((t) => t.toLowerCase() == value.toLowerCase())) return;
    setState(() => _tags.add(value));
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _initDefaults(List<Account> accounts, List<Category> cats,
      List<Member> members) {
    if (_selectedAccount != null) return;
    if (accounts.isNotEmpty) {
      final existing = widget.existing;
      if (existing != null) {
        _selectedAccount =
            accounts.firstWhere((a) => a.id == existing.accountId,
                orElse: () => accounts.first);
        if (existing.toAccountId != null) {
          _selectedToAccount = accounts.firstWhere(
              (a) => a.id == existing.toAccountId,
              orElse: () => accounts.first);
        }
      } else {
        _selectedAccount =
            accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first);
      }
    }
    if (cats.isNotEmpty && widget.existing?.categoryId != null) {
      _selectedCategory = cats.firstWhere(
          (c) => c.id == widget.existing!.categoryId,
          orElse: () => cats.first);
    } else if (cats.isNotEmpty && !isEditing && _selectedCategory == null) {
      final expenseCats = cats.where((c) => c.type == 'expense').toList();
      _selectedCategory = expenseCats
              .where((c) => c.name.toLowerCase() == 'food & drinks')
              .firstOrNull ??
          (expenseCats.isNotEmpty ? expenseCats.first : null);
    }
    if (!_memberInitialized && members.isNotEmpty) {
      _memberInitialized = true;
      final existingMemberId = widget.existing?.memberId;
      if (existingMemberId != null) {
        _selectedMember = members
            .where((m) => m.id == existingMemberId)
            .firstOrNull;
      } else if (!isEditing) {
        _selectedMember =
            members.where((m) => m.isDefault).firstOrNull ?? members.first;
      }
    }
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showError('Please enter an amount.');
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount greater than zero.');
      return;
    }
    if (_selectedAccount == null) {
      _showError('Please select an account.');
      return;
    }
    if (_type != 'transfer' && _selectedCategory == null) {
      _showError('Please select a category.');
      return;
    }
    if (_type == 'transfer' && _selectedToAccount == null) {
      _showError('Please select the destination account.');
      return;
    }
    if (_type == 'transfer' &&
        _selectedToAccount?.id == _selectedAccount?.id) {
      _showError('Origin and destination accounts must be different.');
      return;
    }

    setState(() => _saving = true);
    final db = ref.read(databaseProvider);

    try {
      final companion = TransactionsCompanion(
        type: Value(_type),
        amount: Value(amount),
        note: Value(_noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim()),
        categoryId: Value(
            _type == 'transfer' ? null : _selectedCategory?.id),
        accountId: Value(_selectedAccount!.id),
        toAccountId:
            Value(_type == 'transfer' ? _selectedToAccount?.id : null),
        memberId: Value(_selectedMember?.id),
        date: Value(_date),
        currency: const Value('MYR'),
      );

      final categoryId = _type == 'transfer' ? null : _selectedCategory?.id;
      double previousSpent = 0;
      if (_type == 'expense' && categoryId != null) {
        final spending = await db.getCategorySpending(_date.year, _date.month);
        previousSpent = spending[categoryId] ?? 0;
        if (isEditing && widget.existing!.categoryId == categoryId) {
          previousSpent -= widget.existing!.amount;
        }
      }

      int txnId;
      if (isEditing) {
        txnId = widget.existing!.id;
        await db.updateTransactionWithBalanceUpdate(
            widget.existing!, companion);
      } else {
        txnId = await db.insertTransactionWithBalanceUpdate(companion);
      }
      await db.setTransactionTags(txnId, _tags);
      unawaited(HomeWidgetService.refresh(db));

      if (_type == 'expense' && categoryId != null) {
        await NotificationService.instance.checkBudgetThreshold(
          db: db,
          categoryId: categoryId,
          year: _date.year,
          month: _date.month,
          previousSpent: previousSpent,
          spent: previousSpent + amount,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError('Failed to save: $e');
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('This will also reverse the account balance.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(color: context.colors.expense)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final db = ref.read(databaseProvider);
    await db.deleteTransactionWithBalanceUpdate(widget.existing!);
    unawaited(HomeWidgetService.refresh(db));
    if (mounted) Navigator.of(context).pop();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickCategory(List<Category> cats) async {
    final typeCats = cats.where((c) => c.type == _type).toList();
    final picked = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryPicker(categories: typeCats),
    );
    if (picked != null) setState(() => _selectedCategory = picked);
  }

  Future<void> _pickAccount(List<Account> accounts,
      {bool isToAccount = false}) async {
    final picked = await showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountPicker(
          accounts: accounts,
          excludeId: isToAccount ? _selectedAccount?.id : null),
    );
    if (picked != null) {
      setState(() {
        if (isToAccount) {
          _selectedToAccount = picked;
        } else {
          _selectedAccount = picked;
        }
      });
    }
  }

  Future<void> _pickMember(List<Member> members) async {
    final picked = await showModalBottomSheet<Member>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MemberPicker(members: members),
    );
    if (picked != null) setState(() => _selectedMember = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final membersAsync = ref.watch(membersProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    final accounts = accountsAsync.valueOrNull ?? [];
    final members = membersAsync.valueOrNull ?? [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDefaults(accounts, categories, members);
    });

    final titleColor = _type == 'expense'
        ? context.colors.expense
        : _type == 'income'
            ? context.colors.income
            : context.colors.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: titleColor,
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Type Selector ──────────────────────────────────────────────
          Container(
            color: titleColor,
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                _TypeTab(
                    label: 'Expense',
                    selected: _type == 'expense',
                    onTap: () => setState(() {
                          _type = 'expense';
                          _selectedCategory = null;
                        })),
                const SizedBox(width: 8),
                _TypeTab(
                    label: 'Income',
                    selected: _type == 'income',
                    onTap: () => setState(() {
                          _type = 'income';
                          _selectedCategory = null;
                        })),
                const SizedBox(width: 8),
                _TypeTab(
                    label: 'Transfer',
                    selected: _type == 'transfer',
                    onTap: () => setState(() {
                          _type = 'transfer';
                          _selectedCategory = null;
                        })),
              ],
            ),
          ),

          // ── Amount ────────────────────────────────────────────────────
          Container(
            color: context.colors.surfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'RM',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    autofocus: !isEditing,
                  ),
                ),
              ],
            ),
          ),

          // ── Form Fields ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Category (not for transfer)
                if (_type != 'transfer') ...[
                  _FieldTile(
                    icon: _selectedCategory?.icon ?? '📦',
                    label: 'Category',
                    value: _selectedCategory?.name ?? 'Select category',
                    hasValue: _selectedCategory != null,
                    onTap: () => _pickCategory(categories),
                  ),
                  const SizedBox(height: 10),
                ],

                // Account
                _FieldTile(
                  icon: _selectedAccount?.icon ?? '💵',
                  label: _type == 'transfer' ? 'From account' : 'Account',
                  value: _selectedAccount?.name ?? 'Select account',
                  hasValue: _selectedAccount != null,
                  onTap: () => _pickAccount(accounts),
                ),
                const SizedBox(height: 10),

                // To account (transfer only)
                if (_type == 'transfer') ...[
                  _FieldTile(
                    icon: _selectedToAccount?.icon ?? '🏦',
                    label: 'To account',
                    value:
                        _selectedToAccount?.name ?? 'Select account',
                    hasValue: _selectedToAccount != null,
                    onTap: () => _pickAccount(accounts, isToAccount: true),
                  ),
                  const SizedBox(height: 10),
                ],

                // Date
                _FieldTile(
                  icon: '📅',
                  label: 'Date',
                  value: DateFormatter.formatDate(_date),
                  hasValue: true,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 10),

                // Person
                _FieldTile(
                  icon: _selectedMember?.icon ?? '👤',
                  label: 'For',
                  value: _selectedMember?.name ?? 'Select person',
                  hasValue: _selectedMember != null,
                  onTap: () => _pickMember(members),
                ),
                const SizedBox(height: 10),

                // Note
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Add a note (optional)',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: Text('📝',
                          style: TextStyle(fontSize: 20)),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                ),
                const SizedBox(height: 16),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._tags.map((tag) => Chip(
                          label: Text(tag, style: const TextStyle(fontSize: 12)),
                          onDeleted: () => _removeTag(tag),
                          backgroundColor: context.colors.primarySurface,
                          deleteIconColor: context.colors.primary,
                          labelStyle: TextStyle(color: context.colors.primary),
                          side: BorderSide.none,
                        )),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _tagInputController,
                        decoration: const InputDecoration(
                          hintText: '+ Add tag',
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: _addTag,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: titleColor),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            isEditing ? 'Save Changes' : 'Save Transaction',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Type Tab ──────────────────────────────────────────────────────────────────

class _TypeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeTab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : context.colors.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? context.colors.primary : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Field Tile ────────────────────────────────────────────────────────────────

class _FieldTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final bool hasValue;
  final VoidCallback onTap;

  const _FieldTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: context.colors.textHint, fontSize: 11)),
                  Text(
                    value,
                    style: TextStyle(
                      color: hasValue
                          ? context.colors.textPrimary
                          : context.colors.textHint,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: context.colors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Category Picker ───────────────────────────────────────────────────────────

class _CategoryPicker extends StatelessWidget {
  final List<Category> categories;
  const _CategoryPicker({required this.categories});

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
          Text('Select Category',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              return GestureDetector(
                onTap: () => Navigator.pop(context, cat),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(cat.icon,
                            style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cat.name,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Member Picker ─────────────────────────────────────────────────────────────

class _MemberPicker extends StatelessWidget {
  final List<Member> members;
  const _MemberPicker({required this.members});

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
          Text('Who is this for?',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          ...members.map((m) => ListTile(
                leading: Text(m.icon, style: const TextStyle(fontSize: 24)),
                title: Text(m.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, m),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Account Picker ────────────────────────────────────────────────────────────

class _AccountPicker extends StatelessWidget {
  final List<Account> accounts;
  final int? excludeId;
  const _AccountPicker({required this.accounts, this.excludeId});

  @override
  Widget build(BuildContext context) {
    final filtered = accounts
        .where((a) => a.id != excludeId && !a.isArchived)
        .toList();
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
          Text('Select Account',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          ...filtered.map((a) => ListTile(
                leading: Text(a.icon,
                    style: const TextStyle(fontSize: 24)),
                title: Text(a.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    CurrencyFormatter.format(a.balance),
                    style: TextStyle(color: context.colors.textSecondary)),
                onTap: () => Navigator.pop(context, a),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
