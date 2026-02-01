import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/features/suppliers/domain/entities/supplier.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:shop_ledger/core/widgets/common_error_widget.dart';

class SupplierLedgerPage extends ConsumerWidget {
  final Supplier supplier;

  const SupplierLedgerPage({super.key, required this.supplier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We'll trust the supplier ID is not null as it comes from list
    final transactionsAsync = ref.watch(
      supplierTransactionListProvider(supplier.id!),
    );

    // Use the supplier passed in directly to avoid re-watching the whole list
    final currentSupplier = supplier;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.background,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    currentSupplier.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              if (currentSupplier.phone.isNotEmpty)
                Text(
                  currentSupplier.phone,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.textMuted,
                  ),
                ),
            ],
          ),
          backgroundColor: context.appBarBackground,
          elevation: 0,
          actions: [
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: context.subtleBackground,
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                offset: const Offset(0, 50),
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                icon: Icon(
                  Icons.more_vert,
                  color: context.textPrimary,
                  size: 20,
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmDelete(context, ref);
                  } else if (value == 'edit') {
                    context.push('/suppliers/add', extra: currentSupplier);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            color: context.textPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Edit Supplier',
                            style: GoogleFonts.inter(
                              color: context.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Delete Supplier',
                            style: GoogleFonts.inter(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ),
          ],
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),

        body: Column(
          children: [
            // Summary Card
            _buildSummaryCard(context, supplier, ref),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push(
                          '/suppliers/${supplier.id}/payment',
                          extra: supplier,
                        );
                      },
                      icon: const Icon(Icons.payments, color: Colors.red),
                      label: const Text('Pay Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push(
                          '/suppliers/${supplier.id}/purchase',
                          extra: supplier,
                        );
                      },
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        color: Colors.white,
                      ),
                      label: const Text('Purchase'),
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(fontSize: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: context.textMuted,
                indicatorColor: AppColors.primary,
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: "Purchases"),
                  Tab(text: "Payments"),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab View
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  final purchases = transactions
                      .where((t) => t.type == TransactionType.purchase)
                      .toList();
                  final payments = transactions
                      .where((t) => t.type == TransactionType.paymentOut)
                      .toList();

                  return TabBarView(
                    children: [
                      _buildTransactionList(
                        context,
                        purchases,
                        "No purchases yet",
                      ),
                      _buildTransactionList(
                        context,
                        payments,
                        "No payments yet",
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(
                  child: CommonErrorWidget(
                    error: e,
                    onRetry: () {
                      ref.refresh(
                        supplierTransactionListProvider(supplier.id!),
                      );
                    },
                    fullScreen: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<Transaction> transactions,
    String emptyMsg,
  ) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          emptyMsg,
          style: GoogleFonts.inter(color: context.textMuted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildLedgerItem(
          context,
          transaction: transaction,
          index: index,
        );
      },
    );
  }

  Widget _buildLedgerItem(
    BuildContext context, {
    required Transaction transaction,
    required int index,
  }) {
    final isCredit = transaction.type == TransactionType.purchase;
    final amountColor = isCredit ? context.textPrimary : Colors.red;

    String title;
    if (transaction.type == TransactionType.purchase) {
      title = 'Purchase';
    } else {
      title = 'Payment Out';
    }

    return GestureDetector(
      onTap: () {
        context.push(
          '/suppliers/${supplier.id}/transaction',
          extra: transaction,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMM').format(transaction.date),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  DateFormat('hh:mm a').format(transaction.date),
                  style: TextStyle(fontSize: 10, color: context.textMuted),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCredit
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCredit ? Icons.shopping_cart : Icons.payments,
                size: 16,
                color: isCredit ? AppColors.primary : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  if (transaction.details != null &&
                      transaction.details!.isNotEmpty)
                    Text(
                      transaction.details!,
                      style: TextStyle(fontSize: 12, color: context.textMuted),
                      maxLines: 1, // Limited to 1 line
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount (Right aligned)
            Text(
              '₹${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    Supplier supplier,
    WidgetRef ref,
  ) {
    final stats = ref.watch(supplierStatsProvider(supplier.id!));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OUTSTANDING BALANCE',
              style: TextStyle(
                color: context.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${stats.outstandingBalance.toStringAsFixed(2)}',
              style: TextStyle(
                color: stats.outstandingBalance > 0
                    ? context.textPrimary
                    : AppColors.primary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: context.borderColor),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Purchased',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${stats.totalPurchased.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 32, color: context.borderColor),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Paid',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${stats.totalPaid.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Supplier'),
          content: Text(
            'Are you sure you want to delete ${supplier.name}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      if (context.mounted) {
        _deleteSupplier(context, ref);
      }
    }
  }

  Future<void> _deleteSupplier(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(supplierListProvider.notifier)
          .deleteSupplier(supplier.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplier deleted successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting supplier: $e')));
      }
    }
  }
}
