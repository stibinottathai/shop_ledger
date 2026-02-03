import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/customer/domain/entities/customer.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';

import 'package:shop_ledger/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:shop_ledger/features/inventory/domain/entities/item.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Add this

class SelectedSaleItem {
  final Item item;
  final double quantity;
  final int count;
  final double totalPrice;

  SelectedSaleItem({
    required this.item,
    required this.quantity,
    required this.count,
  }) : totalPrice = (item.unit == 'ml' || item.unit == 'mg')
           ? (item.pricePerKg * quantity) / 1000
           : item.pricePerKg * quantity;
}

class AddSalePage extends ConsumerStatefulWidget {
  final Customer customer;
  const AddSalePage({super.key, required this.customer});

  @override
  ConsumerState<AddSalePage> createState() => _AddSalePageState();
}

class _AddSalePageState extends ConsumerState<AddSalePage> {
  // Common
  final TextEditingController _manualAmountController = TextEditingController();
  final TextEditingController _itemizedAmountController =
      TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final TextEditingController _receivedAmountController =
      TextEditingController();

  // Itemized Mode
  bool _isManualMode = false;
  final List<SelectedSaleItem> _selectedItems = [];

  // Item Form
  Item? _selectedInventoryItem;
  final TextEditingController _itemQtyController = TextEditingController();
  final TextEditingController _itemCountController = TextEditingController(
    text: '1',
  );

