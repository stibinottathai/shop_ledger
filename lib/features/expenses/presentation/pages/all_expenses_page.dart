import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/core/widgets/common_error_widget.dart';
import 'package:shop_ledger/features/expenses/domain/entities/expense.dart';
import 'package:shop_ledger/features/expenses/presentation/providers/expense_provider.dart';

class AllExpensesPage extends ConsumerStatefulWidget {
  const AllExpensesPage({super.key});

  @override
  ConsumerState<AllExpensesPage> createState() => _AllExpensesPageState();
}

class _AllExpensesPageState extends ConsumerState<AllExpensesPage> {
  int _selectedFilterIndex = 2; // Default to Monthly

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _applyFilter(2));
  }

  void _applyFilter(int index) {
    setState(() => _selectedFilterIndex = index);
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (index) {
      case 0: // Daily
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 1: // Weekly
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case 2: // Monthly
        start = DateTime(now.year, now.month, 1);
        break;
      case 3: // Yearly (New Requirement)
        start = DateTime(now.year, 1, 1);
        break;
      case 4: // Custom
        return; // Handled by date picker
      default:
        start = DateTime(now.year, now.month, 1);
    }

    ref
        .read(expenseFilterProvider.notifier)
        .setFilter(ExpenseFilter(startDate: start, endDate: end));
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (pickerContext, child) {
        final isDark = pickerContext.isDarkMode;
        return Theme(
          data: Theme.of(pickerContext).copyWith(
            scaffoldBackgroundColor: isDark
                ? AppColors.backgroundDark
                : Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceDark,
                    onSurface: Colors.white,
                    secondary: AppColors.primary,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.textDark,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedFilterIndex = 4);
      ref
          .read(expenseFilterProvider.notifier)
          .setFilter(
            ExpenseFilter(startDate: picked.start, endDate: picked.end),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseListAsync = ref.watch(expenseListProvider);

    return Scaffold(
      backgroundColor: context.appBarBackground,
      appBar: AppBar(
        title: Text(
          'Transactions',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.appBarBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: expenseListAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => CommonErrorWidget(
                error: err,
                onRetry: () => ref.refresh(expenseListProvider),
              ),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Center(
                    child: Text(
                      "No transactions found",
                      style: GoogleFonts.inter(color: context.textMuted),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) =>
                      _buildExpenseItem(expenses[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: context.isDarkMode ? AppColors.backgroundDark : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTab('This Month', 2),
            const SizedBox(width: 8),
            _buildTab('This Week', 1),
            const SizedBox(width: 8),
            _buildTab('This Year', 3), // Index 3
            const SizedBox(width: 8),
            _buildTab('Custom', 4, onTap: _selectDateRange), // Index 4
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, {VoidCallback? onTap}) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: onTap ?? () => _applyFilter(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF016B61)
              : (context.isDarkMode
                    ? AppColors.surfaceDark
                    : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : context.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    if (expense.id == null) return const SizedBox.shrink();

    return Dismissible(
      key: Key(expense.id!),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: context.cardColor,
              title: Text(
                'Delete Transaction?',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              content: Text(
                'Are you sure you want to delete this transaction?',
                style: GoogleFonts.inter(color: context.textPrimary),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: context.textMuted),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        if (expense.id != null) {
          ref.read(expenseListProvider.notifier).deleteExpense(expense.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction deleted', style: GoogleFonts.inter()),
              backgroundColor: AppColors.textMain,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              offset: Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? AppColors.surfaceDark
                    : AppColors.slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              alignment: Alignment.center,
              child: Icon(
                _getCategoryIcon(expense.category),
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.category,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM yyyy, hh:mm a').format(expense.date),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (expense.notes != null && expense.notes!.isNotEmpty)
                    Text(
                      expense.notes!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '- ₹${NumberFormat("##,##0").format(expense.amount)}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expense.paymentMethod.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Travel':
        return Icons.directions_car;
      case 'Rent':
        return Icons.home;
      case 'Bills':
        return Icons.receipt_long;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Medical':
        return Icons.medical_services;
      case 'Entertainment':
        return Icons.movie;
      default:
        return Icons.attach_money;
    }
  }
}
