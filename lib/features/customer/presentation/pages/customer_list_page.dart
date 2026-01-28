import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/customer/domain/entities/customer.dart';
import 'package:shop_ledger/features/customer/presentation/providers/customer_provider.dart';
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';

import 'package:shop_ledger/core/widgets/common_error_widget.dart';

class CustomerListPage extends ConsumerStatefulWidget {
  const CustomerListPage({super.key});

  @override
  ConsumerState<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends ConsumerState<CustomerListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerListAsync = ref.watch(customerListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFC),
              border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Text(
                          'Customers',
                          style: GoogleFonts.inter(
                            color: AppColors.textMain,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.slate100),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final notifier = ref.read(customerListProvider.notifier);
                      final currentSort = notifier.sortOption;

                      return PopupMenuButton<CustomerSortOption>(
                        padding: EdgeInsets.zero,
                        offset: const Offset(0, 50),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                currentSort == CustomerSortOption.latestCreated
                                ? Colors.transparent
                                : AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.filter_list,
                            size: 20,
                            color:
                                currentSort == CustomerSortOption.latestCreated
                                ? AppColors.slate600
                                : AppColors.primary,
                          ),
                        ),
                        onSelected: (option) {
                          notifier.setSortOption(option);
                        },
                        itemBuilder: (context) => [
                          _buildFilterItem(
                            CustomerSortOption.mostDue,
                            'Most Due',
                            currentSort,
                          ),
                          _buildFilterItem(
                            CustomerSortOption.lowestDue,
                            'Lowest Due',
                            currentSort,
                          ),
                          const PopupMenuDivider(),
                          _buildFilterItem(
                            CustomerSortOption.latestUpdated,
                            'Latest Updated',
                            currentSort,
                          ),
                          _buildFilterItem(
                            CustomerSortOption.latestCreated,
                            'Latest Created',
                            currentSort,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Search and List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  // Search Bar
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 48, // Consistent height for search bars usually
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.05),
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.01),
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                      ),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          ref
                              .read(customerListProvider.notifier)
                              .searchCustomers(value);
                        },
                        style: GoogleFonts.inter(
                          color: AppColors.textMain,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.slate400,
                            size: 20,
                          ),
                          hintText: 'Search customers...',
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.slate400,
                          ),
                          border: InputBorder.none,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 2.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.slate200,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // List Header
                  customerListAsync.when(
                    data: (customers) {
                      return Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ALL CUSTOMERS (${customers.length})',
                                  style: GoogleFonts.inter(
                                    color: AppColors.slate400,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Customer List Container
                            Expanded(
                              child: customers.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No customers found',
                                        style: GoogleFonts.inter(
                                          color: AppColors.slate400,
                                        ),
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: () async {
                                        // Ignoring the return value is fine here as onRefresh expects a Future
                                        // and ref.refresh returns the new state, but we just need to wait for it.
                                        // However, ref.refresh is synchronous for providers.
                                        // Ideally we invalidate and read to trigger rebuild.
                                        // But invalidating generic providers is simpler.
                                        // Actually `ref.refresh` re-executes the provider immediately and returns the result.
                                        // If it returns a Future (for FutureProvider), we can await it.
                                        // customerListProvider is likely a FutureProvider or similar.
                                        // Let's assume it returns a generic async value or we can just invalidate.
                                        return ref.refresh(
                                          customerListProvider.future,
                                        );
                                      },
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: customers.length,
                                        itemBuilder: (context, index) {
                                          final customer = customers[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: _buildCustomerItem(customer),
                                          );
                                        },
                                      ),
                                    ),
                            ),
                            const SizedBox(
                              height: 20,
                            ), // Bottom padding for FAB space
                          ],
                        ),
                      );
                    },
                    loading: () => const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, stackTrace) => Expanded(
                      child: CommonErrorWidget(
                        error: error,
                        onRetry: () {
                          ref.refresh(customerListProvider);
                        },
                        fullScreen: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24, right: 24),
        child: SizedBox(
          width: 56,
          height: 56,
          child: FloatingActionButton(
            heroTag: 'customer_add_fab',
            onPressed: () {
              context.go('/customers/add');
            },
            backgroundColor: AppColors.primary,
            elevation:
                0, // Shadow handled by container in logic/design usually, but FAB has default
            shape: const CircleBorder(),
            // Custom shadow matching design "shadow-float"
            // "0 10px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -4px rgba(0, 0, 0, 0.025)"
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    offset: Offset(0, 10),
                    blurRadius: 15,
                    spreadRadius: -3,
                  ),
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.025),
                    offset: Offset(0, 4),
                    blurRadius: 6,
                    spreadRadius: -4,
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

  PopupMenuItem<CustomerSortOption> _buildFilterItem(
    CustomerSortOption option,
    String label,
    CustomerSortOption currentSort,
  ) {
    final isSelected = option == currentSort;
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: isSelected ? AppColors.primary : AppColors.slate400,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? AppColors.primary : AppColors.textMain,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerItem(Customer customer) {
    return CustomerListItem(customer: customer);
  }
}

class CustomerListItem extends ConsumerWidget {
  final Customer customer;

  const CustomerListItem({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(customerStatsProvider(customer.id!));

    // Determine avatar color logic (cycling through branding colors)
    final colors = [
      AppColors.emerald500,
      AppColors.teal600,
      AppColors.indigo500,
      AppColors.orange400,
    ];
    // Simple hash for consistent color
    final colorIndex = customer.name.length % colors.length;
    final avatarColor = colors[colorIndex];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.01),
            offset: Offset(0, 1),
            blurRadius: 2,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.go('/customers/${customer.id}', extra: customer);
          },
          borderRadius: BorderRadius.circular(16),
          hoverColor: AppColors.slate50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  height: 48, // Increased size for better visual
                  width: 48,
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: avatarColor.withOpacity(0.2)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    customer.name.isNotEmpty
                        ? customer.name
                              .substring(0, math.min(2, customer.name.length))
                              .toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      color: avatarColor, // Colored text on light bg (elegant)
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name & Phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: GoogleFonts.inter(
                          color: AppColors.textMain,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer.phone,
                        style: GoogleFonts.inter(
                          color: AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Balance & Chevron
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${stats.outstandingBalance.abs().toStringAsFixed(2)}",
                          style: GoogleFonts.inter(
                            color: stats.outstandingBalance > 0
                                ? AppColors.danger
                                : stats.outstandingBalance < 0
                                ? AppColors.emerald500
                                : AppColors.textMain,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          stats.outstandingBalance > 0
                              ? "DUE"
                              : stats.outstandingBalance < 0
                              ? "ADVANCE"
                              : "PAID",
                          style: GoogleFonts.inter(
                            color: stats.outstandingBalance > 0
                                ? AppColors.danger
                                : stats.outstandingBalance < 0
                                ? AppColors.emerald500
                                : AppColors.emerald500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.slate300,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
