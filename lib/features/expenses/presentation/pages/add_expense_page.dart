import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/expenses/domain/entities/expense.dart';
import 'package:shop_ledger/features/expenses/presentation/providers/expense_provider.dart';

class AddExpensePage extends ConsumerStatefulWidget {
  const AddExpensePage({super.key});

  @override
  ConsumerState<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends ConsumerState<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = 'Food';
  String _paymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  String? _recurring = 'None';
  bool _isLoading = false;

  final List<String> _categories = [
    'Food',
    'Fuel',
    'Travel',
    'Rent',
    'Bills',
    'Shopping',
    'Medical',
    'Entertainment',
    'Other',
  ];

  final List<String> _paymentMethods = ['Cash', 'UPI', 'Bank', 'Credit Card'];
  final List<String> _recurringOptions = ['None', 'Daily', 'Weekly', 'Monthly'];

  Future<void> _selectDate(BuildContext context) async {
    final bool isDark = context.isDarkMode;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (dialogContext, child) {
        return Theme(
          data: Theme.of(dialogContext).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceDark,
                    onSurface: AppColors.textDarkTheme,
                  )
                : ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    onSurface: AppColors.textDark,
                  ),
            dialogTheme: DialogThemeData(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              headerBackgroundColor: AppColors.primary,
              headerForegroundColor: Colors.white,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return isDark ? AppColors.textDarkTheme : AppColors.textDark;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return Colors.transparent;
              }),
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return isDark ? AppColors.textDarkTheme : AppColors.textDark;
              }),
              yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return Colors.transparent;
              }),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final expense = Expense(
          amount: double.parse(_amountController.text),
          category: _category,
          paymentMethod: _paymentMethod,
          date: _selectedDate,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          recurring: _recurring == 'None' ? null : _recurring,
        );

        await ref.read(expenseListProvider.notifier).addExpense(expense);

        // Force refresh dashboard providers immediately
        ref.refresh(recentExpensesProvider);
        ref.refresh(totalExpenseProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense added successfully'),
              backgroundColor: Colors.black,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding expense: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        title: Text(
          'Add Expense',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        backgroundColor: context.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input
              Text(
                'Amount',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: context.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Category & Payment Method Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: context.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _category,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.borderColor,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                          items: _categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _category = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: context.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: context.borderColor,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                          items: _paymentMethods.map((String method) {
                            return DropdownMenuItem<String>(
                              value: method,
                              child: Text(method),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _paymentMethod = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Date Picker
              Text(
                'Date',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: context.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: context.textPrimary,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: context.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recurring
              Text(
                'Recurring',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: context.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _recurring,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                items: _recurringOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _recurring = newValue!;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Notes
              Text(
                'Notes',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.greyText,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                decoration: InputDecoration(
                  hintText: 'Add a note...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Expense',
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
}
