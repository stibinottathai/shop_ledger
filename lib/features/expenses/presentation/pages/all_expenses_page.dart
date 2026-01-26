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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Transactions',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textMain,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textMain),
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
                      style: GoogleFonts.inter(color: AppColors.textMuted),
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
      color: Colors.white,
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
          color: isSelected ? const Color(0xFF016B61) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : AppColors.textMain,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: const Color(0xFF15803D),
              size: 20,
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
                    fontSize: 15,
                    color: AppColors.textMain,
                  ),
                ),
                Text(
                  DateFormat('d MMM yyyy, hh:mm a').format(expense.date),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '- ₹${NumberFormat("##,##0").format(expense.amount)}',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: const Color(0xFFB91C1C),
            ),
          ),
        ],
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
