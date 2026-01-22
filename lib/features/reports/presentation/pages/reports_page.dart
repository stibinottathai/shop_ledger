import 'package:flutter/material.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int _selectedTabIndex = 2; // Default to 'Summary' (2)
  int _selectedDateFilter = 0; // 0: Today, 1: This Week, 2: Range
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildAppBar(context),

            // Main Content Scrolls
            Expanded(
              child: SingleChildScrollView(
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
                              onTap: () =>
                                  setState(() => _selectedDateFilter = 0),
                            ),
                            const SizedBox(width: 12),
                            _buildChip(
                              icon: Icons.calendar_month,
                              label: 'This Week',
                              isSelected: _selectedDateFilter == 1,
                              onTap: () =>
                                  setState(() => _selectedDateFilter = 1),
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
                    _buildTabContent(),
                  ],
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
    } else if (_selectedDateFilter != 2 && _selectedDateRange == null) {
      // If no range picked and not already on range tab, don't switch.
      // But if user tapped specific range button, maybe we should switch to 2 anyway?
      // For now let's just do nothing if cancelled.
    } else {
      // If they tap custom range but don't pick one, maybe we should keep it selected if it was already selected?
      setState(() {
        _selectedDateFilter = 2;
      });
    }
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildSalesView();
      case 1:
        return _buildPurchasesView();
      case 2:
      default:
        return _buildSummaryView();
    }
  }

  Widget _buildSalesView() {
    return Column(
      children: [
        // Sales Chart Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildChartSection(
            title: 'Total Sales',
            amount: '₹4,82,450',
            percentage: '+15.2%',
            primaryColor: AppColors.primary,
            bars: [0.55, 0.40, 0.70, 0.50, 0.90, 0.80], // Dummy sales data
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
            children: [
              _buildSummaryCard(
                title: 'Top Customer',
                value: 'Total: ₹52,400',
                subtitle: 'Rajesh Kumar',
                icon: Icons.person,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.primary.withOpacity(0.1),
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                title: 'Best Selling Item',
                value: '450 Crates',
                subtitle: 'Yelakki Banana',
                icon: Icons.local_offer,
                iconColor: Colors.blue,
                iconBgColor: Colors.blue.withOpacity(0.1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPurchasesView() {
    return Column(
      children: [
        // Purchase Chart Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildChartSection(
            title: 'Total Purchases',
            amount: '₹3,12,000',
            percentage: '+8.4%',
            primaryColor: AppColors.accentOrange,
            bars: [0.35, 0.25, 0.50, 0.40, 0.60, 0.75], // Dummy purchase data
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
            children: [
              _buildSummaryCard(
                title: 'Top Supplier',
                value: 'Total: ₹1,12,000',
                subtitle: 'Patel Banana Farms',
                icon: Icons.local_shipping,
                iconColor: AppColors.accentOrange,
                iconBgColor: AppColors.accentOrange.withOpacity(0.1),
                subtitleColor: AppColors.accentOrange,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                title: 'Pending Payments',
                value: '₹45,000',
                subtitle: 'Due within 7 days',
                icon: Icons.schedule,
                iconColor: Colors.red,
                iconBgColor: Colors.red.withOpacity(0.1),
                subtitleColor: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryView() {
    return Column(
      children: [
        // Main Chart Section (Summary)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildChartSection(
            title: 'Monthly Performance',
            amount: '₹4,52,000',
            percentage: '+12.5%',
            primaryColor: AppColors.primary,
            bars: [0.45, 0.30, 0.60, 0.40, 0.85, 1.0],
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
                title: 'Monthly Total',
                value: '₹4,52,000',
                subtitle: 'Up from last month',
                icon: Icons.trending_up,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.primary.withOpacity(0.1),
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                title: 'Gross Difference',
                value: '₹85,000',
                subtitle: 'Net profit margin',
                icon: Icons.account_balance_wallet,
                iconColor: Colors.blue,
                iconBgColor: Colors.blue.withOpacity(0.1),
                subtitleColor: AppColors.greyText,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                title: 'Best Day',
                value: '₹42,300',
                subtitle: 'Tuesday, Dec 12',
                icon: Icons.workspace_premium,
                iconColor: Colors.amber,
                iconBgColor: Colors.amber.withOpacity(0.1),
                subtitleColor: AppColors.greyText,
              ),
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
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  percentage,
                  style: TextStyle(
                    color: primaryColor,
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
              children: [
                _buildBar(primaryColor, 'JUL', bars[0], false),
                _buildBar(primaryColor, 'AUG', bars[1], false),
                _buildBar(primaryColor, 'SEP', bars[2], false),
                _buildBar(primaryColor, 'OCT', bars[3], false),
                _buildBar(primaryColor, 'NOV', bars[4], true, isCurrent: true),
                _buildBar(primaryColor, 'DEC', bars[5], true),
              ].map((e) => Expanded(child: e)).toList(),
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
          const SizedBox(width: 40),
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
          _buildTab('Summary', 2, AppColors.primary),
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
              heightFactor: fillPercentage,
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
