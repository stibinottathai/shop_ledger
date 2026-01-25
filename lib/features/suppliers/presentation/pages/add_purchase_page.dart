import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:shop_ledger/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:shop_ledger/features/reports/presentation/providers/reports_provider.dart';
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';
import 'package:shop_ledger/features/reports/presentation/providers/all_transactions_provider.dart';
import 'package:shop_ledger/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:shop_ledger/features/inventory/domain/entities/item.dart';

class PurchaseItem {
  final Item item;
  final int count; // Number of items
  final double quantity; // Kg
  final double pricePerKg;

  PurchaseItem({
    required this.item,
    required this.count,
    required this.quantity,
    required this.pricePerKg,
  });

  double get total => quantity * pricePerKg;
}

class AddPurchasePage extends ConsumerStatefulWidget {
  final Supplier supplier;
  const AddPurchasePage({super.key, required this.supplier});

  @override
  ConsumerState<AddPurchasePage> createState() => _AddPurchasePageState();
}

class _AddPurchasePageState extends ConsumerState<AddPurchasePage> {
  // Mode: 0 = Manual, 1 = Select Items
  int _entryMode = 1;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _manualDetailsController =
      TextEditingController();

  // Store manual amount separately
  String _manualAmount = '';

  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Select Items Logic
  Item? _selectedItem;
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final List<PurchaseItem> _addedItems = [];

  @override
  void dispose() {
    _amountController.dispose();
    _manualDetailsController.dispose();
    _dateController.dispose();
    _countController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    double total = 0;
    for (var item in _addedItems) {
      total += item.total;
    }
    // Only update controller if we are in Select Items mode
    if (_entryMode == 1) {
      _amountController.text = total.toStringAsFixed(2);
    }
  }

  void _addItem() {
    if (_selectedItem == null) return;
    final count = int.tryParse(_countController.text) ?? 0;
    final qty = double.tryParse(_quantityController.text) ?? 0;
    final pricePerKg = double.tryParse(_priceController.text) ?? 0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid quantity')),
      );
      return;
    }

    setState(() {
      _addedItems.add(
        PurchaseItem(
          item: _selectedItem!,
          count: count,
          quantity: qty,
          pricePerKg: pricePerKg,
        ),
      );

      // Reset fields
      _selectedItem = null;
      _countController.clear();
      _quantityController.clear();
      _priceController.clear();

      // Update totals
      _calculateTotal();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _addedItems.removeAt(index);
      _calculateTotal();
    });
  }

  String _generateDetailsFromItems() {
    if (_addedItems.isEmpty) return 'Purchase';
    return _addedItems
        .map((e) {
          final qty = e.quantity
              .toStringAsFixed(1)
              .replaceAll(RegExp(r'\.0$'), '');
          // Format: "2 Items, 5.0 Kg Rubber @ 150.0 = 750.0" (using a distinct separator pattern helps)
          // We'll use a specific format that our regex can easily find, or continue using the loose text and parse it out.
          // Let's use: "{count} Items, {qty} Kg {name} (Rate: {rate}, Total: {total})"
          return "${e.count} Items, $qty Kg ${e.item.name} (Rate: ${e.pricePerKg.toStringAsFixed(2)}, Total: ${e.total.toStringAsFixed(2)})";
        })
        .join(", ");
  }

  Future<void> _savePurchase() async {
    final amountText = _amountController.text;
    if (amountText.isEmpty || double.tryParse(amountText) == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String details = '';
      if (_entryMode == 0) {
        details = _manualDetailsController.text.isNotEmpty
            ? _manualDetailsController.text
            : 'Purchase via Manual Entry';
      } else {
        details = _generateDetailsFromItems();
      }

      final transaction = Transaction(
        supplierId: widget.supplier.id,
        amount: double.parse(amountText),
        type: TransactionType.purchase,
        date: _selectedDate,
        details: details,
      );

      final repository = ref.read(transactionRepositoryProvider);
      await repository.addTransaction(transaction);

      // Trigger global update for dashboard
      await Future.delayed(const Duration(milliseconds: 1000));
      ref.read(dashboardStatsProvider.notifier).refresh();
      ref.read(reportsProvider.notifier).refresh();
      ref.read(transactionUpdateProvider.notifier).increment();

      ref.invalidate(supplierTransactionListProvider(widget.supplier.id!));
      ref.invalidate(allTransactionsProvider);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving purchase: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Add Purchase',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(child: _buildTabButton('Manual Entry', 0)),
                    Expanded(child: _buildTabButton('Select Items', 1)),
                  ],
                ),
              ),
            ),

            // Supplier Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFE8F5E9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Supplier',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.supplier.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mode Content
            if (_entryMode == 0)
              _buildManualEntry(context)
            else
              _buildSelectItems(context, inventoryAsync),

            // Total Amount & Date
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    readOnly: _entryMode == 1, // ReadOnly in Select Items mode
                    onChanged: (val) {
                      if (_entryMode == 0) {
                        _manualAmount = val;
                      }
                    },
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800], // Darker text for readability
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _entryMode == 1
                          ? Colors.grey[100]
                          : Colors.white,
                      hintText: '0.00',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Transaction Date',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                          _dateController.text = DateFormat(
                            'yyyy-MM-dd',
                          ).format(picked);
                        });
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 110, // Increased height for summary + button
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Optional: Show count summary?
              // SizedBox(
              //   height: 56,
              //   child: ElevatedButton.icon(...)
              // ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  key: const Key('save_purchase_fab'),
                  onPressed: _isLoading ? null : _savePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.save_outlined, color: Colors.white),
                  label: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Purchase',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _entryMode == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          // Logic for switching tabs
          if (_entryMode != index) {
            _entryMode = index;

            if (_entryMode == 0) {
              // Switched to Manual Mode
              // Restore manual amount
              _amountController.text = _manualAmount;
            } else {
              // Switched to Select Items Mode
              // Save manual amount first? No, we update _manualAmount on change.
              // Just calculate total from items
              _calculateTotal();
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.black87 : Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntry(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _manualDetailsController,
            maxLines: 3,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Enter purchase details...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectItems(
    BuildContext context,
    AsyncValue<List<Item>> inventoryAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select Item Dropdown
          inventoryAsync.when(
            data: (items) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Item>(
                  value: _selectedItem,
                  isExpanded: true,
                  hint: Text(
                    'Select Item',
                    style: GoogleFonts.inter(color: Colors.grey[600]),
                  ),
                  items: items.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.name,
                        style: GoogleFonts.inter(color: Colors.black87),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedItem = val;
                    });
                  },
                ),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Failed to load items'),
          ),

          const SizedBox(height: 16),

          // Number of Items and Quantity Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'No. Items',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Quantity (Kg)',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Price Row
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              labelText: 'Price / Kg',
              labelStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Add Item Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedItem == null ? null : _addItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1a1a1a),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Add Item',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Added Items List Preview
          if (_addedItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            "Item",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            "Detail",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "Total",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 32), // Action copy space
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _addedItems.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _addedItems[index];
                      final qty = item.quantity
                          .toStringAsFixed(1)
                          .replaceAll(RegExp(r'\.0$'), '');
                      final rate = item.pricePerKg.toStringAsFixed(0);
                      final total = item.total.toStringAsFixed(0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.item.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (item.count > 0)
                                    Text(
                                      "${item.count} Items",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                "$qty Kg x ₹$rate",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "₹$total",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: const Color(0xFF00695C),
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
