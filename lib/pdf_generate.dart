import 'dart:io';
import 'package:expanse_tracker/home_content.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

Future<void> generatePdf(List<Transaction> transactions) async {
  final pdf = pw.Document();

  final totalIncome = transactions
      .where((tx) => !tx.isExpense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  final totalExpense = transactions
      .where((tx) => tx.isExpense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

 final font = await PdfGoogleFonts.notoSansRegular();

pdf.addPage(
  pw.MultiPage(
    build: (context) => [
      pw.Text('Transaction Report', style: pw.TextStyle(fontSize: 22)),
      pw.SizedBox(height: 20),

      pw.Table(
        border: pw.TableBorder.all(),
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Title')),
              pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Amount')),
              pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Type')),
              pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Date')),
            ],
          ),

          ...transactions.map((tx) {
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: pw.EdgeInsets.all(5),
                  child: pw.Text(tx.title, maxLines: 2),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(5),
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text("₹${tx.amount.toStringAsFixed(2)}"),
                  ),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(5),
                  child: pw.Text(tx.isExpense ? "Expense" : "Income"),
                ),
                pw.Padding(
                  padding: pw.EdgeInsets.all(5),
                  child: pw.Text(
                    "${tx.date.day}/${tx.date.month}/${tx.date.year}",
                  ),
                ),
              ],
            );
          }),
        ],
      ),

      pw.SizedBox(height: 20),

      pw.Divider(),

      pw.Text("Total Income: ₹${totalIncome.toStringAsFixed(2)}"),
      pw.Text("Total Expense: ₹${totalExpense.toStringAsFixed(2)}"),
      pw.Text(
        "Balance: ₹${(totalIncome - totalExpense).toStringAsFixed(2)}",
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    ],
  ),
);

  /// Save once
  final bytes = await pdf.save();

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/transactions.pdf');

  await file.writeAsBytes(bytes);

  /// Share
  await Printing.sharePdf(bytes: bytes, filename: 'transactions.pdf');
}
