import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';
import 'package:shop_ledger/features/customer/presentation/providers/transaction_provider.dart';
import 'package:shop_ledger/features/dashboard/presentation/providers/dashboard_provider.dart';

import 'package:shop_ledger/features/reports/presentation/providers/reports_provider.dart';
import 'package:shop_ledger/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:shop_ledger/core/services/pdf_service.dart';
import 'package:shop_ledger/features/auth/presentation/providers/auth_provider.dart';
import 'package:native_share/native_share.dart';

class SupplierTransactionDetailsPage extends ConsumerStatefulWidget {
  final Transaction transaction;

  const SupplierTransactionDetailsPage({super.key, required this.transaction});

  @override
  ConsumerState<SupplierTransactionDetailsPage> createState() =>
      _SupplierTransactionDetailsPageState();
}

class _SupplierTransactionDetailsPageState
    extends ConsumerState<SupplierTransactionDetailsPage> {
  bool _isLoading = false;
  bool _isSharing = false;

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(transactionRepositoryProvider);
      if (widget.transaction.id != null) {
        await repository.deleteTransaction(widget.transaction.id!);

        await Future.delayed(const Duration(milliseconds: 500));
        ref.read(dashboardStatsProvider.notifier).refresh();
        ref.read(reportsProvider.notifier).refresh();
        ref.read(transactionUpdateProvider.notifier).increment();

        if (widget.transaction.supplierId != null) {
          ref.invalidate(
            supplierTransactionListProvider(widget.transaction.supplierId!),
          );
          ref.invalidate(supplierStatsProvider(widget.transaction.supplierId!));
        }
        ref.invalidate(allTransactionsProvider);

        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction deleted successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting transaction: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper to parse details string
  List<Map<String, String>> _parseItems(String details) {
    if (details.isEmpty) return [];

    if (!details.contains("Items") || !details.contains("Kg")) {
      return [];
    }

    final List<Map<String, String>> items = [];

    // Pattern matches:
    // 1. Count (digits)
    // 2. Weight (decimals)
    // 3. Name & Extras (Everything else until next match)
    final regex = RegExp(
      r'(\d+)\s+Items,\s+([\d\.]+)\s+Kg\s+((?:(?!,\s+\d+\s+Items).)*)',
    );

    final matches = regex.allMatches(details);
    for (final match in matches) {
      String nameAndExtras = match.group(3)?.trim() ?? 'Unknown';
      String rate = '-';
      String total = '-';
      String name = nameAndExtras;

      // Try to extract Rate and Total from the name part
      // Format: "Name (Rate: 150.00, Total: 750.00)"
      final extrasRegex = RegExp(
        r'^(.*?)\s*\(Rate:\s*([\d\.]+),\s*Total:\s*([\d\.]+)\)$',
      );
      final extraMatch = extrasRegex.firstMatch(nameAndExtras);

      if (extraMatch != null) {
        name = extraMatch.group(1) ?? nameAndExtras;
        rate = extraMatch.group(2) ?? '-';
        total = extraMatch.group(3) ?? '-';
      }

      items.add({
        'qty': match.group(1) ?? '0',
        'weight': match.group(2) ?? '0',
        'name': name,
        'rate': rate,
        'total': total,
      });
    }

    return items;
  }

  Future<void> _shareTransaction() async {
    setState(() => _isSharing = true);
    try {
      final user = ref.read(authRepositoryProvider).getCurrentUser();
      final shopName = user?.userMetadata?['shop_name'] as String?;

      // Find supplier details
      String name = 'Supplier';
      String phone = '';
      if (widget.transaction.supplierId != null) {
        final supplierList = ref.read(supplierListProvider).value;
        if (supplierList != null) {
          try {
            final supplier = supplierList.firstWhere(
              (s) => s.id == widget.transaction.supplierId,
            );
            name = supplier.name;
            phone = supplier.phone;
          } catch (_) {}
        }
      }

      final pdfService = PdfService();
      final file = await pdfService.generateTransactionPdf(
        name: name,
        phone: phone,
        transactions: [widget.transaction],
        outstandingBalance: 0,
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

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.transaction.type == TransactionType.purchase;
    final typeLabel = isCredit ? 'PURCHASE RECEIPT' : 'PAYMENT RECEIPT';

    final stats = widget.transaction.supplierId != null
        ? ref.watch(supplierStatsProvider(widget.transaction.supplierId!))
        : null;

    final parsedItems = isCredit && widget.transaction.details != null
        ? _parseItems(widget.transaction.details!)
        : [];

    final hasParsedItems = parsedItems.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Transaction Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _isLoading ? null : _deleteTransaction,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Outstanding Balance Banner
            if (stats != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFEF9A9A).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Outstanding Balance",
                      style: GoogleFonts.inter(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "₹${stats.outstandingBalance.toStringAsFixed(2)}",
                      style: GoogleFonts.inter(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

            // Receipt Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeLabel,
                          style: GoogleFonts.inter(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'dd MMMM yyyy, hh:mm a',
                          ).format(widget.transaction.date),
                          style: GoogleFonts.inter(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Amount Paid & Balance (If applicable)
                  if (widget.transaction.receivedAmount != null &&
                      widget.transaction.receivedAmount! > 0) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "AMOUNT PAID",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            "₹${widget.transaction.receivedAmount!.toStringAsFixed(2)}",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF00695C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.red.withOpacity(0.05),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "BALANCE",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          Text(
                            "₹${(widget.transaction.amount - widget.transaction.receivedAmount!).toStringAsFixed(2)}",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 1),

                  // Table Header
                  if (hasParsedItems) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: _tableHeader("ITEM")),
                          Expanded(flex: 2, child: _tableHeader("WEIGHT")),
                          Expanded(
                            flex: 2,
                            child: _tableHeader("RATE"),
                          ), // New Column
                          Expanded(
                            flex: 2,
                            child: _tableHeader(
                              "AMOUNT",
                              align: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Table Body
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      itemCount: parsedItems.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey[100]),
                      itemBuilder: (context, index) {
                        final item = parsedItems[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
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
                                      item['name']!,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (item['qty'] != '0')
                                      Text(
                                        "${item['qty']} Pack",
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item['weight']!,
                                  style: GoogleFonts.inter(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item['rate']!,
                                  style: GoogleFonts.inter(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item['total'] == '-'
                                      ? '-'
                                      : "₹${item['total']}",
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                  ] else ...[
                    // Manual description or Payment
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        widget.transaction.details ?? "No details",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],

                  // Total Amount
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "TOTAL AMOUNT",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          "₹${widget.transaction.amount.toStringAsFixed(2)}",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Amount Paid & Balance (If applicable)
                  if (widget.transaction.receivedAmount != null &&
                      widget.transaction.receivedAmount! > 0) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "AMOUNT PAID",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            "₹${widget.transaction.receivedAmount!.toStringAsFixed(2)}",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF00695C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.red.withOpacity(0.05),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "BALANCE",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          Text(
                            "₹${(widget.transaction.amount - widget.transaction.receivedAmount!).toStringAsFixed(2)}",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Share Receipt Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSharing ? null : _shareTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  icon: _isSharing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.share, color: Colors.white, size: 20),
                  label: Text(
                    _isSharing ? "Generating PDF..." : "Share Receipt",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String text, {TextAlign align = TextAlign.start}) {
    return Text(
      text,
      textAlign: align,
      style: GoogleFonts.inter(
        color: Colors.grey[400],
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }
}
