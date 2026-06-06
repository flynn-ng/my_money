import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/data/auth_repository.dart';
import '../data/category_model.dart';
import '../data/transaction_repository.dart';

// Preset color palette for category colors
const _colorSwatches = [
  '#EF4444', '#F97316', '#EAB308', '#22C55E',
  '#14B8A6', '#3B82F6', '#8B5CF6', '#EC4899',
  '#78716C', '#0EA5E9', '#84CC16', '#F43F5E',
];


class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  Future<void> _showCategoryForm({CategoryModel? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(existing: existing),
    );
    ref.invalidate(categoriesProvider);
  }

  Future<void> _confirmDelete(CategoryModel cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(S.deleteCategoryTitle),
        content: Text(S.deleteCategoryContent(cat.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(S.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await ref.read(transactionRepositoryProvider).deleteCategory(cat.id);
        ref.invalidate(categoriesProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad(context), 20, hPad(context), 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(S.manageCategories,
                        style: AppTextStyles.titleLarge),
                  ),
                  FilledButton.icon(
                    onPressed: _showCategoryForm,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(S.addCategory),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.amber)),
                error: (e, _) => Center(child: Text(friendlyError(e))),
                data: (cats) {
                  if (cats.isEmpty) {
                    return Center(
                      child: Text(S.noTransactions,
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary)),
                    );
                  }

                  final income = cats
                      .where((c) => c.type == 'income' || c.type == 'both')
                      .toList();
                  final expense = cats
                      .where((c) => c.type == 'expense' || c.type == 'both')
                      .toList();

                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                        hPad(context), 8, hPad(context), 32),
                    children: [
                      if (income.isNotEmpty) ...[
                        _SectionHeader(S.income),
                        _CategoryCard(
                          categories: income,
                          onEdit: (c) => _showCategoryForm(existing: c),
                          onDelete: _confirmDelete,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (expense.isNotEmpty) ...[
                        _SectionHeader(S.expense),
                        _CategoryCard(
                          categories: expense,
                          onEdit: (c) => _showCategoryForm(existing: c),
                          onDelete: _confirmDelete,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: AppTextStyles.titleMedium),
      );
}

class _CategoryCard extends StatelessWidget {
  final List<CategoryModel> categories;
  final void Function(CategoryModel) onEdit;
  final void Function(CategoryModel) onDelete;
  const _CategoryCard(
      {required this.categories, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < categories.length; i++) ...[
            if (i > 0)
              const Padding(
                  padding: EdgeInsets.only(left: 58),
                  child: Divider(height: 1)),
            _CategoryRow(
              category: categories[i],
              onEdit: () => onEdit(categories[i]),
              onDelete: () => onDelete(categories[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CategoryRow(
      {required this.category, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: category.colorValue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: category.iconWidget(size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(category.name, style: AppTextStyles.bodyLarge),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: AppColors.textSecondary),
            onPressed: onEdit,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.red),
            onPressed: onDelete,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ── Add / Edit form bottom sheet ──────────────────────────────────────────────

class _CategoryFormSheet extends ConsumerStatefulWidget {
  final CategoryModel? existing;
  const _CategoryFormSheet({this.existing});

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _iconTabController;
  final _nameController = TextEditingController();
  final _emojiController = TextEditingController();
  bool _loading = false;

  String _selectedColor = _colorSwatches.first;
  String _selectedIcon = '🛒';
  String _selectedType = 'expense';
  bool _useEmoji = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _iconTabController = TabController(length: 2, vsync: this);
    if (_isEditing) {
      final cat = widget.existing!;
      _nameController.text = cat.name;
      _selectedColor = cat.color;
      _selectedType = cat.type;
      _useEmoji = cat.isEmoji;
      _selectedIcon = cat.icon;
      if (cat.isEmoji) {
        _emojiController.text = cat.icon;
      }
      _iconTabController.index = cat.isEmoji ? 0 : 1;
    }
    _iconTabController.addListener(() {
      if (!_iconTabController.indexIsChanging) {
        setState(() => _useEmoji = _iconTabController.index == 0);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    _iconTabController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.categoryNameHint)),
      );
      return;
    }

    final icon = _useEmoji
        ? (_emojiController.text.trim().isEmpty ? _selectedIcon : _emojiController.text.trim())
        : _selectedIcon;

    setState(() => _loading = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      if (_isEditing) {
        await repo.updateCategory(
          widget.existing!.id,
          name: name,
          icon: icon,
          color: _selectedColor,
          type: _selectedType,
        );
      } else {
        final profile = await ref.read(currentProfileProvider.future);
        final cats = await repo.getCategories(profile!.householdId!);
        await repo.createCategory(
          householdId: profile.householdId!,
          name: name,
          icon: icon,
          color: _selectedColor,
          type: _selectedType,
          sortOrder: cats.length,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(friendlyError(e)),
              backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorValue = CategoryModel(
      id: '', householdId: '', name: '', icon: '',
      color: _selectedColor, type: '', sortOrder: 0,
    ).colorValue;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? S.editCategory : S.addCategory,
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name field
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: S.categoryNameHint,
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Type selector
                    Text(S.category, style: AppTextStyles.labelSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final t in ['expense', 'income', 'both'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_typeLabel(t)),
                              selected: _selectedType == t,
                              onSelected: (_) =>
                                  setState(() => _selectedType = t),
                              selectedColor: AppColors.black,
                              labelStyle: TextStyle(
                                color: _selectedType == t
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Color swatches
                    Text(S.categoryNameHint, style: AppTextStyles.labelSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _colorSwatches.map((hex) {
                        final c = CategoryModel(
                          id: '', householdId: '', name: '', icon: '',
                          color: hex, type: '', sortOrder: 0,
                        ).colorValue;
                        final selected = _selectedColor == hex;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = hex),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? AppColors.black
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: selected
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Icon picker — emoji tab + material icon tab
                    Text(S.categoryIconHint, style: AppTextStyles.labelSmall),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _iconTabController,
                            labelColor: AppColors.black,
                            unselectedLabelColor: AppColors.textSecondary,
                            indicatorColor: AppColors.black,
                            indicatorWeight: 2,
                            labelStyle: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                            unselectedLabelStyle: AppTextStyles.bodyMedium,
                            tabs: const [
                              Tab(text: S.categoryEmojiTab),
                              Tab(text: S.categoryIconTab),
                            ],
                          ),
                          SizedBox(
                            height: 160,
                            child: TabBarView(
                              controller: _iconTabController,
                              children: [
                                // Emoji tab
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(S.categoryIconHint,
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                  color:
                                                      AppColors.textSecondary)),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _emojiController,
                                        decoration: InputDecoration(
                                          hintText: '📦',
                                          prefixIcon: _emojiController
                                                  .text.isNotEmpty
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: Text(
                                                    _emojiController.text,
                                                    style: const TextStyle(
                                                        fontSize: 22),
                                                  ),
                                                )
                                              : null,
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ],
                                  ),
                                ),
                                // Material icons tab
                                GridView.builder(
                                  padding: const EdgeInsets.all(12),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 6,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: kMatIcons.length,
                                  itemBuilder: (_, i) {
                                    final entry =
                                        kMatIcons.entries.elementAt(i);
                                    final isSelected =
                                        _selectedIcon == entry.key;
                                    return GestureDetector(
                                      onTap: () => setState(
                                          () => _selectedIcon = entry.key),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 120),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? colorValue.withValues(alpha: 0.15)
                                              : AppColors.cream,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected
                                                ? colorValue
                                                : Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          entry.value,
                                          size: 22,
                                          color: isSelected
                                              ? colorValue
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save button
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.black,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_isEditing ? S.update : S.save,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'income':
        return S.categoryTypeIncome;
      case 'expense':
        return S.categoryTypeExpense;
      default:
        return S.categoryTypeBoth;
    }
  }
}
