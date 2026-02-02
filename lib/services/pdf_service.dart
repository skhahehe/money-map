import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../models/transaction_model.dart';

class PdfService {
  /// 📄 Generates and opens the native print dialog.
  static Future<void> printTransactionReport({
    required List<TransactionModel> transactions,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required String periodTitle,
  }) async {
    try {
      final pdf = await _generateDocument(
        transactions, 
        totalIncome, 
        totalExpense, 
        netBalance, 
        periodTitle,
      );
      
      final bool success = await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Money_Map_Statement_${periodTitle.replaceAll(' ', '_')}.pdf',
      );

      if (!success) {
        await saveTransactionReport(
          transactions: transactions,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          netBalance: netBalance,
          periodTitle: periodTitle,
        );
      }
    } catch (e) {
      await saveTransactionReport(
        transactions: transactions,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: netBalance,
        periodTitle: periodTitle,
      );
    }
  }

  /// 💾 Opens a native "Save As" location picker or Share sheet.
  static Future<void> saveTransactionReport({
    required List<TransactionModel> transactions,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required String periodTitle,
  }) async {
    final pdf = await _generateDocument(
      transactions, 
      totalIncome, 
      totalExpense, 
      netBalance, 
      periodTitle,
    );
    final bytes = await pdf.save();
    final fileName = 'Money_Map_Statement_${periodTitle.replaceAll(' ', '_')}.pdf';

    if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      try {
        final String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Statement',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsBytes(bytes);
          return;
        }
      } catch (e) {
        debugPrint('⚠️ FilePicker native error: $e. Falling back to Share.');
      }
    } 
    
    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
    );
  }

  static Future<pw.Document> _generateDocument(
    List<TransactionModel> transactions,
    double totalIncome,
    double totalExpense,
    double netBalance,
    String periodTitle,
  ) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final theme = pw.ThemeData.withFont(
      base: ttf,
      bold: ttf,
    );

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
          ),
        ),
        build: (pw.Context context) {
          return [
            _buildHeader(periodTitle),
            pw.SizedBox(height: 20),
            _buildSummary(totalIncome, totalExpense, netBalance),
            pw.SizedBox(height: 24),
            pw.Text(
              'Transaction Details',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 8),
            _buildTransactionTable(transactions),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Money Map Statement',
          style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Date Range: $title',
          style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue900),
      ],
    );
  }

  static pw.Widget _buildSummary(double income, double expense, double balance) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total Income', income, PdfColors.green700),
          pw.Container(width: 1, height: 40, color: PdfColors.grey300),
          _summaryItem('Total Expense', expense, PdfColors.red700),
          pw.Container(width: 1, height: 40, color: PdfColors.grey300),
          _summaryItem('Net Balance', balance, PdfColors.blue900),
        ],
      ),
    );
  }

  static pw.Widget _summaryItem(String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(
          '\$${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionTable(List<TransactionModel> transactions) {
    return pw.TableHelper.fromTextArray(
      border: null,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      headerHeight: 30,
      cellHeight: 25,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerAlignment: pw.Alignment.centerLeft,
      cellAlignment: pw.Alignment.centerLeft,
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
      headers: ['Date', 'Category', 'Type', 'Amount'],
      data: transactions.map((t) {
        return [
          '${t.date.day}/${t.date.month}/${t.date.year}',
          t.category,
          t.isIncome ? 'Income' : 'Expense',
          '${t.isIncome ? "+" : "-"}\$${t.amount.toStringAsFixed(2)}',
        ];
      }).toList(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
    );
  }
}
