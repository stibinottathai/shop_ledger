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

class PaymentOutPage extends ConsumerStatefulWidget {
  final Supplier supplier;
  const PaymentOutPage({super.key, required this.supplier});

  @override
  ConsumerState<PaymentOutPage> createState() => _PaymentOutPageState();
}

class _PaymentOutPageState extends ConsumerState<PaymentOutPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _outstandingBalanceController =
      TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  double _enteredAmount = 0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateAmount);
  }

  void _updateAmount() {
    setState(() {
      _enteredAmount = double.tryParse(_amountController.text) ?? 0;
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateAmount);
    _outstandingBalanceController.dispose();
    _amountController.dispose();
    _detailsController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    final amountText = _amountController.text;
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = Transaction(
        supplierId: widget.supplier.id,
        amount: double.parse(amountText),
        type: TransactionType.paymentOut,
        date: _selectedDate,
        details: _detailsController.text.isNotEmpty
            ? _detailsController.text
            : 'Payment Out',
      );

      final repository = ref.read(transactionRepositoryProvider);
      await repository.addTransaction(transaction);

      // Trigger global update for dashboard
      // Small delay to ensure DB consistency
      await Future.delayed(const Duration(milliseconds: 1000));
      ref.read(dashboardStatsProvider.notifier).refresh();
      ref.read(reportsProvider.notifier).refresh();
      ref.read(transactionUpdateProvider.notifier).increment();

      // Refresh the list
      ref.invalidate(supplierTransactionListProvider(widget.supplier.id!));
      ref.invalidate(allTransactionsProvider);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving payment: $e')));
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
        title: Text(
          'Payment Out',
          style: TextStyle(color: context.textPrimary),
        ),
        centerTitle: true,
        backgroundColor: context.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Supplier Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paying To',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.supplier.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Balance Info
            Consumer(
              builder: (context, ref, child) {
                final stats = ref.watch(
                  supplierStatsProvider(widget.supplier.id!),
                );
                final outstanding = stats.outstandingBalance;
                final remaining = outstanding - _enteredAmount;

                // Update controller text if different to avoid infinite loops
                // (though less risky here as it's not the active field)
                final newText = remaining.toStringAsFixed(2);
                if (_outstandingBalanceController.text != newText) {
                  // Schedule update to avoid build-phase modification errors
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _outstandingBalanceController.text = newText;
                    }
                  });
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildTextField(
                    label: 'Outstanding Balance',
                    hint: '0.00',
                    controller: _outstandingBalanceController,
                    isBold: true,
                    fontSize: 18,
                    prefixText: '₹ ',
                    readOnly: true,
                    textColor: remaining < 0
                        ? AppColors.primary
                        : context.textPrimary,
                  ),
                );
              },
            ),

            // Amount with Max button
            Consumer(
              builder: (context, ref, child) {
                final stats = ref.watch(
                  supplierStatsProvider(widget.supplier.id!),
                );
                final outstanding = stats.outstandingBalance;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount Paid',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(color: context.textMuted),
                              filled: true,
                              fillColor: context.cardColor,
                              prefixText: '₹ ',
                              prefixStyle: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
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
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Max button
                        Material(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              _amountController.text = outstanding
                                  .toStringAsFixed(2);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              child: const Text(
                                'Max',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
                    hintText: 'Select Date',
                    hintStyle: TextStyle(color: context.textMuted),
                    filled: true,
                    fillColor: context.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderColor),
                    ),
                    suffixIcon: Icon(
                      Icons.calendar_today,
                      color: context.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details
            _buildTextField(
              label: 'Details',
              hint: 'e.g. Bank Transfer Ref: ...',
              controller: _detailsController,
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.danger.withOpacity(0.7),
                  elevation: 4,
                  shadowColor: AppColors.danger.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Save Payment',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isBold = false,
    double fontSize = 16,
    String? prefixText,
    bool readOnly = false,
    Color? textColor,
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
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: textColor ?? context.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.textMuted),
            prefixText: prefixText,
            prefixStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: context.textPrimary,
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
