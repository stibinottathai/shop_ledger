import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:shop_ledger/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:shop_ledger/core/widgets/common_error_widget.dart';

class SupplierListPage extends ConsumerStatefulWidget {
  const SupplierListPage({super.key});

  @override
  ConsumerState<SupplierListPage> createState() => _SupplierListPageState();
}

class _SupplierListPageState extends ConsumerState<SupplierListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supplierListAsync = ref.watch(supplierListProvider);

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
                          'Suppliers',
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
                      final notifier = ref.read(supplierListProvider.notifier);
                      final currentSort = notifier.sortOption;

                      return PopupMenuButton<SupplierSortOption>(
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
                                currentSort == SupplierSortOption.latestCreated
                                ? Colors.transparent
                                : AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.filter_list,
                            size: 20,
                            color:
                                currentSort == SupplierSortOption.latestCreated
                                ? AppColors.slate600
                                : AppColors.primary,
                          ),
                        ),
                        onSelected: (option) {
                          notifier.setSortOption(option);
                        },
                        itemBuilder: (context) => [
                          _buildFilterItem(
                            SupplierSortOption.mostToPay,
                            'Most to Pay',
                            currentSort,
                          ),
                          _buildFilterItem(
                            SupplierSortOption.lowestToPay,
                            'Lowest to Pay',
                            currentSort,
                          ),
                          const PopupMenuDivider(),
                          _buildFilterItem(
                            SupplierSortOption.latestUpdated,
                            'Latest Updated',
                            currentSort,
                          ),
                          _buildFilterItem(
                            SupplierSortOption.latestCreated,
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
                        height: 48,
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
                              .read(supplierListProvider.notifier)
                              .searchSuppliers(value);
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
                          hintText: 'Search suppliers...',
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
                  supplierListAsync.when(
                    data: (suppliers) {
                      return Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ALL SUPPLIERS (${suppliers.length})',
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

                            // Supplier List Container
                            Expanded(
                              child: suppliers.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No suppliers found',
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
                                        itemCount: suppliers.length,
                                        separatorBuilder: (context, index) =>
                                            const Divider(
                                              height: 1,
                                              thickness: 1,
                                              color: AppColors.slate50,
                                            ),
                                        itemBuilder: (context, index) {
                                          final supplier = suppliers[index];
                                          return _buildSupplierItem(supplier);
                                        },
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 20),
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
                          ref.refresh(supplierListProvider);
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
            heroTag: 'supplier_add_fab',
            onPressed: () {
              context.go('/suppliers/add');
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

  PopupMenuItem<SupplierSortOption> _buildFilterItem(
    SupplierSortOption option,
    String label,
    SupplierSortOption currentSort,
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

  Widget _buildSupplierItem(Supplier supplier) {
    return SupplierListItem(supplier: supplier);
  }
}

class SupplierListItem extends ConsumerWidget {
  final Supplier supplier;

  const SupplierListItem({super.key, required this.supplier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the overview provider which fetches all stats at once
    final statsMapAsync = ref.watch(supplierOverviewStatsProvider);
    final stats =
        statsMapAsync.value?[supplier.id] ??
        const SupplierStats(
          totalPurchased: 0,
          totalPaid: 0,
          outstandingBalance: 0,
        );

    // Determine avatar color logic (cycling through branding colors)
    final colors = [
      AppColors.emerald500,
      AppColors.teal600,
      AppColors.indigo500,
      AppColors.orange400,
    ];
    // Simple hash for consistent color
    final colorIndex = supplier.name.length % colors.length;
    final avatarColor = colors[colorIndex];

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          context.go('/suppliers/${supplier.id}', extra: supplier);
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
                  supplier.name.isNotEmpty
                      ? supplier.name
                            .substring(0, math.min(2, supplier.name.length))
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
                      supplier.name,
                      style: GoogleFonts.inter(
                        color: AppColors.textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      supplier.phone,
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
                            ? "TO PAY"
                            : stats.outstandingBalance < 0
                            ? "ADVANCE"
                            : "SETTLED",
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
