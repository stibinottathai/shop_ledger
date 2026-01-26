import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shop_ledger/core/services/pdf_service.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shop_ledger/features/auth/presentation/providers/auth_provider.dart';
import 'package:shop_ledger/features/customer/domain/entities/customer.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/customer/presentation/providers/customer_provider.dart';
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shop_ledger/core/widgets/common_error_widget.dart';

class CustomerDetailPage extends ConsumerWidget {
  final Customer customer;

  const CustomerDetailPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(customerStatsProvider(customer.id!));
    final transactionsAsync = ref.watch(transactionListProvider(customer.id!));

    // Watch for customer updates
    final currentCustomer = ref
        .watch(customerListProvider)
        .maybeWhen(
          data: (customers) => customers.cast<Customer>().firstWhere(
            (c) => c.id == customer.id,
            orElse: () => customer,
          ),
          orElse: () => customer,
        );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentCustomer.name,
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              currentCustomer.phone,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.call,
                color: Theme.of(context).iconTheme.color,
                size: 20,
              ),
              onPressed: () {
                if (currentCustomer.phone.isNotEmpty) {
                  _makePhoneCall(context, currentCustomer.phone);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No phone number available')),
                  );
                }
              },
            ),
          ),
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor, // Was grey[100]
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              offset: const Offset(0, 50),
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.1),
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).iconTheme.color,
                size: 20,
              ),
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmation(context, ref);
                } else if (value == 'edit') {
                  context.push('/customers/add', extra: currentCustomer);
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
                          color: Theme.of(context).iconTheme.color,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Edit Customer',
                          style: GoogleFonts.inter(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
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
                          'Delete Customer',
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
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Summary Card
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'OUTSTANDING BALANCE',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                if (stats.outstandingBalance > 0)
                                  transactionsAsync.maybeWhen(
                                    data: (transactions) => IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: const FaIcon(
                                        FontAwesomeIcons.whatsapp,
                                        color: Color(0xFF25D366),
                                        size: 24,
                                      ),
                                      onPressed: () => _openWhatsApp(
                                        context,
                                        ref,
                                        currentCustomer,
                                        transactions,
                                        stats.outstandingBalance,
                                      ),
                                    ),
                                    orElse: () => const SizedBox.shrink(),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${stats.outstandingBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: stats.outstandingBalance > 0
                                    ? AppColors.danger
                                    : Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.color,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Theme.of(context).dividerColor),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Sales',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹${stats.totalSales.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: Theme.of(context).dividerColor,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total Paid',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.5),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹${stats.totalPaid.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
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
                    ),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.go(
                                  '/customers/${customer.id}/sale',
                                  extra: customer,
                                );
                              },
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Sale'),
                              style: ElevatedButton.styleFrom(
                                textStyle: const TextStyle(fontSize: 16),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.go(
                                  '/customers/${customer.id}/payment',
                                  extra: customer,
                                );
                              },
                              icon: const Icon(
                                Icons.payments,
                                color: Colors.white,
                              ),
                              label: const Text('Payment In'),
                              style: ElevatedButton.styleFrom(
                                textStyle: const TextStyle(fontSize: 16),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Tab Bar
              SliverPersistentHeader(
                delegate: _PersistentHeaderDelegate(
                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Theme.of(
                      context,
                    ).disabledColor, // Grey in theme
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'Sales'),
                      Tab(text: 'Payments'),
                    ],
                  ),
                  Theme.of(context).scaffoldBackgroundColor, // Pass color
                ),
                pinned: true,
              ),
            ];
          },
          body: transactionsAsync.when(
            data: (transactions) {
              final sales = transactions
                  .where((t) => t.type == TransactionType.sale)
                  .toList();
              final payments = transactions
                  .where((t) => t.type == TransactionType.paymentIn)
                  .toList();

              return TabBarView(
                children: [
                  _buildTransactionList(context, sales, isSale: true),
                  _buildTransactionList(context, payments, isSale: false),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(
              child: CommonErrorWidget(
                error: e,
                onRetry: () {
                  ref.refresh(transactionListProvider(customer.id!));
                },
                fullScreen: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<Transaction> transactions, {
    required bool isSale,
  }) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          isSale ? 'No sales recorded' : 'No payments recorded',
          style: TextStyle(color: Theme.of(context).disabledColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionRow(
          context,
          transaction,
          isShaded: index % 2 == 1,
          onTap: () {
            context.push(
              '/customers/${customer.id}/transaction',
              extra: {'customer': customer, 'transaction': transaction},
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionRow(
    BuildContext context,
    Transaction transaction, {
    required VoidCallback onTap,
    bool isShaded = false,
  }) {
    final date = DateFormat('dd MMM, yyyy').format(transaction.date);
    final details =
        transaction.details ??
        (transaction.type == TransactionType.sale ? 'Sale' : 'Payment');

    final isPayment = transaction.type == TransactionType.paymentIn;
    final amount = '₹${transaction.amount.toStringAsFixed(2)}';
    final amountColor = isPayment
        ? AppColors.primary
        : Theme.of(context).textTheme.bodyLarge?.color;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isShaded
              ? AppColors.primary.withOpacity(0.05)
              : Theme.of(context).cardColor,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  isPayment
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                details,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              amount,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... (Keep existing _showDeleteConfirmation and other methods but they are inside the class)

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Delete Customer',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this customer? This action cannot be undone and will delete all associated transactions.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              context.pop(); // Close dialog
              try {
                // Assuming CustomerProvider has delete method
                await ref
                    .read(customerListProvider.notifier)
                    .deleteCustomer(customer.id!);
                if (context.mounted) {
                  context.pop(); // Go back to list
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting customer: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
    List<Transaction> transactions,
    double amount,
  ) async {
    if (customer.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }

    try {
      // Get shop name from user metadata
      final user = ref.read(authRepositoryProvider).getCurrentUser();
      final shopName = user?.userMetadata?['shop_name'] as String?;

      // Generate PDF
      final pdfService = PdfService();
      final file = await pdfService.generateTransactionPdf(
        customer: customer,
        transactions: transactions,
        outstandingBalance: amount,
        shopName: shopName,
      );

      final cleanNumber = customer.phone.replaceAll(RegExp(r'[^\d]'), '');
      String finalNumber = cleanNumber;
      if (cleanNumber.length == 10) {
        finalNumber = '91$cleanNumber';
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Hello ${customer.name}, please find your account statement attached. Outstanding Balance: ₹${amount.toStringAsFixed(2)}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating/sharing PDF: $e')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    // Remove any non-digit characters for the actual URL
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch dialer')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _PersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor; // Add this

  _PersistentHeaderDelegate(this.tabBar, this.backgroundColor);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _PersistentHeaderDelegate oldDelegate) {
    return backgroundColor != oldDelegate.backgroundColor;
  }
}
