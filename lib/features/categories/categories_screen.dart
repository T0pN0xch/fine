import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/theme/app_theme.dart';
import '../../data/database/app_database.dart';
import '../../providers/providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'Expense'), Tab(text: 'Income')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryForm(context, null,
            _tabController.index == 0 ? 'expense' : 'income'),
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          final expense = all.where((c) => c.type == 'expense').toList();
          final income = all.where((c) => c.type == 'income').toList();
          return TabBarView(
            controller: _tabController,
            children: [
              _CategoryList(
                  categories: expense,
                  onTap: (c) => _showCategoryForm(context, c, 'expense')),
              _CategoryList(
                  categories: income,
                  onTap: (c) => _showCategoryForm(context, c, 'income')),
            ],
          );
        },
      ),
    );
  }

  void _showCategoryForm(
      BuildContext context, Category? existing, String type) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          _CategoryFormScreen(existing: existing, defaultType: type),
    ));
  }
}

class _CategoryList extends StatelessWidget {
  final List<Category> categories;
  final void Function(Category) onTap;
  const _CategoryList({required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 48, color: context.colors.textHint),
            const SizedBox(height: 12),
            Text('No categories yet',
                style: TextStyle(color: context.colors.textSecondary)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        final color = AppColors.categoryColors[
            cat.colorIndex % AppColors.categoryColors.length];
        return GestureDetector(
          onTap: () => onTap(cat),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Center(
                    child: Text(cat.icon,
                        style: const TextStyle(fontSize: 26))),
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
    );
  }
}

// ── Category Form ─────────────────────────────────────────────────────────────

class _CategoryFormScreen extends ConsumerStatefulWidget {
  final Category? existing;
  final String defaultType;
  const _CategoryFormScreen({this.existing, required this.defaultType});

  @override
  ConsumerState<_CategoryFormScreen> createState() =>
      _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<_CategoryFormScreen> {
  late TextEditingController _nameCtrl;
  late String _icon;
  late int _colorIndex;
  late String _type;
  bool _saving = false;

  static const _icons = [
    '🍔', '🚗', '🛍️', '⚡', '💊', '🎬', '📚', '✈️', '🛒', '🏠',
    '💼', '💻', '🏪', '📈', '🎁', '💰', '📦', '🏋️', '🎵', '🌿',
    '☕', '🍕', '🏥', '📱', '🎮', '🌍', '🐾', '🎓', '🔧', '🎯',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _icon = e?.icon ?? '📦';
    _colorIndex = e?.colorIndex ?? 0;
    _type = e?.type ?? widget.defaultType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    try {
      final companion = CategoriesCompanion(
        name: Value(_nameCtrl.text.trim()),
        icon: Value(_icon),
        colorIndex: Value(_colorIndex),
        type: Value(_type),
        isDefault: const Value(false),
      );
      if (widget.existing != null) {
        await db.updateCategory(
            companion.copyWith(id: Value(widget.existing!.id)));
      } else {
        await db.insertCategory(companion);
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
        title: const Text('Delete category?'),
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
    await ref.read(databaseProvider).deleteCategory(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        AppColors.categoryColors[_colorIndex % AppColors.categoryColors.length];

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.existing != null ? 'Edit Category' : 'Add Category'),
        actions: [
          if (widget.existing != null && !widget.existing!.isDefault)
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Preview
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selectedColor.withOpacity(0.5), width: 2),
                  ),
                  child: Center(
                      child:
                          Text(_icon, style: const TextStyle(fontSize: 40))),
                ),
                const SizedBox(height: 8),
                Text(_nameCtrl.text.isEmpty ? 'Category name' : _nameCtrl.text,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Icon picker
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
                        ? Border.all(color: selectedColor, width: 2)
                        : null,
                  ),
                  child: Center(
                      child:
                          Text(ic, style: const TextStyle(fontSize: 22))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Name
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Category name'),
          ),
          const SizedBox(height: 16),

          // Color
          Text('Color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(AppColors.categoryColors.length, (i) {
              final sel = _colorIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _colorIndex = i),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.categoryColors[i],
                    shape: BoxShape.circle,
                    border: sel
                        ? Border.all(color: Colors.black26, width: 3)
                        : null,
                  ),
                  child: sel
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }),
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
                      : 'Add Category'),
            ),
          ),
        ],
      ),
    );
  }
}
