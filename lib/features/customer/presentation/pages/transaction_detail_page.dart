import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shop_ledger/core/services/pdf_service.dart';
import 'package:shop_ledger/core/theme/app_colors.dart';
import 'package:shop_ledger/features/auth/presentation/providers/auth_provider.dart';
import 'package:shop_ledger/features/customer/domain/entities/customer.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
// import 'package:shop_ledger/features/customer/presentation/providers/customer_provider.dart'; // Unused
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';

class TransactionDetailPage extends ConsumerStatefulWidget {
  final Customer customer;
  final Transaction transaction;

  const TransactionDetailPage({
    super.key,
    required this.customer,
    required this.transaction,
  });

  @override
  ConsumerState<TransactionDetailPage> createState() =>
      _TransactionDetailPageState();
}

class _TransactionDetailPageState extends ConsumerState<TransactionDetailPage> {
  bool _isSharing = false;
  bool _isDeleting = false;

  Future<void> _shareTransaction() async {
    setState(() => _isSharing = true);
    try {
      final user = ref.read(authRepositoryProvider).getCurrentUser();
      final shopName = user?.userMetadata?['shop_name'] as String?;

      final pdfService = PdfService();
      // Use existing service but passing only this transaction
      final file = await pdfService.generateTransactionPdf(
        customer: widget.customer,
        transactions: [widget.transaction],
        outstandingBalance:
            0, // Not needed for single receipt ideally but required by signature
        shopName: shopName,
        isSingleReceipt:
            true, // We might need to update PdfService to handle this flag if we want specific receipt format
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Receipt for transaction on ${DateFormat('dd MMM yyyy').format(widget.transaction.date)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      if (widget.transaction.id == null)
        throw Exception('Transaction ID is null');

      await ref
          .read(transactionListProvider(widget.customer.id!).notifier)
          .deleteTransaction(widget.transaction.id!);

      if (mounted) {
        context.pop(); // Go back to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  List<Map<String, String>> _parseItems(String details) {
    if (details.isEmpty) return [];

    final lines = details.split('\n');
    final List<Map<String, String>> items = [];

    // Regex to match: ItemName (Price/kg) Weight [Count Nos] = Total
    // Example: Apple (100/kg) 2kg [5 Nos] = 200
    // Updated regex to be more flexible
    final regex = RegExp(r'^(.*?) \((.*?)\) (.*?) \[(.*?)\] = (.*?)$');

    for (var line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        items.add({
          'item': match.group(1) ?? '',
          'price': match.group(2) ?? '',
          'weight': match.group(3) ?? '',
          'count': match.group(4) ?? '',
          'total': match.group(5) ?? '',
        });
      } else {
        // Fallback for non-matching lines (maybe legacy or simple notes)
        if (line.trim().isNotEmpty) {
          items.add({
            'item': line,
            'price': '',
            'weight': '',
            'count': '',
            'total': '',
          });
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(customerStatsProvider(widget.customer.id!));
    final isSale = widget.transaction.type == TransactionType.sale;

    // Parse items if it's a sale and has details
    final parsedItems = (isSale && widget.transaction.details != null)
        ? _parseItems(widget.transaction.details!)
        : <Map<String, String>>[];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Transaction Details',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _isDeleting ? null : _deleteTransaction,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Outstanding Balance Header
            if (stats.outstandingBalance > 0)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentRed.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Outstanding Balance',
                      style: TextStyle(
                        color: AppColors.accentRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₹${stats.outstandingBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.accentRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

            // Main Bill Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bill Header (Date & ID can go here)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSale ? 'SALE RECEIPT' : 'PAYMENT RECEIPT',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'dd MMMM yyyy, hh:mm a',
                          ).format(widget.transaction.date), // Detailed date
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Item Table
                  if (parsedItems.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: _tableHeader('ITEM')),
                          Expanded(flex: 2, child: _tableHeader('WEIGHT')),
                          Expanded(flex: 2, child: _tableHeader('QTY')),
                          Expanded(
                            flex: 2,
                            child: _tableHeader(
                              'AMOUNT',
                              align: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: parsedItems.length,
                      separatorBuilder: (c, i) =>
                          const Divider(height: 1, indent: 20, endIndent: 20),
                      itemBuilder: (context, index) {
                        final item = parsedItems[index];
                        // If simple row (parsing failed but has content)
                        if (item['total'] == '') {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              item['item']!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['item']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (item['price']!.isNotEmpty)
                                      Text(
                                        item['price']!,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item['weight']!.replaceAll(
                                    'kg',
                                    '',
                                  ), // Just show number
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item['count']!.replaceAll(
                                    ' Nos',
                                    '',
                                  ), // Just show number
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '₹${item['total']}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    // Fallback for no details or Payments
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.transaction.details?.isNotEmpty == true
                            ? widget.transaction.details!
                            : (isSale
                                  ? 'Item details not available'
                                  : 'Payment Received'),
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ],

                  const Divider(height: 1, thickness: 1),

                  // Total Footer
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL AMOUNT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '₹${widget.transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: isSale
                                ? AppColors.textDark
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSharing ? null : _shareTransaction,
                icon: _isSharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.share, color: Colors.white),
                label: Text(_isSharing ? 'Generating PDF...' : 'Share Receipt'),
                style: ElevatedButton.styleFrom(
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
    );
  }

  Widget _tableHeader(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }
}
