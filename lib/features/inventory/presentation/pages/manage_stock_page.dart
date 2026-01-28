import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/inventory/domain/entities/item.dart';
import 'package:shop_ledger/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  bool _isSearching = false;
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
      backgroundColor: Colors.white,
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
                          color: AppColors.textMain,
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
                                color: AppColors.slate50,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.slate200),
                              ),
                              child: const Icon(Icons.close, size: 18),
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
                            color: AppColors.slate600,
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
            color: AppColors.slate600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: AppColors.textMain,
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppColors.slate400),
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

  void _showDeleteConfirm(Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Item',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text('Are you sure you want to delete "${item.name}"?'),
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
      backgroundColor: const Color(0xFFF1F5F9), // Light grey background
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  hintStyle: GoogleFonts.inter(color: AppColors.slate400),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.inter(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              )
            : Text(
                'Inventory',
                style: GoogleFonts.inter(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: AppColors.slate500,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.slate500),
            color: Colors.white,
            elevation: 4,
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
          const SizedBox(width: 8),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          // Filter items based on search query
          final filteredItems = items.where((item) {
            return item.name.toLowerCase().contains(_searchQuery);
          }).toList();

          // Calculate summary (based on ALL items, or filtered? Usually all items makes sense for dashboard stats, but filtered for list view.
          // Let's keep summary for ALL items as it is "Total Stock" summary).
          final totalItems = items.length;
          final totalValue = items.fold(0.0, (sum, item) {
            return sum + (item.pricePerKg * (item.totalQuantity ?? 0));
          });

          return Column(
            children: [
              // Summary Section (Hide when searching to give more space? Or keep it? Let's keep it for now)
              if (!_isSearching)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.03),
                        offset: Offset(0, 10),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        'Total Items',
                        totalItems.toString(),
                        Icons.inventory_2,
                        AppColors.primary,
                        AppColors.emerald50,
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryCard(
                        'Total Value',
                        '₹${totalValue.toStringAsFixed(0)}',
                        Icons.currency_rupee,
                        AppColors.orange400,
                        const Color(0xFFFFF7ED),
                      ),
                    ],
                  ),
                ),

              // List Section
              Expanded(
                child: filteredItems.isEmpty
                    ? (items.isEmpty
                          ? _buildEmptyState()
                          : _buildNoSearchResults())
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredItems.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
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
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(
                                    'Delete Item',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete "${item.name}"?',
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.inter(
                                          color: AppColors.slate500,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
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
                            onDismissed: (direction) {
                              _deleteItem(item.id!);
                            },
                            child: _buildItemCard(item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemForm(),
        backgroundColor: AppColors.primary,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Item',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
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

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildItemCard(Item item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showItemForm(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate100),
                  ),
                  child: Center(
                    child: Text(
                      item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.currency_rupee,
                            size: 14,
                            color: AppColors.slate500,
                          ),
                          Text(
                            '${item.pricePerKg.toStringAsFixed(2)} / ${item.unit == 'pcs' ? 'pc' : item.unit}',
                            style: GoogleFonts.inter(
                              color: AppColors.slate500,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Qty Badge
                if (item.totalQuantity != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.emerald200.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.totalQuantity}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.emerald600,
                          ),
                        ),
                        Text(
                          item.unit.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                            color: AppColors.emerald600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