  @override
  void dispose() {
    _manualAmountController.dispose();
    _itemizedAmountController.dispose();
    _detailsController.dispose();
    _dateController.dispose();
    _itemQtyController.dispose();
    _itemCountController.dispose();
    _receivedAmountController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
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
              if (hasScanned) return;

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
      // Find item by barcode in the local list (so dropdown can select it)
      final inventoryState = ref.read(inventoryProvider);

      inventoryState.when(
        data: (items) {
          try {
            final existingItem = items.firstWhere(
              (item) => item.barcode == result,
            );

            setState(() {
              _selectedInventoryItem = existingItem;
              // Clear quantity for user to enter
              _itemQtyController.clear();
              _itemCountController.text = '1';
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Item found: ${existingItem.name}'),
                  backgroundColor: AppColors.primary,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          } catch (e) {
            // firstWhere throws StateError if not found
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item not found in inventory'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        error: (e, s) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading inventory: $e')),
            );
          }
        },
        loading: () {
          // Should be loaded by now if we are on this page
        },
      );
    }
  }

  double _calculateCurrentItemTotal() {
    if (_selectedInventoryItem == null) return 0;
    final qty = double.tryParse(_itemQtyController.text) ?? 0;

    // For ml and mg, the pricePerKg is stored as Price/Liter or Price/Gram
    // So we need to divide the quantity (ml/mg) by 1000 to get L/g equivalent for calculation
    // Wait, if Price is per Gram, and Qty is mg. Cost = Price * (Qty/1000). Correct.
    // If Price is per Gram (e.g. Saffron 500/g). Qty 100mg. Cost = 500 * 0.1 = 50. Correct.
    // If Price is per Liter (e.g. Oil 26/L). Qty 500ml. Cost = 26 * 0.5 = 13. Correct.

    if (_selectedInventoryItem!.unit == 'ml' ||
        _selectedInventoryItem!.unit == 'mg') {
      return (_selectedInventoryItem!.pricePerKg * qty) / 1000;
    }

    return _selectedInventoryItem!.pricePerKg * qty;
  }

  void _calculateTotal() {
    // Only calculate for itemized mode
    double total = 0;
    for (var i in _selectedItems) {
      total += i.totalPrice;
    }
    _itemizedAmountController.text = total.toStringAsFixed(2);
  }

  void _incrementCount() {
    int current = int.tryParse(_itemCountController.text) ?? 1;
    setState(() {
      _itemCountController.text = (current + 1).toString();
    });
  }

  void _decrementCount() {
    int current = int.tryParse(_itemCountController.text) ?? 1;
    if (current > 1) {
      setState(() {
        _itemCountController.text = (current - 1).toString();
      });
    }
  }

  void _addItemToList() {
    if (_selectedInventoryItem == null) return;

    final qtyText = _itemQtyController.text;
    if (qtyText.isEmpty) return;

    final qty = double.tryParse(qtyText);
    if (qty == null || qty <= 0) return;

    final count = int.tryParse(_itemCountController.text) ?? 1;

    setState(() {
      _selectedItems.add(
        SelectedSaleItem(
          item: _selectedInventoryItem!,
          quantity: qty,
          count: _selectedInventoryItem!.unit == 'kg' ? count : 1,
        ),
      );

      // Reset item form
      _selectedInventoryItem = null;
      _itemQtyController.clear();
      _itemCountController.text = '1';

      _calculateTotal();
    });
  }

  void _deleteItemFromList(int index) {
    setState(() {
      _selectedItems.removeAt(index);
      _calculateTotal();
    });
  }

  String _constructItemizedDetails() {
    final buffer = StringBuffer();
    // Manual note first if any
    if (_detailsController.text.isNotEmpty) {
      buffer.write('${_detailsController.text}\n');
    }

    // Items
    final itemsList = _selectedItems
        .map((e) {
          final unit = e.item.unit == 'ml'
              ? 'l'
              : e.item.unit == 'mg'
              ? 'g'
              : e.item.unit;
          final countStr = e.item.unit == 'kg' ? ' [${e.count} Nos]' : '';
          return '${e.item.name} (${e.item.pricePerKg.toStringAsFixed(0)}/$unit) ${e.quantity}$unit$countStr = ${e.totalPrice.toStringAsFixed(0)}';
        })
        .join('\n');

    buffer.write(itemsList);
    return buffer.toString();
  }

  Future<void> _saveSale() async {
    // Use the controller corresponding to the current mode
    final amountText = _isManualMode
        ? _manualAmountController.text
        : _itemizedAmountController.text;

    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (!_isManualMode && _selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Construct details
      String finalDetails = _isManualMode
          ? (_detailsController.text.isNotEmpty
                ? _detailsController.text
                : 'Sale')
          : _constructItemizedDetails();

      final futures = <Future<void>>[];

      // 1. Save Sale Transaction
      final receivedAmountForTx = _receivedAmountController.text.isNotEmpty
          ? double.tryParse(_receivedAmountController.text) ?? 0.0
          : null;

      final saleTransaction = Transaction(
        customerId: widget.customer.id!,
        amount: double.parse(amountText),
        type: TransactionType.sale,
        date: _selectedDate,
        details: finalDetails,
        receivedAmount: receivedAmountForTx,
      );

      final notifier = ref.read(
        transactionListProvider(widget.customer.id!).notifier,
      );

      futures.add(notifier.addTransaction(saleTransaction));

      // 2. Save Payment Transaction (if received amount > 0)
      final receivedAmountStr = _receivedAmountController.text;
      if (receivedAmountStr.isNotEmpty) {
        final receivedAmount = double.tryParse(receivedAmountStr);
        if (receivedAmount != null && receivedAmount > 0) {
          final paymentTransaction = Transaction(
            customerId: widget.customer.id!,
            amount: receivedAmount,
            type: TransactionType.paymentIn,
            date: _selectedDate,
            details: 'Payment received for sale',
          );
          futures.add(notifier.addTransaction(paymentTransaction));
        }
      }

      await Future.wait(futures);

      // 3. Update Inventory Stock (Deduct Items)
      if (!_isManualMode && _selectedItems.isNotEmpty) {
        final inventoryNotifier = ref.read(inventoryProvider.notifier);
        for (final sItem in _selectedItems) {
          final originalItem = sItem.item;
          final currentQty = originalItem.totalQuantity ?? 0;
          final soldQty = sItem.quantity;

          final newQty = currentQty - soldQty;

          // Debug log
          print(
            'Debug: Sale - Deducting ${originalItem.name}. Current: $currentQty, Sold: $soldQty, New: $newQty',
          );

          final updatedItem = originalItem.copyWith(totalQuantity: newQty);
          await inventoryNotifier.updateItem(updatedItem);
        }
      }

      // Force refresh of global transaction list
      ref.invalidate(allTransactionsProvider);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving sale: $e')));
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
          'Add Sale',
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: context.borderColor, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Mode Toggle
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.subtleBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isManualMode = true;
                        // No need to copy values, keep states independent
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isManualMode
                              ? context.cardColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _isManualMode
                              ? [
                                  const BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Manual Entry',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isManualMode
                                ? context.textPrimary
                                : context.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isManualMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isManualMode
                              ? context.cardColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: !_isManualMode
                              ? [
                                  const BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Select Items',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !_isManualMode
                                ? context.textPrimary
                                : context.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Customer Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primary.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer',
                    style: TextStyle(
                      color: context.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.customer.name,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (!_isManualMode) ...[
              // Item Selection UI
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer(
                  builder: (context, ref, _) {
                    final inventoryAsync = ref.watch(inventoryProvider);
                    return inventoryAsync.when(
                      data: (items) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<Item>(
                                    value: _selectedInventoryItem,
                                    isExpanded: true,
                                    dropdownColor: context.cardColor,
                                    style: TextStyle(
                                      color: context.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Select Item',
                                      labelStyle: TextStyle(
                                        color: context.textMuted,
                                      ),
                                      filled: true,
                                      fillColor: context.cardColor,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 16,
                                          ),
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
                                    ),
                                    items: items.map((item) {
                                      String priceUnit = item.unit;
                                      if (item.unit == 'ml') priceUnit = 'l';
                                      if (item.unit == 'mg') priceUnit = 'g';

                                      final quantity = item.totalQuantity ?? 0;
                                      final isOutOfStock = quantity <= 0;

                                      return DropdownMenuItem(
                                        value: item,
                                        enabled: !isOutOfStock,
                                        child: Text(
                                          '${item.name} (₹${item.pricePerKg}/$priceUnit)${isOutOfStock ? ' - Out of Stock' : ''}',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isOutOfStock
                                                ? context.textMuted
                                                : context.textPrimary,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedInventoryItem = val;
                                        // Update quantity label/logic if needed
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.qr_code_scanner),
                                    color: AppColors.primary,
                                    onPressed: _scanBarcode,
                                    tooltip: 'Scan Item QR',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _itemQtyController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(6),
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]'),
                                      ),
                                    ],
                                    onChanged: (_) => setState(() {}),
                                    style: TextStyle(
                                      color: context.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      labelText:
                                          'Quantity (${_selectedInventoryItem?.unit ?? 'Units'})',
                                      labelStyle: TextStyle(
                                        color: context.textMuted,
                                      ),
                                      filled: true,
                                      fillColor: context.cardColor,
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
                                    ),
                                  ),
                                ),
                                if (_selectedInventoryItem?.unit == 'kg') ...[
                                  const SizedBox(width: 12),
                                  // Count Stepper
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: context.borderColor,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.remove,
                                            size: 20,
                                            color: context.textPrimary,
                                          ),
                                          onPressed: _decrementCount,
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                        SizedBox(
                                          width: 40,
                                          child: TextField(
                                            controller: _itemCountController,
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.add,
                                            size: 20,
                                            color: context.textPrimary,
                                          ),
                                          onPressed: _incrementCount,
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _addItemToList,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textDark,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: context.borderColor,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Add Item (Total: ₹${_calculateCurrentItemTotal().toStringAsFixed(2)})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Error loading items: $e'),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Selected Items List
              if (_selectedItems.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedItems.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final sItem = _selectedItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      color: context.subtleBackground,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: context.borderColor),
                      ),
                      child: ListTile(
                        title: Text(
                          sItem.item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${sItem.quantity} ${sItem.item.unit}${sItem.item.unit == 'kg' ? ' (${sItem.count} Nos)' : ''} x ₹${sItem.item.pricePerKg}/${(sItem.item.unit == 'ml'
                              ? 'l'
                              : sItem.item.unit == 'mg'
                              ? 'g'
                              : sItem.item.unit)}',
                          style: TextStyle(color: context.textMuted),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${sItem.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteItemFromList(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),
            ],

            // Total Amount Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTextField(
                label: 'Total Amount',
                hint: '0.00',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                isBold: true,
                fontSize: 24,
                prefixText: '₹ ',
                // Disable editing if in item mode
                controller: _isManualMode
                    ? _manualAmountController
                    : _itemizedAmountController,
                readOnly: !_isManualMode,
              ),
            ),

            const SizedBox(height: 24),

            // Received Amount Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Received Amount',
                      hint: '0.00',
                      controller: _receivedAmountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixText: '₹ ',
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(8),
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Live Balance Display
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 56, // Match TextField height approx
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '₹ ${(() {
                              final total = double.tryParse(_isManualMode ? _manualAmountController.text : _itemizedAmountController.text) ?? 0;
                              final received = double.tryParse(_receivedAmountController.text) ?? 0;
                              return (total - received).toStringAsFixed(2);
                            })()}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Date Picker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dateController,
                    style: TextStyle(color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Select Date',
                      hintStyle: TextStyle(color: context.textMuted),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: context.textMuted,
                      ),
                      filled: true,
                      fillColor: context.cardColor,
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
                        vertical: 14,
                      ),
                    ),
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
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Optional Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTextField(
                label: 'Details (Optional)',
                hint: 'Enter notes...',
                maxLines: 4,
                controller: _detailsController,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          border: Border(top: BorderSide(color: context.borderColor)),
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveSale,
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.textDark,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.save,
                    color: AppColors.backgroundLight,
                    size: 24,
                  ),
            label: Text(
              _isLoading ? 'Saving...' : 'Save Sale',
              style: const TextStyle(
                color: AppColors.backgroundLight,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
    int maxLines = 1,
    bool isBold = false,
    double fontSize = 16,
    String? prefixText,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          maxLines: maxLines,
          controller: controller,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: context.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: context.textPrimary,
            ),
            hintStyle: TextStyle(color: context.textMuted),
            filled: true,
            fillColor: context.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
