import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/inventory/domain/entities/item.dart';
import 'package:shop_ledger/features/inventory/presentation/providers/inventory_provider.dart';

class LowStockSettingsPage extends ConsumerStatefulWidget {
  const LowStockSettingsPage({super.key});

  @override
  ConsumerState<LowStockSettingsPage> createState() =>
      _LowStockSettingsPageState();
}

class _LowStockSettingsPageState extends ConsumerState<LowStockSettingsPage> {
  String _selectedFilter = 'All';
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Low Stock Thresholds',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: inventoryState.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: context.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items in inventory',
                    style: GoogleFonts.inter(
                      color: context.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // Filter items by unit
          final filteredItems = _selectedFilter == 'All'
              ? items
              : items.where((item) => item.unit == _selectedFilter).toList();

          // Group items by unit
          final groupedItems = <String, List<Item>>{};
          for (var item in filteredItems) {
            groupedItems.putIfAbsent(item.unit, () => []).add(item);
          }

          return Column(
            children: [
              // Filter chips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  border: Border(
                    bottom: BorderSide(color: context.borderColor),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('kg'),
                      const SizedBox(width: 8),
                      _buildFilterChip('box'),
                      const SizedBox(width: 8),
                      _buildFilterChip('piece'),
                      const SizedBox(width: 8),
                      _buildFilterChip('liter'),
                    ],
                  ),
                ),
              ),

              // Items list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedItems.length,
                  itemBuilder: (context, groupIndex) {
                    final unit = groupedItems.keys.elementAt(groupIndex);
                    final unitItems = groupedItems[unit]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (groupIndex > 0) const SizedBox(height: 24),

                        // Unit header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                _getUnitIcon(unit),
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getUnitLabel(unit),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${unitItems.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Items in this unit
                        ...unitItems
                            .map((item) => _buildItemCard(item))
                            .toList(),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: GoogleFonts.inter(color: context.textMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.subtleBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.borderColor,
          ),
        ),
        child: Text(
          label == 'All' ? 'All Items' : _getUnitLabel(label),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : context.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    final itemId = item.id!;
    if (!_controllers.containsKey(itemId)) {
      _controllers[itemId] = TextEditingController(
        text: item.lowStockThreshold?.toStringAsFixed(0) ?? '10',
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStockStatusColor(item).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Stock: ${item.totalQuantity?.toStringAsFixed(1) ?? '0'} ${item.unit}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getStockStatusColor(item),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _controllers[itemId],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: context.subtleBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    hintText: '10',
                    hintStyle: GoogleFonts.inter(
                      color: context.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (value) async {
                    final threshold = double.tryParse(value);
                    if (threshold != null) {
                      try {
                        await ref
                            .read(inventoryProvider.notifier)
                            .updateItemLowStockThreshold(itemId, threshold);

                        // Show success feedback
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Threshold updated to $threshold'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        // Show error feedback
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStockStatusColor(Item item) {
    final stock = item.totalQuantity ?? 0;
    final threshold = item.lowStockThreshold ?? 10;

    if (stock <= 0) {
      return Colors.red;
    } else if (stock <= threshold) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  IconData _getUnitIcon(String unit) {
    switch (unit.toLowerCase()) {
      case 'kg':
        return Icons.scale_outlined;
      case 'box':
        return Icons.inventory_2_outlined;
      case 'piece':
        return Icons.apps_outlined;
      case 'liter':
        return Icons.water_drop_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  String _getUnitLabel(String unit) {
    switch (unit.toLowerCase()) {
      case 'kg':
        return 'Kilograms';
      case 'box':
        return 'Boxes';
      case 'piece':
        return 'Pieces';
      case 'liter':
        return 'Liters';
      default:
        return unit;
    }
  }
}
