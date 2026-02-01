import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:native_share/native_share.dart';
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
  double? _cachedOutstandingBalance;

  Future<void> _shareTransaction() async {
    setState(() => _isSharing = true);
    try {
      final user = ref.read(authRepositoryProvider).getCurrentUser();
      final shopName = user?.userMetadata?['shop_name'] as String?;

      final pdfService = PdfService();
      // Use the cached outstanding balance from the last build
      final outstandingBalance = _cachedOutstandingBalance ?? 0.0;
      final file = await pdfService.generateTransactionPdf(
        name: widget.customer.name,
        phone: widget.customer.phone,
        transactions: [widget.transaction],
        outstandingBalance: outstandingBalance,
        shopName: shopName,
        isSingleReceipt: true,
      );

      // Share using native share
      await NativeShare.shareFiles(
        filePaths: [file.path],
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
    // Updated regex to be more flexible and make count optional
    final regex = RegExp(r'^(.*?) \((.*?)\) (.*?)(?: \[(.*?)\])? = (.*?)$');

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
    // Cache the outstanding balance for PDF generation
    _cachedOutstandingBalance = stats.outstandingBalance;
    final isSale = widget.transaction.type == TransactionType.sale;

    // Parse items if it's a sale and has details
    final parsedItems = (isSale && widget.transaction.details != null)
        ? _parseItems(widget.transaction.details!)
        : <Map<String, String>>[];

    // Determine dominant unit
    String unitHeader = 'QTY/WT';
    String? commonUnit;
    bool mixedUnits = false;

    if (parsedItems.isNotEmpty) {
      final firstUnit = parsedItems.first['weight']!
          .replaceAll(RegExp(r'[0-9.]'), '')
          .trim();
      commonUnit = firstUnit;

      for (var item in parsedItems) {
        final currentUnit = item['weight']!
            .replaceAll(RegExp(r'[0-9.]'), '')
            .trim();
        if (currentUnit != commonUnit) {
          mixedUnits = true;
          break;
        }
      }

      if (!mixedUnits && commonUnit.isNotEmpty) {
        if (commonUnit == 'kg') {
          unitHeader = 'WEIGHT';
        } else if (commonUnit == 'pcs') {
          unitHeader = 'PIECES';
        } else if (commonUnit == 'box') {
          unitHeader = 'BOXES';
        } else if (commonUnit == 'l') {
          unitHeader = 'VOLUME';
        } else {
          unitHeader = commonUnit.toUpperCase();
        }
      }
    }

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Transaction Details',
          style: TextStyle(
            color: context.textPrimary,
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
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
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
                            color: context.textMuted,
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
                          style: TextStyle(
                            color: context.textPrimary,
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
                          Expanded(flex: 2, child: _tableHeader(unitHeader)),
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

                        // Format logic: if unified header, strip unit. If mixed, show unit.
                        String quantityDisplay = item['weight']!;
                        if (!mixedUnits && commonUnit != null) {
                          quantityDisplay = quantityDisplay
                              .replaceAll(commonUnit, '')
                              .trim();
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: context.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (item['price']!.isNotEmpty)
                                      Text(
                                        item['price']!,
                                        style: TextStyle(
                                          color: context.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  quantityDisplay,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item['count']!.replaceAll(
                                    ' Nos',
                                    '',
                                  ), // Just show number
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '₹${item['total']}',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: context.textPrimary,
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
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: context.textPrimary,
                        ),
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
                        Text(
                          'TOTAL AMOUNT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.0,
                            color: context.textPrimary,
                          ), // Text style
                        ), // Text
                        Text(
                          '₹${widget.transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: isSale
                                ? context.textPrimary
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSale &&
                      widget.transaction.receivedAmount != null &&
                      widget.transaction.receivedAmount! > 0) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(color: context.borderColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RECEIVED AMOUNT',
                            style: TextStyle(
                              color: context.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '- ₹${widget.transaction.receivedAmount!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: context.subtleBackground,
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'BALANCE',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            '₹${(widget.transaction.amount - widget.transaction.receivedAmount!).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
        color: context.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }
}
