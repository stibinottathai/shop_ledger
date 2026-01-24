import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/reports/presentation/providers/all_transactions_provider.dart';

class TransactionListPage extends ConsumerStatefulWidget {
  const TransactionListPage({super.key});

  @override
  ConsumerState<TransactionListPage> createState() =>
      _TransactionListPageState();
}

class _TransactionListPageState extends ConsumerState<TransactionListPage> {
  String _selectedFilter = 'Today';
  final List<String> _filters = [
    'Today',
    'Last Week',
    'This Month',
    'Last Year',
    'All Time',
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    // Custom Gradient for Selected Filter (Amber-Green roughly based on request)
    final gradient = const LinearGradient(
      colors: [Color(0xFF84CC16), Color(0xFF22C55E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // background-light
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              color: const Color(0xFFFAFAFA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transactions',
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827), // text-main-light
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6), // subtle-light
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search transactions, customers...',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF6B7280), // text-sec-light
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF6B7280),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        isDense: true,
                      ),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter Chips
            Container(
              height: 60,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: const Color(0xFFFAFAFA).withOpacity(0.95),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = filter == _selectedFilter;

                  if (isSelected) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {}, // Already selected
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  filter,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => setState(() => _selectedFilter = filter),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: Text(
                              filter,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),

            // List
            Expanded(
              child: transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (allTransactions) {
                  final filteredTransactions = _filterTransactions(
                    allTransactions,
                    _searchController.text,
                  );

                  if (filteredTransactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions found',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      return ref.refresh(allTransactionsProvider);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      itemCount: filteredTransactions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(
                          filteredTransactions[index],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Transaction> _filterTransactions(
    List<Transaction> transactions,
    String query,
  ) {
    var result = transactions;

    // Date Filtering
    if (_selectedFilter != 'All Time') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      result = result.where((tx) {
        final txDate = tx.date;
        final txDay = DateTime(txDate.year, txDate.month, txDate.day);

        switch (_selectedFilter) {
          case 'Today':
            return txDay.isAtSameMomentAs(today);
          case 'Last Week':
            final lastWeekStart = today.subtract(const Duration(days: 7));
            return (txDay.isAfter(lastWeekStart) &&
                    txDay.isBefore(today.add(const Duration(days: 1)))) ||
                txDay.isAtSameMomentAs(lastWeekStart) ||
                txDay.isAtSameMomentAs(today);
          case 'This Month':
            return txDate.year == now.year && txDate.month == now.month;
          case 'Last Year':
            return txDate.year == now.year - 1;
          default:
            return true;
        }
      }).toList();
    }

    // Search Filtering
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      result = result.where((tx) {
        final name = (tx.customerName ?? tx.supplierName ?? '').toLowerCase();
        final amount = tx.amount.toString();
        // final details = (tx.details ?? '').toLowerCase();
        return name.contains(lowerQuery) || amount.contains(lowerQuery);
      }).toList();
    }

    return result;
  }

  Widget _buildTransactionCard(Transaction transaction) {
    // Colors from Request logic
    Color iconBg;
    Color iconColor;
    IconData icon;
    String typeLabel;
    Color amountColor;
    String statusLabel;
    Color statusColor = const Color(0xFF6B7280); // Default grey

    switch (transaction.type) {
      case TransactionType.sale:
        iconBg = const Color(0xFFEFF6FF); // Blue 50
        iconColor = const Color(0xFF3B82F6); // Blue 500
        icon = Icons.storefront;
        typeLabel = "Sale";
        amountColor = const Color(0xFF111827); // Text Main
        statusLabel = "COMPLETED";
        statusColor = const Color(0xFF6B7280);
        break;
      case TransactionType.paymentIn:
        iconBg = const Color(0xFFECFDF5); // Green 50
        iconColor = const Color(0xFF10B981); // Income Green
        icon = Icons.arrow_downward;
        typeLabel = "Payment In";
        amountColor = const Color(0xFF10B981); // Income Green
        statusLabel = "RECEIVED";
        statusColor = const Color(0xFF6B7280);
        break;
      case TransactionType.purchase:
        iconBg = const Color(0xFFFFFBEB); // Amber 50
        iconColor = const Color(0xFFF59E0B); // Amber 500
        icon = Icons.shopping_bag;
        typeLabel = "Purchase";
        amountColor = const Color(0xFF111827);
        statusLabel = "PENDING";
        statusColor = const Color(0xFFF59E0B); // Amber
        break;
      case TransactionType.paymentOut:
        iconBg = const Color(0xFFFEF2F2); // Red 50
        iconColor = const Color(0xFFEF4444); // Expense Red
        icon = Icons.arrow_upward;
        typeLabel = "Payment Out";
        amountColor = const Color(0xFFEF4444); // Expense Red
        statusLabel = "PAID";
        statusColor = const Color(0xFF6B7280);
        break;
    }

    final dateStr = DateFormat('dd MMM yyyy').format(transaction.date);
    final name =
        transaction.customerName ?? transaction.supplierName ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Side
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          "•",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      Text(
                        dateStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Right Side
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(transaction.amount),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color:
                      statusColor, // Using specific status color or default grey
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }
}
