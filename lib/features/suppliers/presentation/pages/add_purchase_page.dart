import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

import 'package:shop_ledger/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:shop_ledger/features/inventory/domain/entities/item.dart';

class PurchaseItem {
  final Item item;
  final int count; // Number of items (relevant for kg)
  final double quantity; // Qty in Unit
  final double pricePerUnit;
  final String unit;

  PurchaseItem({
    required this.item,
    required this.count,
    required this.quantity,
    required this.pricePerUnit,
    required this.unit,
  });

  double get total => quantity * pricePerUnit;
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
  String _selectedUnit = 'kg';
  final List<String> _unitOptions = ['kg', 'box', 'piece', 'liter'];

  final TextEditingController _countController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  final List<PurchaseItem> _addedItems = [];

  @override
  void dispose() {
    _amountController.dispose();
    _manualDetailsController.dispose();
    _dateController.dispose();
    _countController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  // Calculate total for Select Items mode
  double _calculatedTotal = 0;

  void _calculateTotal() {
    double total = 0;
    for (var item in _addedItems) {
      total += item.total;
    }
    setState(() {
      _calculatedTotal = total;
    });
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

    // If unit is NOT kg, count is irrelevant (or implicit).
    // User said "maintain number of items only for kg".
    // For Box/Piece/Liter, we can treat count as 0 or equal to quantity if integer?
    // Let's set count to 0 for non-kg to avoid confusion, or purely use it for display.
    final finalCount = _selectedUnit == 'kg' ? count : 0;

    setState(() {
      _addedItems.add(
        PurchaseItem(
          item: _selectedItem!,
          count: finalCount,
          quantity: qty,
          pricePerUnit: pricePerKg,
          unit: _selectedUnit,
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

          if (e.unit == 'kg') {
            return "${e.count} Items, $qty Kg ${e.item.name} (Rate: ${e.pricePerUnit.toStringAsFixed(2)}, Total: ${e.total.toStringAsFixed(2)})";
          } else {
            // For Box, Piece, Liter
            String unitLabel = e.unit;
            if (e.quantity > 1) unitLabel += "s"; // pluralize roughly
            return "$qty $unitLabel ${e.item.name} (Rate: ${e.pricePerUnit.toStringAsFixed(2)}, Total: ${e.total.toStringAsFixed(2)})";
          }
        })
        .join(", ");
  }

  Future<void> _savePurchase() async {
    double amount = 0;

    if (_entryMode == 0) {
      // Manual Mode
      final amountText = _amountController.text;
      if (amountText.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
        return;
      }
      amount = double.tryParse(amountText) ?? 0;
    } else {
      // Select Items Mode
      amount = _calculatedTotal;
    }

    if (amount == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Amount cannot be zero')));
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

      final paidAmount = _paidAmountController.text.isNotEmpty
          ? double.tryParse(_paidAmountController.text) ?? 0.0
          : null;

      final transaction = Transaction(
        supplierId: widget.supplier.id,
        amount: amount,
        type: TransactionType.purchase,
        date: _selectedDate,
        details: details,
        receivedAmount:
            paidAmount, // Reusing receivedAmount field for Amount Paid
      );

      final repository = ref.read(transactionRepositoryProvider);
      await repository.addTransaction(transaction);

      // 2. Save Payment Out Transaction (if amount paid > 0)
      final paidAmountStr = _paidAmountController.text;
      if (paidAmountStr.isNotEmpty) {
        final paidAmount = double.tryParse(paidAmountStr);
        if (paidAmount != null && paidAmount > 0) {
          final paymentTransaction = Transaction(
            supplierId: widget.supplier.id,
            amount: paidAmount,
            type: TransactionType.paymentOut,
            date: _selectedDate,
            details: 'Payment made for purchase',
          );
          await repository.addTransaction(paymentTransaction);
        }
      }

      // 3. Update Inventory Stock
      print(
        'Debug: EntryMode: $_entryMode, AddedItems: ${_addedItems.length}',
      ); // Debug log
      if (_entryMode == 1 && _addedItems.isNotEmpty) {
        final inventoryNotifier = ref.read(inventoryProvider.notifier);
        for (final purchaseItem in _addedItems) {
          final originalItem = purchaseItem.item;
          final currentQty = originalItem.totalQuantity ?? 0;
          final newQty = currentQty + purchaseItem.quantity;

          print(
            'Debug: Updating ${originalItem.name}. Current: $currentQty, Adding: ${purchaseItem.quantity}, New: $newQty',
          ); // Debug log

          final updatedItem = originalItem.copyWith(totalQuantity: newQty);
          await inventoryNotifier.updateItem(updatedItem);
          print('Debug: Update complete for ${originalItem.name}'); // Debug log
        }
      }

      // Trigger global update for dashboard
      await Future.delayed(const Duration(milliseconds: 1000));
      ref.read(dashboardStatsProvider.notifier).refresh();
      ref.read(reportsProvider.notifier).refresh();
      ref.read(transactionUpdateProvider.notifier).increment();

      ref.invalidate(supplierTransactionListProvider(widget.supplier.id!));
      ref.invalidate(allTransactionsProvider);

      // Refresh supplier list to update balances
      ref.read(supplierListProvider.notifier).refresh();

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
      backgroundColor: context.background,
      appBar: AppBar(
        title: Text(
          'Add Purchase',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.textPrimary,
            size: 20,
          ),
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
                  color: context.subtleBackground,
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
              color: AppColors.primary.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Supplier',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.supplier.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
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
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_entryMode == 0)
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(8),
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: context.textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: context.cardColor,
                        hintText: '0.00',
                        hintStyle: TextStyle(color: context.textMuted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: context.subtleBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Text(
                        "₹${_calculatedTotal.toStringAsFixed(2)}",
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  Text(
                    'Transaction Date',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dateController,
                    readOnly: true,
                    style: TextStyle(color: context.textPrimary),
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
                      fillColor: context.cardColor,
                      suffixIcon: Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: context.textMuted,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.borderColor),
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

            const SizedBox(height: 16),

            // Amount Paid & Balance
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount Paid',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _paidAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(8),
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: context.textPrimary,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: context.cardColor,
                            hintText: '0.00',
                            prefixText: '₹ ',
                            hintStyle: TextStyle(color: context.textMuted),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.borderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.borderColor,
                              ),
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
                  const SizedBox(width: 16),
                  // Balance Display
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 53, // Match TextField height approx
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.2),
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '₹ ${(() {
                              final total = _entryMode == 0 ? (double.tryParse(_amountController.text) ?? 0) : _calculatedTotal;
                              final paid = double.tryParse(_paidAmountController.text) ?? 0;
                              return (total - paid).toStringAsFixed(2);
                            })()}',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
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
              // Clear controller to ensure strict separation
              _amountController.clear();
              _calculateTotal();
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? context.cardColor : Colors.transparent,
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
            color: isSelected ? context.textPrimary : context.textMuted,
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
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _manualDetailsController,
            maxLines: 3,
            style: TextStyle(color: context.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.cardColor,
              hintText: 'Enter purchase details...',
              hintStyle: TextStyle(color: context.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
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
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Item>(
                  value: _selectedItem,
                  isExpanded: true,
                  dropdownColor: context.cardColor,
                  hint: Text(
                    'Select Item',
                    style: GoogleFonts.inter(color: context.textMuted),
                  ),
                  items: items.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(
                        item.name,
                        style: GoogleFonts.inter(color: context.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedItem = val;
                      // Logic to auto-select unit based on item if needed
                      if (_selectedItem != null) {
                        if (_selectedItem!.unit == 'pcs') {
                          _selectedUnit = 'piece';
                        } else {
                          // Default or 'kg'
                          _selectedUnit = 'kg';
                        }
                      }
                    });
                  },
                ),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Failed to load items'),
          ),

          const SizedBox(height: 16),

          // Unit Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedUnit,
                isExpanded: true,
                dropdownColor: context.cardColor,
                hint: Text(
                  'Select Unit',
                  style: TextStyle(color: context.textMuted),
                ),
                items: _unitOptions.map((u) {
                  String label = u[0].toUpperCase() + u.substring(1);
                  if (u == 'liter') label = 'Liter (l)';
                  if (u == 'kg') label = 'Kilogram (kg)';
                  return DropdownMenuItem(
                    value: u,
                    child: Text(
                      label,
                      style: GoogleFonts.inter(color: context.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedUnit = val!;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Number of Items and Quantity Row
          Row(
            children: [
              if (_selectedUnit == 'kg') ...[
                Expanded(
                  child: TextField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: TextStyle(color: context.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.cardColor,
                      labelText: 'No. Items',
                      labelStyle: TextStyle(color: context.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: TextStyle(color: context.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.cardColor,
                    labelText: _selectedUnit == 'kg'
                        ? 'Quantity (Kg)'
                        : 'Quantity (${_selectedUnit[0].toUpperCase()}${_selectedUnit.substring(1)})',
                    labelStyle: TextStyle(color: context.textMuted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
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
            inputFormatters: [
              LengthLimitingTextInputFormatter(8),
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: TextStyle(color: context.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.cardColor,
              labelText:
                  'Price / ${_selectedUnit == 'liter' ? 'ltr' : _selectedUnit}',
              labelStyle: TextStyle(color: context.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderColor),
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
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
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
                              color: context.textMuted,
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
                              color: context.textMuted,
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
                              color: context.textMuted,
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
                      String unitSuffix = item.unit;
                      if (item.unit == 'liter') unitSuffix = 'l';

                      final rate = item.pricePerUnit.toStringAsFixed(0);
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
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  if (item.count > 0)
                                    Text(
                                      "${item.count} Items",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: context.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                "$qty $unitSuffix x ₹$rate",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: context.textMuted,
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
