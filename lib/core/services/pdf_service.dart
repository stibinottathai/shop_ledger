import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';

class PdfService {
  Future<File> generateTransactionPdf({
    required String name,
    required String phone,
    required List<Transaction> transactions,
    required double outstandingBalance,
    String? shopName,
    bool isSingleReceipt = false,
  }) async {
    final pdf = pw.Document();

    // Use a standard font (Helvetica by default)
    // Removed asset load that was causing crashes

    final DateFormat dateFormatter = DateFormat('dd MMM yyyy');
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs. ',
      decimalDigits: 2,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(
              name,
              dateFormatter.format(DateTime.now()),
              shopName,
              isSingleReceipt: isSingleReceipt,
            ),
            pw.SizedBox(height: 20),
            _buildSummary(name, phone, outstandingBalance, currencyFormatter),
            pw.SizedBox(height: 20),
            _buildTransactionTable(
              transactions,
              dateFormatter,
              currencyFormatter,
              isSingleReceipt: isSingleReceipt,
            ),
            pw.Divider(),
            _buildFooter(),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/statement_${name}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildHeader(
    String name,
    String date,
    String? shopName, {
    bool isSingleReceipt = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              shopName ?? 'Shop Ledger',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              isSingleReceipt ? 'Transaction Receipt' : 'Statement of Accounts',
              style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [pw.Text('Date: $date')],
        ),
      ],
    );
  }

  pw.Widget _buildSummary(
    String name,
    String phone,
    double balance,
    NumberFormat currency,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Customer Details:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                name.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(phone),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Outstanding Balance',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                currency.format(balance),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: balance > 0 ? PdfColors.red : PdfColors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTransactionTable(
    List<Transaction> transactions,
    DateFormat dateFmt,
    NumberFormat currency, {
    bool isSingleReceipt = false,
  }) {
    if (isSingleReceipt && transactions.length == 1) {
      return _buildSingleReceiptTable(transactions.first, currency);
    }

    return pw.Table.fromTextArray(
      headers: ['Date', 'Details', 'Debit', 'Credit'],
      data: transactions.map((tx) {
        final isSale = tx.type == TransactionType.sale;
        return [
          dateFmt.format(tx.date),
          tx.details ?? (isSale ? 'Sale' : 'Payment Received'),
          isSale ? currency.format(tx.amount) : '-',
          !isSale ? currency.format(tx.amount) : '-',
        ];
      }).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _buildSingleReceiptTable(Transaction tx, NumberFormat currency) {
    final items = _parseItems(tx.details ?? '');
    final isSale = tx.type == TransactionType.sale;

    if (items.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Text(
          tx.details?.isNotEmpty == true
              ? tx.details!
              : (isSale ? 'Sale' : 'Payment Received'),
        ),
      );
    }

    // Determine unit header similar to UI
    String unitHeader = 'QTY/WT';
    String? commonUnit;
    bool mixedUnits = false;

    if (items.isNotEmpty) {
      final firstUnit = items.first['weight']!
          .replaceAll(RegExp(r'[0-9.]'), '')
          .trim();
      commonUnit = firstUnit;

      for (var item in items) {
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

    return pw.Column(
      children: [
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(3), // Item
            1: const pw.FlexColumnWidth(2), // Unit
            2: const pw.FlexColumnWidth(2), // Qty
            3: const pw.FlexColumnWidth(2), // Amount
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableHeaderCell('ITEM'),
                _tableHeaderCell(unitHeader),
                _tableHeaderCell('QTY'),
                _tableHeaderCell('AMOUNT', align: pw.TextAlign.right),
              ],
            ),
            // Rows
            ...items.map((item) {
              String quantityDisplay = item['weight']!;
              if (!mixedUnits && commonUnit != null) {
                quantityDisplay = quantityDisplay
                    .replaceAll(commonUnit, '')
                    .trim();
              }

              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item['item']!,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        if (item['price']!.isNotEmpty)
                          pw.Text(
                            item['price']!,
                            style: const pw.TextStyle(
                              color: PdfColors.grey600,
                              fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: pw.Text(
                      quantityDisplay,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: pw.Text(
                      item['count']!.replaceAll(' Nos', ''),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: pw.Text(
                      'Rs.${item['total']}',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
        pw.Divider(),
        // Total Section
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL AMOUNT',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    currency.format(tx.amount),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (isSale &&
                  tx.receivedAmount != null &&
                  tx.receivedAmount! > 0) ...[
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'RECEIVED AMOUNT',
                      style: const pw.TextStyle(
                        color: PdfColors.grey700,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      '- ${currency.format(tx.receivedAmount!)}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green700,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  color: PdfColors.grey50,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'BALANCE',
                        style: pw.TextStyle(
                          color: PdfColors.red,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        currency.format(tx.amount - tx.receivedAmount!),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _tableHeaderCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey600,
          fontSize: 8,
        ),
      ),
    );
  }

  List<Map<String, String>> _parseItems(String details) {
    if (details.isEmpty) return [];

    final lines = details.split('\n');
    final List<Map<String, String>> items = [];

    // Strategy 1: Customer Transaction Format
    // Apple (100/kg) 2kg [5 Nos] = 200
    final customerRegex = RegExp(
      r'^(.*?) \((.*?)\) (.*?)(?: \[(.*?)\])? = (.*?)$',
    );
    bool matchedCustomer = false;

    for (var line in lines) {
      final match = customerRegex.firstMatch(line);
      if (match != null) {
        matchedCustomer = true;
        items.add({
          'item': match.group(1) ?? '',
          'price': match.group(2) ?? '',
          'weight': match.group(3) ?? '',
          'count': match.group(4) ?? '',
          'total': match.group(5) ?? '',
        });
      }
    }

    if (matchedCustomer && items.isNotEmpty) return items;

    // Strategy 2: Supplier Transaction Format
    // 5 Items, 10.5 Kg Apple (Rate: 150.00, Total: 750.00)
    // Regex matches multiple items in one string if needed, or per line?
    // Supplier logic typically parses the whole string or lines.
    // Based on SupplierTransactionDetailsPage, regex uses allMatches on the whole text?
    // Let's copy logic from SupplierTransactionDetailsPage.

    if (details.contains("Items") && details.contains("Kg")) {
      items.clear();
      final supplierRegex = RegExp(
        r'(\d+)\s+Items,\s+([\d\.]+)\s+Kg\s+((?:(?!,\s+\d+\s+Items).)*)',
      );
      final matches = supplierRegex.allMatches(details);

      for (final match in matches) {
        String nameAndExtras = match.group(3)?.trim() ?? 'Unknown';
        String rate = '';
        String total = '';
        String name = nameAndExtras;

        final extrasRegex = RegExp(
          r'^(.*?)\s*\(Rate:\s*([\d\.]+),\s*Total:\s*([\d\.]+)\)$',
        );
        final extraMatch = extrasRegex.firstMatch(nameAndExtras);

        if (extraMatch != null) {
          name = extraMatch.group(1) ?? nameAndExtras;
          rate = extraMatch.group(2) ?? '';
          total = extraMatch.group(3) ?? '';
        }

        // Map to common keys used by _buildSingleReceiptTable
        items.add({
          'item': name,
          'price': rate,
          'weight': '${match.group(2)} Kg', // normalized to display string
          'count': '${match.group(1)} Nos', // normalized
          'total': total,
        });
      }
      if (items.isNotEmpty) return items;
    }

    return [];
  }

  pw.Widget _buildFooter() {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'Generated by Shop Ledger',
            style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
