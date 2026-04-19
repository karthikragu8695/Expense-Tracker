import 'package:expanse_tracker/home_content.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class Listdeatails extends StatefulWidget {
  const Listdeatails({super.key});

  @override
  State<Listdeatails> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Listdeatails> {
  bool isExpense = true;
  bool isLoading = true;

  final List<Transaction> _transaction = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // ✅ FETCH DATA (FIXED)
  Future<void> fetchData() async {
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null) {
    print("User not logged in");
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    final response = await Supabase.instance.client
        .from('Transaction')
        .select()
        .eq('user_id', user.id) // ✅ IMPORTANT FIX
        .eq('isExpense', isExpense)
        .order('date', ascending: false);

    final List<Transaction> loadedData = [];

    for (var item in response) {
      loadedData.add(
        Transaction(
          id: item['id'].toString(),
          title: item['title'] ?? '',
          amount: (item['amount'] as num).toDouble(),
          date: DateTime.tryParse(item['date'] ?? '') ?? DateTime.now(),
          isExpense: item['isExpense'] ?? false,
        ),
      );
    }

    setState(() {
      _transaction.clear();
      _transaction.addAll(loadedData);
    });
  } catch (e) {
    print("Fetch error: $e");
  }

  setState(() {
    isLoading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    Future<void> refresh() async {
      setState(() {
        isLoading = true;
      });
      await fetchData();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: RefreshIndicator(
          onRefresh: refresh,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// 🔄 Toggle Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      /// 🔴 Expense
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            setState(() {
                              isExpense = true;
                              isLoading = true;
                            });
                            await fetchData();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isExpense
                                  ? const Color(0xFF680BEA)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Expense',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isExpense ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),

                      /// 🟢 Income
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            setState(() {
                              isExpense = false;
                              isLoading = true;
                            });
                            await fetchData();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isExpense
                                  ? const Color(0xFF680BEA)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Income',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !isExpense ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                /// 📋 LIST
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _transaction.isEmpty
                      ? const Center(
                          child: Text(
                            "No Transactions Found",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _transaction.length,
                          itemBuilder: (ctx, index) {
                            final tx = _transaction[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: tx.isExpense
                                      ? Colors.red
                                      : Colors.green,
                                  child: Icon(
                                    tx.isExpense
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(tx.title),
                                subtitle: Text(
                                  "${tx.date.day}/${tx.date.month}/${tx.date.year}",
                                ),
                                trailing: Text(
                                  "₹${tx.amount}",
                                  style: TextStyle(
                                    color: tx.isExpense
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),

      /// 📄 PDF DOWNLOAD
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final file = await generatePdf(_transaction);

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("PDF Downloaded")));

          await OpenFilex.open(file.path);
        },
        child: const Icon(Icons.download),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// 📄 PDF FUNCTIONS
////////////////////////////////////////////////////////////

Future<void> saveToDownloads(pw.Document pdf) async {
  if (await Permission.storage.request().isGranted) {
    final directory = Directory('/storage/emulated/0/Download');
    final file = File('${directory.path}/transactions.pdf');

    await file.writeAsBytes(await pdf.save());
  }
}

Future<File> generatePdf(List<Transaction> transactions) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Transaction Report', style: pw.TextStyle(fontSize: 22)),
            pw.SizedBox(height: 20),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [pw.Text('Title'), pw.Text('Amount'), pw.Text('Type')],
            ),

            pw.Divider(),

            ...transactions.map((tx) {
              return pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(tx.title),
                  pw.Text("₹${tx.amount}"),
                  pw.Text(tx.isExpense ? "Expense" : "Income"),
                ],
              );
            }),
          ],
        );
      },
    ),
  );

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/transactions.pdf');

  await file.writeAsBytes(await pdf.save());
  await saveToDownloads(pdf);

  return file;
}
