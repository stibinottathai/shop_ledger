import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shop_ledger/features/customer/domain/entities/customer.dart';
import 'package:shop_ledger/features/customer/domain/entities/transaction.dart';

class PdfService {
  Future<File> generateTransactionPdf({
    required Customer customer,
    required List<Transaction> transactions,
    required double outstandingBalance,
  }) async {
    final pdf = pw.Document();

    // Use a standard font
    final font = await rootBundle
        .load("assets/fonts/Inter-Regular.ttf")
        .catchError((_) {
          // Fallback or use standard font if not available
          // Using standard helvetica for now as getting custom fonts might be tricky without setup
          return Future.value(ByteData(0));
        });
    // However, pdf package has built-in fonts, let's use them to avoid asset issues for now.

    final DateFormat dateFormatter = DateFormat('dd MMM yyyy');
    final currencyFormatter = NumberFormat.simpleCurrency(
      locale: 'en_IN',
      decimalDigits: 2,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(customer, dateFormatter.format(DateTime.now())),
            pw.SizedBox(height: 20),
            _buildSummary(customer, outstandingBalance, currencyFormatter),
            pw.SizedBox(height: 20),
            _buildTransactionTable(
              transactions,
              dateFormatter,
              currencyFormatter,
            ),
            pw.Divider(),
            _buildFooter(),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/statement_${customer.name}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildHeader(Customer customer, String date) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Shop Ledger',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Statement of Accounts',
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
    Customer customer,
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
                customer.name.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(customer.phone),
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
    NumberFormat currency,
  ) {
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
