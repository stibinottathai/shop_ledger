import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/inventory/domain/entities/item.dart';
import 'package:shop_ledger/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shop_ledger/features/inventory/presentation/widgets/stock_item_card.dart';

class ManageStockPage extends ConsumerStatefulWidget {
  const ManageStockPage({super.key});

  @override
  ConsumerState<ManageStockPage> createState() => _ManageStockPageState();
}

class _ManageStockPageState extends ConsumerState<ManageStockPage> {
  // Form handling
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _barcodeController = TextEditingController();
  bool _isSaving = false;

  // Search
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Unit Selection
  String _selectedUnit = 'kg'; // Default

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _sellingPriceController.dispose();
    _qtyController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode(StateSetter setSheetState) async {
    final controller = MobileScannerController();
    bool hasScanned = false;

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Scan Barcode')),
          body: MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (hasScanned) return; // Prevent multiple scans

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !hasScanned) {
                  hasScanned = true;
                  controller.stop();
                  Navigator.pop(context, barcode.rawValue);
                  return;
                }
              }
            },
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      setSheetState(() {
        _barcodeController.text = result;
      });

      // Smart Lookup: Check if item with this barcode already exists
      try {
        final existingItem = await ref
            .read(inventoryProvider.notifier)
            .getItemByBarcode(result);

        if (existingItem != null && mounted) {
          // Auto-fill name and price from existing item
          setSheetState(() {
            _nameController.text = existingItem.name;
            _sellingPriceController.text = existingItem.pricePerKg.toString();
            _selectedUnit = existingItem.unit;
            // Don't auto-fill quantity - user will add new quantity
            _qtyController.clear();
          });

          // Show feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Found: ${existingItem.name} - Just add quantity!',
                ),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        // If lookup fails, just continue with manual entry
        // (User can still enter details manually)
      }
    }
  }

  void _showItemForm([Item? item]) {
    _nameController.text = item?.name ?? '';
    _sellingPriceController.text = item?.pricePerKg.toString() ?? '';
    _qtyController.text = item?.totalQuantity?.toString() ?? '';
    _barcodeController.text = item?.barcode ?? '';
    _selectedUnit = ['kg', 'pcs', 'l', 'box'].contains(item?.unit)
        ? item!.unit
        : 'kg';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.isDarkMode ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item != null ? 'Edit Stock Item' : 'Add New Item',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          if (item != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.danger,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showDeleteConfirm(item);
                                },
                              ),
                            ),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: context.isDarkMode
                                    ? AppColors.surfaceDark
                                    : AppColors.slate50,
                                shape: BoxShape.circle,
                                border: Border.all(color: context.borderColor),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: context.textPrimary,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Item Name
                        _buildInputField(
                          controller: _nameController,
                          label: 'Item Name',
                          hint: 'e.g., Golden Apple',
                          icon: Icons.inventory_2_outlined,
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        // 2. Barcode
                        _buildInputField(
                          controller: _barcodeController,
                          label: 'Barcode (Optional)',
                          hint: 'Scan or enter barcode',
                          icon: Icons.qr_code_scanner,
                          suffix: IconButton(
                            icon: const Icon(Icons.center_focus_weak),
                            onPressed: () => _scanBarcode(setSheetState),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3. Unit Selection Dropdown
                        Text(
                          'Unit Type',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.slate200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.slate200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'box', child: Text('Box')),
                            DropdownMenuItem(
                              value: 'l',
                              child: Text('Liter (l)'),
                            ),
                            DropdownMenuItem(
                              value: 'kg',
                              child: Text('Kilogram (kg)'),
                            ),
                            DropdownMenuItem(
                              value: 'pcs',
                              child: Text('Pieces (pcs)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => _selectedUnit = val);
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // 4. Price and Quantity
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                controller: _sellingPriceController,
                                label: 'Price (₹/${_selectedUnit})',
                                hint: '0.00',
                                icon: Icons.currency_rupee,
                                inputType: TextInputType.number,
                                validator: (val) {
                                  if (val == null || val.isEmpty)
                                    return 'Required';
                                  if (double.tryParse(val) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInputField(
                                controller: _qtyController,
                                label: 'Quantity (${_selectedUnit})',
                                hint: '0.00',
                                icon: Icons.scale_outlined,
                                inputType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    if (!_formKey.currentState!.validate())
                                      return;

                                    setSheetState(
                                      () => _isSaving = true,
                                    ); // Use local setState

                                    final name = _nameController.text.trim();
                                    final barcode =
                                        _barcodeController.text.trim().isEmpty
                                        ? null
                                        : _barcodeController.text.trim();
                                    final price =
                                        double.tryParse(
                                          _sellingPriceController.text.trim(),
                                        ) ??
                                        0.0;
                                    final qty =
                                        _qtyController.text.trim().isNotEmpty
                                        ? double.tryParse(
                                            _qtyController.text.trim(),
                                          )
                                        : null;

                                    try {
                                      if (item != null) {
                                        final updated = item.copyWith(
                                          name: name,
                                          pricePerKg: price,
                                          totalQuantity: qty,
                                          unit: _selectedUnit,
                                          barcode: barcode,
                                        );
                                        await ref
                                            .read(inventoryProvider.notifier)
                                            .updateItem(updated);
                                      } else {
                                        await ref
                                            .read(inventoryProvider.notifier)
                                            .addItem(
                                              name,
                                              price,
                                              qty,
                                              unit: _selectedUnit,
                                              barcode: barcode,
                                            );
                                      }
                                      if (mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              item != null
                                                  ? 'Item updated successfully'
                                                  : 'Item added successfully',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: AppColors.textMain,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: AppColors.danger,
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setSheetState(() => _isSaving = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    item != null ? 'Update Item' : 'Add Item',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: context.textPrimary,
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: context.textMuted),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }

  Future<void> _deleteItem(String id) async {
    try {
      await ref.read(inventoryProvider.notifier).deleteItem(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
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
    final isDark = context.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: Text(
          'Delete All Stock?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        content: Text(
          'This will permanently delete ALL items from your inventory. This action cannot be undone.',
          style: TextStyle(color: context.textMuted),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: context.textMuted,
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

  void _showDeleteConfirm(Item item) {
    final isDark = context.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        title: Text(
          'Delete Item',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${item.name}"?',
          style: TextStyle(color: context.textMuted),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: context.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteItem(item.id!);
            },
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
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: context.appBarBackground,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              16,
            ),
            decoration: BoxDecoration(color: context.appBarBackground),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Text(
                          'Inventory',
                          style: GoogleFonts.inter(
                            color: context.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? AppColors.surfaceDark
                        : AppColors.slate50,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.borderColor),
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
                    icon: Icon(
                      Icons.more_vert,
                      color: context.textPrimary,
                      size: 20,
                    ),
                    elevation: 4,
                    color: context.cardColor,
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
                                      ? AppColors.danger.withAlpha(26)
                                      : this.context.isDarkMode
                                      ? AppColors.surfaceDark
                                      : AppColors.slate100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delete_forever,
                                  color: hasItems
                                      ? AppColors.danger
                                      : this.context.textMuted,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Delete All Stock',
                                style: GoogleFonts.inter(
                                  color: hasItems
                                      ? this.context.textPrimary
                                      : this.context.textMuted,
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
                  // Search Bar
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: context.cardColor,
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
                          color: context.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search,
                            color: context.textMuted,
                            size: 20,
                          ),
                          hintText: 'Search items...',
                          hintStyle: GoogleFonts.inter(
                            color: context.textMuted,
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
                            borderSide: BorderSide(
                              color: context.borderColor,
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
                  const SizedBox(height: 24),

                  // Content
                  Expanded(
                    child: itemsAsync.when(
                      data: (items) {
                        // 1. Calculate Stats
                        final totalItems = items.length;
                        final totalValue = items.fold(0.0, (sum, item) {
                          return sum +
                              (item.pricePerKg * (item.totalQuantity ?? 0));
                        });
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

                        // 2. Filter Items (Only Search + Limit 5)
                        final filteredItems = items
                            .where((item) {
                              final matchesSearch = item.name
                                  .toLowerCase()
                                  .contains(_searchQuery);
                              return matchesSearch;
                            })
                            .take(5)
                            .toList();

                        return Column(
                          children: [
                            // Hero Summary Card
                            _buildHeroSummaryCard(
                              totalValue,
                              totalItems,
                              lowStockCount,
                              outOfStockCount,
                            ),
                            const SizedBox(height: 24),

                            // Filter Chips Removed

                            // List Header
                            if (_searchQuery.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Text(
                                      'Results (${filteredItems.length})',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: context.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Stock Items',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          context.push('/inventory/all'),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            'View All',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 12,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // List
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: () =>
                                    ref.refresh(inventoryProvider.future),
                                child: items.isEmpty
                                    ? _buildEmptyState()
                                    : filteredItems.isEmpty
                                    ? _buildNoSearchResults()
                                    : ListView.separated(
                                        padding: const EdgeInsets.only(
                                          bottom: 100,
                                        ),
                                        itemCount: filteredItems.length,
                                        separatorBuilder: (ctx, i) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (ctx, index) {
                                          final item = filteredItems[index];
                                          return Dismissible(
                                            key: Key(item.id ?? item.name),
                                            direction:
                                                DismissDirection.endToStart,
                                            background: Container(
                                              alignment: Alignment.centerRight,
                                              padding: const EdgeInsets.only(
                                                right: 20,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.danger,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.white,
                                              ),
                                            ),
                                            confirmDismiss: (direction) async {
                                              // Reuse existing delete dialog logic logic if needed or reimplement
                                              // For brevity reusing logic via existing method calls if possible
                                              // But to allow simple copy paste I will write a simple one here or Assume _showDeleteConfirm works?
                                              // _showDeleteConfirm is void.
                                              // Re-implementing quick confirm:
                                              return await showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: Text(
                                                    'Delete Item',
                                                    style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  content: Text(
                                                    'Delete "${item.name}"?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            ctx,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            ctx,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            onDismissed: (_) =>
                                                _deleteItem(item.id!),
                                            child: StockItemCard(
                                              item: item,
                                              onTap: () => _showItemForm(item),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Center(child: Text('Error: $e')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24, right: 24),
        child: SizedBox(
          width: 56,
          height: 56,
          child: FloatingActionButton(
            heroTag: 'manage_stock_add_fab',
            onPressed: () => _showItemForm(),
            backgroundColor: AppColors.primary,
            elevation: 0,
            shape: const CircleBorder(),
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    offset: Offset(0, 10),
                    blurRadius: 15,
                    spreadRadius: -3,
                  ),
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.025),
                    offset: Offset(0, 4),
                    blurRadius: 6,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: AppColors.slate300),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: GoogleFonts.inter(
              color: AppColors.slate500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSummaryCard(
    double totalValue,
    int totalItems,
    int lowStock,
    int outOfStock,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL STOCK VALUE',
            style: GoogleFonts.inter(
              color: context.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹ ${totalValue.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              color: context.isDarkMode ? Colors.white : AppColors.primary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildCompactStat(
                Icons.inventory_2_outlined,
                '$totalItems Items',
                context.textPrimary,
              ),
              const SizedBox(width: 24),
              _buildCompactStat(
                Icons.warning_amber_rounded,
                '$lowStock Low Stock',
                AppColors.accentOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Removed _buildFilterChip as it is no longer used here

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.slate300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Items in Stock',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first item to start tracking\nyour inventory.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.slate500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // _buildItemCard removed as it was unused and implemented inline
}
