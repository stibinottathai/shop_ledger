import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/core/widgets/common_error_widget.dart';
import 'package:shop_ledger/features/expenses/domain/entities/expense.dart';
import 'package:shop_ledger/features/expenses/presentation/providers/expense_provider.dart';
import 'package:fl_chart/fl_chart.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Business Reports',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 28,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 80,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF016B61),
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: const Color(0xFF016B61),
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
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildHomeTab(), _buildChartsTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reports/add'),
        backgroundColor: const Color(0xFF016B61),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Expense',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
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
              return CustomScrollView(
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
                                  color: AppColors.textDark,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push('/reports/all'),
                                child: Text(
                                  'View All',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChartsTab() {
    // We reuse expenseListProvider which currently fetches ALL expenses (default filter)
    // Ideally we might want a dedicated provider for stats to avoid re-fetching if list changes.
    final expensesAsync = ref.watch(expenseListProvider);

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading stats: $err')),
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Center(child: Text('No data available for statistics'));
        }

        final total = expenses.fold<double>(
          0,
          (sum, item) => sum + item.amount,
        );
        final categoryData = _calculateCategoryData(expenses);
        final weeklyData = _calculateWeeklyData(expenses);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatsTotalCard(total),
              const SizedBox(height: 24),
              _buildCategoryPieChart(categoryData),
              const SizedBox(height: 24),
              _buildWeeklyBarChart(weeklyData),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsTotalCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ], // Purple/Blue gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Total Expenditure',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '₹ ${NumberFormat("##,##0.00").format(total)}',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart(Map<String, double> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final total = data.values.fold<double>(0, (sum, v) => sum + v);
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Descending

    // Colors for pie sections
    final colors = [
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF6B7280), // Grey
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Breakdown',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE), // Light purple
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${data.length} Categories',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: sortedEntries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final percentage = item.value / total;
                  final color = colors[index % colors.length];

                  return PieChartSectionData(
                    color: color,
                    value: item.value,
                    title: '${(percentage * 100).toStringAsFixed(0)}%',
                    radius: 25, // Donut thickness
                    titleStyle: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: sortedEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final color = colors[index % colors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.key,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(Map<int, double> weeklyData) {
    // weeklyData keys are weekday indices (1=Mon, ..., 7=Sun)
    // We want to show labels for Mon, Tue etc.

    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final maxVal = weeklyData.values.isEmpty
        ? 100.0
        : weeklyData.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Overview',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE), // Light blue
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Last 7 Days',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0284C7),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${days[group.x.toInt()]} \n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: '₹${rod.toY.toInt()}',
                            style: const TextStyle(color: Colors.yellowAccent),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[value.toInt()],
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  // Index 0 = Monday (which is 1 in DateTime.weekday - 1 = 0)
                  // But wait, weeklyData might be mapped by weekday 1-7.
                  // Let's assume we map 0->Mon, etc.
                  // The map key `weekday` is 1..7.
                  final amount = weeklyData[index + 1] ?? 0.0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: amount,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                        color: amount > 0
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFFF1F5F9), // darker if value exists
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateCategoryData(List<Expense> expenses) {
    final Map<String, double> data = {};
    for (var e in expenses) {
      data[e.category] = (data[e.category] ?? 0) + e.amount;
    }
    return data;
  }

  Map<int, double> _calculateWeeklyData(List<Expense> expenses) {
    // Calculate last 7 days total by weekday.
    // Note: This naive approach just sums by weekday index (1-7) across ALL data.
    // If we only want "Last 7 Days", we must filter first.
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final Map<int, double> data = {};

    // Filter for last 7 days
    final recent = expenses.where((e) => e.date.isAfter(sevenDaysAgo));

    for (var e in recent) {
      // 1 (Mon) to 7 (Sun)
      final weekday = e.date.weekday;
      data[weekday] = (data[weekday] ?? 0) + e.amount;
    }

    // Ensure all days 1-7 have entries (0.0) if missing
    for (int i = 1; i <= 7; i++) {
      data.putIfAbsent(i, () => 0.0);
    }

    return data;
  }

  Widget _buildTotalExpenseCard(AsyncValue<double> totalAsync) {
    // We can show loading state or data
    final total = totalAsync.value ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF016B61),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF016B61).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Expense',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (totalAsync.isLoading)
            const SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            Text(
              '₹ ${NumberFormat("##,##0.00").format(total)}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF016B61),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: Colors.white,
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
                    fontSize: 16,
                    color: AppColors.textDark,
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
