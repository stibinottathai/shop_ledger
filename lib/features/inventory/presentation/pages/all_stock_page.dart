import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/inventory/domain/entities/item.dart';
import 'package:shop_ledger/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:shop_ledger/features/inventory/presentation/widgets/stock_item_card.dart';

class AllStockPage extends ConsumerStatefulWidget {
  const AllStockPage({super.key});

  @override
  ConsumerState<AllStockPage> createState() => _AllStockPageState();
}

class _AllStockPageState extends ConsumerState<AllStockPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Low Stock', 'Out of Stock'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _deleteItem(String id) async {
    try {
      await ref.read(inventoryProvider.notifier).deleteItem(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllItems() async {
    try {
      await ref.read(inventoryProvider.notifier).deleteAllItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All terms deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting all items: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showDeleteAllConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete All Stock?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This will permanently delete ALL items from your inventory. This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.slate500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAllItems();
            },
            child: Text(
              'Delete All',
              style: GoogleFonts.inter(
                color: AppColors.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFC),
              border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.slate100),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.textMain,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'All Items',
                      style: GoogleFonts.inter(
                        color: AppColors.textMain,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.slate100),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.textMain,
                      size: 20,
                    ),
                    elevation: 4,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'deleteAll') {
                        _showDeleteAllConfirm();
                      }
                    },
                    itemBuilder: (context) {
                      final items = itemsAsync.value ?? [];
                      final hasItems = items.isNotEmpty;
                      return [
                        PopupMenuItem(
                          value: 'deleteAll',
                          enabled: hasItems,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: hasItems
                                      ? AppColors.danger.withOpacity(0.1)
                                      : AppColors.slate100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delete_forever,
                                  color: hasItems
                                      ? AppColors.danger
                                      : AppColors.slate400,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Delete All Stock',
                                style: GoogleFonts.inter(
                                  color: hasItems
                                      ? AppColors.textMain
                                      : AppColors.slate400,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.05),
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.01),
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                      ),
                      TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });
                        },
                        style: GoogleFonts.inter(
                          color: AppColors.textMain,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.slate400,
                            size: 20,
                          ),
                          hintText: 'Search items...',
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.slate400,
                          ),
                          border: InputBorder.none,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 2.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Content with Filters
                  Expanded(
                    child: itemsAsync.when(
                      data: (items) {
                        // Calculate counts
                        final lowStockCount = items
                            .where(
                              (i) =>
                                  (i.totalQuantity ?? 0) > 0 &&
                                  (i.totalQuantity ?? 0) < 5,
                            )
                            .length;
                        final outOfStockCount = items
                            .where((i) => (i.totalQuantity ?? 0) <= 0)
                            .length;

                        // Filter items
                        final filteredItems = items.where((item) {
                          // Search check
                          final query = _searchQuery.toLowerCase();
                          final matchesSearch =
                              item.name.toLowerCase().contains(query) ||
                              (item.barcode != null &&
                                  item.barcode!.contains(query));
                          if (!matchesSearch) return false;

                          // Filter check
                          if (_selectedFilter == 'Low Stock') {
                            return (item.totalQuantity ?? 0) > 0 &&
                                (item.totalQuantity ?? 0) < 5;
                          } else if (_selectedFilter == 'Out of Stock') {
                            return (item.totalQuantity ?? 0) <= 0;
                          }
                          return true;
                        }).toList();

                        return Column(
                          children: [
                            // Filter Chips Row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('All Items', true),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    'Low Stock',
                                    false,
                                    count: lowStockCount,
                                    isWarning: true,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    'Out of Stock',
                                    false,
                                    count: outOfStockCount,
                                    isDanger: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Results Header if filtering
                            if (_searchQuery.isNotEmpty ||
                                _selectedFilter != 'All')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Text(
                                      'Results (${filteredItems.length})',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            Expanded(
                              child: filteredItems.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No items found',
                                        style: GoogleFonts.inter(
                                          color: AppColors.slate500,
                                        ),
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: () =>
                                          ref.refresh(inventoryProvider.future),
                                      child: ListView.separated(
                                        padding: const EdgeInsets.only(
                                          bottom: 20,
                                        ),
                                        itemCount: filteredItems.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final item = filteredItems[index];
                                          // ... existing item builder ...
                                          return _buildItemWithDismiss(item);
                                        },
                                      ),
                                    ),
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemWithDismiss(Item item) {
    return Dismissible(
      key: Key(item.id ?? item.name),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'Delete Item',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text('Are you sure you want to delete "${item.name}"?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  'Delete',
                  style: GoogleFonts.inter(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _deleteItem(item.id!),
      child: StockItemCard(
        item: item,
        onTap: () {
          // Reuse edit logic or placeholder
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Editing from 'View All' coming soon"),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isDefault, {
    int? count,
    bool isWarning = false,
    bool isDanger = false,
  }) {
    final isSelected =
        _selectedFilter == (label == 'All Items' ? 'All' : label);
    Color getBgColor() {
      if (isSelected) return AppColors.primary;
      if (isDanger) return AppColors.danger.withOpacity(0.1);
      if (isWarning) return AppColors.orange400.withOpacity(0.1);
      return AppColors.slate50;
    }

    Color getTextColor() {
      if (isSelected) return Colors.white;
      if (isDanger) return AppColors.danger;
      if (isWarning) return AppColors.orange400;
      return AppColors.slate600;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label == 'All Items' ? 'All' : label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: getBgColor(),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDanger
                      ? AppColors.danger.withOpacity(0.2)
                      : AppColors.slate200),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: getTextColor(),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : getTextColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
