import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/core/widgets/common_error_widget.dart';
import 'package:shop_ledger/features/expenses/domain/entities/expense.dart';
import 'package:shop_ledger/features/expenses/presentation/providers/expense_provider.dart';
import 'package:shop_ledger/features/expenses/presentation/widgets/expense_statistics_view.dart';
import 'package:shop_ledger/features/expenses/presentation/widgets/add_expense_sheet.dart';

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: Column(
        children: [
          // Custom Header
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              0,
            ),
            decoration: BoxDecoration(
              color: context.appBarBackground,
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Column(
              children: [
                // Title Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Expense Reports',
                      style: GoogleFonts.inter(
                        color: context.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // TabBar
                TabBar(
                  controller: _tabController,
                  labelColor: context.isDarkMode
                      ? AppColors.primary
                      : const Color(0xFF016B61),
                  unselectedLabelColor: context.textMuted,
                  indicatorColor: context.isDarkMode
                      ? AppColors.primary
                      : const Color(0xFF016B61),
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  tabs: const [
                    Tab(text: 'Home'),
                    Tab(text: 'Statistics'),
                  ],
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildHomeTab(), _buildChartsTab()],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24, right: 24),
        child: SizedBox(
          height: 56,
          child: FloatingActionButton(
            heroTag: 'expense_add_fab',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddExpenseSheet(),
              );
            },
            backgroundColor: AppColors.primary,
            elevation: 0,
            shape: const CircleBorder(),
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.2),
                    offset: Offset(0, 10),
                    blurRadius: 15,
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final expenseListAsync = ref.watch(recentExpensesProvider);
    final totalExpenseAsync = ref.watch(totalExpenseProvider);

    return Column(
      children: [
        Expanded(
          child: expenseListAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => CommonErrorWidget(
              error: err,
              onRetry: () {
                ref.refresh(recentExpensesProvider);
                ref.refresh(totalExpenseProvider);
              },
            ),
            data: (expenses) {
              return RefreshIndicator(
                onRefresh: () async {
                  ref.refresh(recentExpensesProvider.future);
                  ref.refresh(totalExpenseProvider.future);
                },
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            _buildTotalExpenseCard(totalExpenseAsync),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Transactions',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/reports/all'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'View All',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 12,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final expense = expenses[index];
                            return _buildExpenseItem(expense);
                          },
                          childCount:
                              expenses.length, // Already limited by provider
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChartsTab() {
    return const ExpenseStatisticsView();
  }

  Widget _buildExpenseItem(Expense expense) {
    if (expense.id == null) return const SizedBox.shrink();

    return Dismissible(
      key: Key(expense.id!),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Delete Transaction?',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
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
          border: Border.all(color: context.borderColor), // Theme aware border
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
                  if (expense.notes != null)
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

  Widget _buildTotalExpenseCard(AsyncValue<double> totalAsync) {
    final total = totalAsync.value ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor), // Theme aware border
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TOTAL EXPENSE',
            style: GoogleFonts.inter(
              color: context.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          if (totalAsync.isLoading)
            const SizedBox(
              height: 32,
              width: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              '₹ ${NumberFormat("##,##0.00").format(total)}',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Current Period',
            style: GoogleFonts.inter(
              color: context.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
