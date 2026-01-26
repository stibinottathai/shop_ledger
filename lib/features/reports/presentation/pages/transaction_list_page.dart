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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Transactions',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search transactions, customers...',
                        hintStyle: GoogleFonts.inter(
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).hintColor,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        isDense: true,
                      ),
                      style: GoogleFonts.inter(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
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
              color: Theme.of(
                context,
              ).scaffoldBackgroundColor.withOpacity(0.95),
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
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
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
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  filter,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
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
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
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
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
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
    Color iconBaseColor;
    IconData icon;
    String typeLabel;
    String statusLabel;

    // Status text color is usually muted/secondary in detailed view but here we can make it dynamic
    // or keep it semi-colored. Let's stick to muted for status label text itself if generic,
    // or colored if specific. Original code had statusColor.
    Color statusColor;

    switch (transaction.type) {
      case TransactionType.sale:
        iconBaseColor = const Color(0xFF3B82F6); // Blue 500
        icon = Icons.storefront;
        typeLabel = "Sale";
        statusLabel = "COMPLETED";
        statusColor =
            Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
        break;
      case TransactionType.paymentIn:
        iconBaseColor = const Color(0xFF10B981); // Income Green
        icon = Icons.arrow_downward;
        typeLabel = "Payment In";
        statusLabel = "RECEIVED";
        statusColor =
            Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
        break;
      case TransactionType.purchase:
        iconBaseColor = const Color(0xFFF59E0B); // Amber 500
        icon = Icons.shopping_bag;
        typeLabel = "Purchase";
        statusLabel = "PENDING";
        statusColor = const Color(0xFFF59E0B); // Amber keeps color
        break;
      case TransactionType.paymentOut:
        iconBaseColor = const Color(0xFFEF4444); // Expense Red
        icon = Icons.arrow_upward;
        typeLabel = "Payment Out";
        statusLabel = "PAID";
        statusColor =
            Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
        break;
    }

    final dateStr = DateFormat('dd MMM yyyy').format(transaction.date);
    final name =
        transaction.customerName ?? transaction.supplierName ?? 'Unknown';

    // For amount color:
    // Income/Sale -> Text Main or specific Green?
    // Original: Sale -> Text Main, Payment In -> Green, Payment Out -> Red.
    // In Dark Mode, Text Main should be white.
    Color amountColor;
    if (transaction.type == TransactionType.paymentIn) {
      amountColor = const Color(0xFF10B981);
    } else if (transaction.type == TransactionType.paymentOut) {
      amountColor = const Color(0xFFEF4444);
    } else {
      amountColor =
          Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
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
          Expanded(
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: iconBaseColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconBaseColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              "•",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
                  color: statusColor,
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
