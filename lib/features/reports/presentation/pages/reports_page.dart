import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/core/widgets/common_error_widget.dart';
import 'package:shop_ledger/features/reports/presentation/providers/reports_provider.dart';
import 'package:shop_ledger/features/expenses/presentation/widgets/expense_statistics_view.dart';
import 'package:shop_ledger/features/expenses/presentation/providers/expense_provider.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  int _selectedTabIndex = 3; // Default to 'Summary' (3)
  int _selectedDateFilter = 0; // 0: Today, 1: This Week, 2: Range
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    // Watch the reports provider
    final reportsAsync = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildAppBar(context),

            // Main Content Scrolls
            Expanded(
              child: reportsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => CommonErrorWidget(
                  error: err,
                  onRetry: () {
                    ref.refresh(reportsProvider);
                  },
                ),
                data: (state) => SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTabs(),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),

                      // Chips
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildChip(
                                icon: Icons.calendar_today,
                                label: 'Today',
                                isSelected: _selectedDateFilter == 0,
                                onTap: () => _onFilterChanged(0),
                              ),
                              const SizedBox(width: 12),
                              _buildChip(
                                icon: Icons.calendar_month,
                                label: 'This Week',
                                isSelected: _selectedDateFilter == 1,
                                onTap: () => _onFilterChanged(1),
                              ),
                              const SizedBox(width: 12),
                              _buildChip(
                                icon: Icons.date_range,
                                label:
                                    _selectedDateFilter == 2 &&
                                        _selectedDateRange != null
                                    ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}'
                                    : 'Range',
                                isSelected: _selectedDateFilter == 2,
                                onTap: _selectDateRange,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Dynamic Content based on Tab
                      _buildTabContent(state),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
              secondary: AppColors.primary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedDateFilter = 2;
      });
      _updateProviders(picked);
    }
  }

  void _onFilterChanged(int index) {
    setState(() => _selectedDateFilter = index);

    DateTime now = DateTime.now();
    DateTimeRange range;

    if (index == 0) {
      // Today
      range = DateTimeRange(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    } else if (index == 1) {
      // This Week
      // Monday start
      final start = now.subtract(Duration(days: now.weekday - 1));
      range = DateTimeRange(
        start: DateTime(start.year, start.month, start.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    } else {
      // Range (handled by picker, but if clicked without picker?)
      // Should probably open picker or keep existing
      if (_selectedDateRange != null) {
        range = _selectedDateRange!;
      } else {
        return; // Wait for picker
      }
    }

    _updateProviders(range);
  }

  void _updateProviders(DateTimeRange range) {
    // Update Reports Filter
    ref.read(reportsFilterProvider.notifier).setRange(range);

    // Update Expenses Tab Filter (sync)
    ref
        .read(expenseFilterProvider.notifier)
        .setFilter(ExpenseFilter(startDate: range.start, endDate: range.end));
  }

  Widget _buildTabContent(ReportsState state) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildSalesView(state);
      case 1:
        return _buildPurchasesView(state);
      case 2:
        return const Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: ExpenseStatisticsView(),
        );
      case 3:
      default:
        return _buildSummaryView(state);
    }
  }

  Widget _buildSalesView(ReportsState state) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    // Normalize monthly sales for bar chart (0.0 to 1.0)
    final maxSale = state.monthlySales.reduce(
      (curr, next) => curr > next ? curr : next,
    );
    final normalizedBars = state.monthlySales
        .map((e) => maxSale > 0 ? e / maxSale : 0.0)
        .toList();

    return Column(
      children: [
        // Sales Chart Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildChartSection(
            title: 'Total Sales',
            amount: formatter.format(state.totalSales),
            percentage: '+${state.salesGrowth.toStringAsFixed(1)}%',
            percentageColor: state.salesGrowth >= 0
                ? AppColors.primary
                : Colors.red,
            primaryColor: AppColors.primary,
            bars: normalizedBars,
          ),
        ),
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Top Performers',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: state.topCustomers.map((performer) {
              return Column(
                children: [
                  _buildSummaryCard(
                    title: 'Top Customer',
                    value: formatter.format(performer.amount),
                    subtitle: performer
                        .name, // Display Name as subtitle for now to match old design structure? Or swap?
                    // Old design: Title: Top Customer, Value: Total, Subtitle: Name.
                    // Let's swap: Title: Customer Name. Value: Amount. Subtitle: 'Top Customer'
                    // Actually let's stick to design: Title "Top Customer", Value "Total: ...", Subtitle "Name"
                    icon: Icons.person,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.primary.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchasesView(ReportsState state) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    final maxPurchase = state.monthlyPurchases.reduce(
      (curr, next) => curr > next ? curr : next,
    );
    final normalizedBars = state.monthlyPurchases
        .map((e) => maxPurchase > 0 ? e / maxPurchase : 0.0)
        .toList();

    return Column(
      children: [
        // Purchase Chart Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildChartSection(
            title: 'Total Purchases',
            amount: formatter.format(state.totalPurchases),
            percentage: '+${state.purchaseGrowth.toStringAsFixed(1)}%',
            percentageColor: state.purchaseGrowth >= 0
                ? AppColors.accentOrange
                : Colors
                      .red, // Orange for purchase growth? Maybe red if cost increases? sticking to design
            primaryColor: AppColors.accentOrange,
            bars: normalizedBars,
          ),
        ),
        const SizedBox(height: 24),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Spending Insights',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: state.topSuppliers.map((performer) {
              return Column(
                children: [
                  _buildSummaryCard(
                    title: 'Top Supplier',
                    value: formatter.format(performer.amount),
                    subtitle: performer.name,
                    icon: Icons.local_shipping,
                    iconColor: AppColors.accentOrange,
                    iconBgColor: AppColors.accentOrange.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryView(ReportsState state) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    return Column(
      children: [
        // Main Chart Section (Summary - Sales mainly?)
        // Reusing Sales chart for summary but maybe combining?
        // Let's us total Revenue (sales) for Monthly Performance chart
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildChartSection(
            title: 'Monthly Performance',
            amount: formatter.format(state.totalSales),
            percentage: '+${state.salesGrowth.toStringAsFixed(1)}%',
            percentageColor: AppColors.primary,
            primaryColor: AppColors.primary,
            bars: state.monthlySales.map((e) {
              final max = state.monthlySales.reduce(
                (curr, next) => curr > next ? curr : next,
              );
              return max > 0 ? e / max : 0.0;
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Business Highlights',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Summary Cards Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildSummaryCard(
                title: 'Monthly Sales',
                value: formatter.format(state.monthlySales.last),
                subtitle: 'Current Month',
                icon: Icons.trending_up,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.primary.withOpacity(0.1),
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                title: 'Total Expenses',
                value: formatter.format(state.monthlyExpenses.last),
                subtitle: 'Current Month',
                icon: Icons.money_off,
                iconColor: Colors.deepOrange,
                iconBgColor: Colors.deepOrange.withOpacity(0.1),
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                title: 'Net Profit (Est)',
                value: formatter.format(
                  state.monthlySales.last -
                      state.monthlyPurchases.last -
                      state.monthlyExpenses.last,
                ),
                subtitle: 'Sales - Purchases - Expenses',
                icon: Icons.account_balance_wallet,
                iconColor: Colors.blue,
                iconBgColor: Colors.blue.withOpacity(0.1),
                subtitleColor: AppColors.greyText,
              ),
              // Removed "Best Day" as we verify simplicity required for now
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection({
    required String title,
    required String amount,
    required String percentage,
    required Color primaryColor,
    required List<double> bars,
    Color? percentageColor,
  }) {
    // Generate month labels for last 6 months
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i), 1);
      return DateFormat('MMM').format(d).toUpperCase();
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.greyText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amount,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 24, // Reduced slightly to fit huge numbers
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (percentageColor ?? primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  percentage,
                  style: TextStyle(
                    color: percentageColor ?? primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Chart Bars
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return Expanded(
                  child: _buildBar(
                    primaryColor,
                    months[index],
                    bars.length > index ? bars[index] : 0.0,
                    bars.length > index ? bars[index] > 0 : false,
                    isCurrent: index == 5,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Expanded(
            child: Text(
              'Reports & Analytics',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          // const SizedBox(width: 40), // No back button so no balancing needed if title centered by Expanded
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab('Sales', 0, AppColors.primary),
          _buildTab('Purchases', 1, AppColors.accentOrange),
          _buildTab('Expense', 2, Colors.purple),
          _buildTab('Summary', 3, AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, Color activeColor) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? activeColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? activeColor : AppColors.greyText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    Color activeColor = AppColors.primary;
    if (_selectedTabIndex == 1) activeColor = AppColors.accentOrange;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor.withOpacity(0.2)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(
    Color color,
    String label,
    double fillPercentage,
    bool isColored, {
    bool isCurrent = false,
  }) {
    Color barColor;
    if (isColored) {
      barColor = isCurrent ? color.withOpacity(0.8) : color;
    } else {
      barColor = const Color(0xFFE5E7EB);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fillPercentage > 0
                  ? fillPercentage
                  : 0.05, // Minimum height for visibility
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isColored ? color : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    Color? subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.greyText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor ?? AppColors.primary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
        ],
      ),
    );
  }
}
