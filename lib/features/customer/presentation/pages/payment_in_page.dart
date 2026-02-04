import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/customer/domain/entities/customer.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';

class PaymentInPage extends ConsumerStatefulWidget {
  final Customer customer;
  const PaymentInPage({super.key, required this.customer});

  @override
  ConsumerState<PaymentInPage> createState() => _PaymentInPageState();
}

class _PaymentInPageState extends ConsumerState<PaymentInPage> {
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
        customerId: widget.customer.id!,
        amount: double.parse(amountText),
        type: TransactionType.paymentIn,
        date: _selectedDate,
        details: _detailsController.text.isNotEmpty
            ? _detailsController.text
            : 'Payment Received',
      );

      await ref
          .read(transactionListProvider(widget.customer.id!).notifier)
          .addTransaction(transaction);

      // Force refresh of global transaction list
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
        backgroundColor: context.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Payment In',
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
            // Customer Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.primary.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Received From',
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Outstanding Balance Display
            Consumer(
              builder: (context, ref, child) {
                final stats = ref.watch(
                  customerStatsProvider(widget.customer.id!),
                );
                final outstanding = stats.outstandingBalance;
                final remaining = outstanding - _enteredAmount;

                // Update controller text if different to avoid infinite loops
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildTextField(
                    label: 'Outstanding Amount',
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

            const SizedBox(height: 24),

            // Amount Given with Max button
            Consumer(
              builder: (context, ref, child) {
                final stats = ref.watch(
                  customerStatsProvider(widget.customer.id!),
                );
                final outstanding = stats.outstandingBalance;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount Received',
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(8),
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              style: TextStyle(
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
                                prefixStyle: TextStyle(
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
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Remaining Balance Display
            Consumer(
              builder: (context, ref, child) {
                final stats = ref.watch(
                  customerStatsProvider(widget.customer.id!),
                );
                final outstanding = stats.outstandingBalance;
                final remaining = outstanding - _enteredAmount;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remaining Balance',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: remaining > 0
                              ? Colors.red.withOpacity(0.05)
                              : AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: remaining > 0
                                ? Colors.red.withOpacity(0.2)
                                : AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          '₹ ${remaining.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: remaining > 0
                                ? Colors.red.shade700
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                    decoration: InputDecoration(
                      hintText: 'Select Date',
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
                hint: 'Enter payment details (e.g. UPI Ref, Check No...)',
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
            onPressed: _isLoading ? null : _savePayment,
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle, color: Colors.white, size: 24),
            label: Text(
              _isLoading ? 'Processing...' : 'Receive Payment',
              style: const TextStyle(
                color: Colors.white, // White text on primary button
                fontWeight: FontWeight.bold,
                fontSize: 18,
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
    int maxLines = 1,
    bool isBold = false,
    double fontSize = 16,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
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
          inputFormatters: inputFormatters,
          keyboardType: keyboardType,
          maxLines: maxLines,
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: textColor ?? context.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? context.textPrimary,
            ),
            hintStyle: TextStyle(color: context.textMuted),
            filled: true,
            fillColor: readOnly
                ? context.cardColor.withOpacity(0.5)
                : context.cardColor,
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
