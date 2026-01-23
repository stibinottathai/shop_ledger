import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/customer/domain/entities/customer.dart';
import 'package:shop_ledger/features/customer/presentation/providers/customer_provider.dart';
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';

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
                        padding: const EdgeInsets.only(
                          left: 40,
                        ), // Balance the right button
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
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.settings, size: 20),
                    color: AppColors.slate600,
                    onPressed: () {},
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
                              width: 2,
                            ),
                          ),
                          enabledBorder: InputBorder.none,
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
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.slate100,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color.fromRGBO(
                                              0,
                                              0,
                                              0,
                                              0.05,
                                            ),
                                            offset: Offset(0, 1),
                                            blurRadius: 3,
                                          ),
                                          BoxShadow(
                                            color: Color.fromRGBO(
                                              0,
                                              0,
                                              0,
                                              0.01,
                                            ),
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                            spreadRadius: -1,
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        itemCount: customers.length,
                                        separatorBuilder: (context, index) =>
                                            const Divider(
                                              height: 1,
                                              thickness: 1,
                                              color: AppColors.slate50,
                                            ),
                                        itemBuilder: (context, index) {
                                          final customer = customers[index];
                                          return _buildCustomerItem(customer);
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
                    error: (error, stackTrace) =>
                        Expanded(child: Center(child: Text('Error: $error'))),
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

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          context.go('/customers/${customer.id}', extra: customer);
        },
        hoverColor: AppColors.slate50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.05),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name
                            .substring(0, math.min(2, customer.name.length))
                            .toUpperCase()
                      : '?',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: GoogleFonts.inter(
                        color: AppColors.textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                              ? AppColors
                                    .emerald500 // Or textMain if 0? Design shows Paid as green/textMain structure
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
    );
  }
}
