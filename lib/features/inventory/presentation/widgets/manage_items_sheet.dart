import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/inventory/domain/entities/item.dart';
import 'package:shop_ledger/features/inventory/presentation/providers/inventory_provider.dart';

class ManageItemsSheet extends ConsumerStatefulWidget {
  const ManageItemsSheet({super.key});

  @override
  ConsumerState<ManageItemsSheet> createState() => _ManageItemsSheetState();
}

class _ManageItemsSheetState extends ConsumerState<ManageItemsSheet> {
  bool _isAdding = false;

  // Edit mode
  Item? _itemToEdit;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();

  void _resetForm() {
    _nameController.clear();
    _priceController.clear();
    _qtyController.clear();
    setState(() {
      _isAdding = false;
      _itemToEdit = null;
    });
  }

  void _startAdd() {
    setState(() {
      _isAdding = true;
      _itemToEdit = null;
      _nameController.clear();
      _priceController.clear();
      _qtyController.clear();
    });
  }

  void _startEdit(Item item) {
    setState(() {
      _isAdding = true;
      _itemToEdit = item;
      _nameController.text = item.name;
      _priceController.text = item.pricePerKg.toString();
      _qtyController.text = item.totalQuantity?.toString() ?? '';
    });
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final qty = _qtyController.text.trim().isNotEmpty
        ? double.tryParse(_qtyController.text.trim())
        : null;

    try {
      if (_itemToEdit != null) {
        // Update
        final updated = _itemToEdit!.copyWith(
          name: name,
          pricePerKg: price,
          totalQuantity: qty,
        );
        await ref.read(inventoryProvider.notifier).updateItem(updated);
      } else {
        // Add
        await ref.read(inventoryProvider.notifier).addItem(name, price, qty);
      }
      _resetForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving item: $e')));
      }
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      await ref.read(inventoryProvider.notifier).deleteItem(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting item: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If adding/editing, show form view
    if (_isAdding) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _itemToEdit != null ? 'Edit Item' : 'Add Item',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _resetForm,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g., Apple',
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price per Kg (₹)',
                    hintText: '0.00',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if (double.tryParse(val) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Available (Kg) - Optional',
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveItem,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _itemToEdit != null ? 'Update Item' : 'Save Item',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Default List View
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage Items',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _startAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),

            // List
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final itemsAsync = ref.watch(inventoryProvider);

                  return itemsAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No items added yet',
                                style: GoogleFonts.inter(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: items.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            elevation: 0,
                            color: Colors.grey[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '₹${item.pricePerKg.toStringAsFixed(2)} / kg${item.totalQuantity != null ? ' • Qty: ${item.totalQuantity}' : ''}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () => _startEdit(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _showDeleteConfirm(context, item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text('Error: $e')),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteItem(item.id!);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
