import 'dart:io';

import 'package:expanse_tracker/AddTransaction.dart';
import 'package:expanse_tracker/ListDeatails.dart';
import 'package:expanse_tracker/login/login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isExpense;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
  });
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomePageState();
}

class _HomePageState extends State<HomeContent> {
  Future<void> loadUserFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('user_detail')
          .select()
          .eq('uuidd', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          userName = data['name'] ?? 'User';
          userImage = data['image_url'] ?? '';
        });
      }
    } catch (e) {
      print("Profile fetch error: $e");
    }
  }

  /// 🔴 Logout with confirmation
  Future<void> logout(BuildContext context) async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      await Supabase.instance.client.auth.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logout failed: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String userName = '';
  String userImage = '';
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchData();
    loadUserData();
    loadUserFromSupabase();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString('user_name') ?? 'User';
      userImage = prefs.getString('user_image') ?? '';
    });
  }

  final List<Transaction> _transaction = [];
  Future<void> fetchData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final response = await Supabase.instance.client
          .from('Transaction')
          .select()
          .eq('user_id', user!.id) 
          .order('date', ascending: false);

      final List<Transaction> loadedData = [];

      for (var item in response) {
        loadedData.add(
          Transaction(
            id: item['id'].toString(),
            title: item['title'],
            amount: (item['amount'] as num).toDouble(),
            date: DateTime.tryParse(item['date']) ?? DateTime.now(),
            isExpense: item['isExpense'], // ✅ fixed
          ),
        );
      }

      setState(() {
        isLoading = false;
        _transaction.clear();
        _transaction.addAll(loadedData);
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load data: $e")));
    }
  }

  //DELETE SUPABASE
  Future<void> _deleteTransaction(String id, int index) async {
    final user = Supabase.instance.client.auth.currentUser;
    await Supabase.instance.client
        .from('Transaction')
        .delete()
       // .eq('id', int.parse(id));
         .eq('user_id', user!.id);
    setState(() {
      _transaction.removeAt(index);
    });
  }

  // ADD SUPABASE
  Future<void> _addTransaction(
    String title,
    double amount,
    bool isExpense,
  ) async {
    final user = Supabase.instance.client.auth.currentUser;
    final response = await Supabase.instance.client
        .from('Transaction')
        .insert({
          'title': title,
          'amount': amount,
          'date': DateTime.now().toString().split(' ')[0],
          'isExpense': isExpense,
          'user_id': user!.id,
        })
        .select()
        .single();

    final newTx = Transaction(
      id: response['id'].toString(), // ✅ real DB id
      title: response['title'],
      amount: (response['amount'] as num).toDouble(),
      date: DateTime.parse(response['date']),
      isExpense: response['isExpense'],
    );

    setState(() {
      _transaction.insert(0, newTx);
    });
  }

  double get totalBalance {
    double income = 0;
    double expense = 0;
    for (var tx in _transaction) {
      if (tx.isExpense) {
        expense += tx.amount;
      } else {
        income += tx.amount;
      }
    }

    return income - expense;
  }

  double get totalIncome {
    return _transaction
        .where((tx) => !tx.isExpense)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  double get totalExpense {
    return _transaction
        .where((tx) => tx.isExpense)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  void _startAddNewTransaction() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Addtransaction(_addTransaction);
      },
    );
  }

  Future<void> clearAllTransactions() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    await Supabase.instance.client
        .from('Transaction')
        .delete()
        .eq('user_id', user.id); // ✅ only this user data

    setState(() {
      _transaction.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All transactions cleared")),
    );
  } catch (e) {
    print("Error: $e");
  }
}

  Future<void> showClearDialog() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear All?"),
        content: const Text("This will delete all transactions permanently"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await clearAllTransactions();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double target = 25000;

    double incomeProgress = totalIncome / target;
    double expenseProgress = totalExpense / target;

    // limit between 0 → 1
    incomeProgress = incomeProgress.clamp(0.0, 1.0);
    expenseProgress = expenseProgress.clamp(0.0, 1.0);
    Future<void> refresh() async {
      await fetchData();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      //appBar: AppBar(title: const Text('Expanse Tracker')),
      appBar:
          // AppBar(
          //   title: Row(
          //     children: [
          //       CircleAvatar(
          //         radius: 18,
          //         backgroundColor: Colors.grey,
          //         backgroundImage: userImage.isNotEmpty
          //             ? NetworkImage(userImage)
          //             : const AssetImage('assets/default.png') as ImageProvider,
          //       ),
          //       const SizedBox(width: 8),
          //       Text('OverView'),
          //     ],
          //   ),
          //   actions: [
          //     IconButton(
          //       onPressed: isLoading ? null : () => logout(context),
          //       icon: Icon(Icons.logout),
          //     ),
          //   ],
          // ),
          AppBar(
         //   backgroundColor: Colors.black,
           
            actions: [
              IconButton(
                alignment: Alignment.topLeft,
                onPressed: isLoading ? null : () => logout(context),
                icon: Icon(Icons.logout),
              ),Spacer(),
              Text(
                  "Expense Tracker",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: showClearDialog
              ),
            ],
          ),

      body: RefreshIndicator(
        onRefresh: refresh,

        child: Column(
          children: [
            Card(
              color: const Color.fromARGB(255, 104, 11, 234),
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'This Month Spending',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "₹${totalBalance.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.white,
                              ),
                              child: Icon(
                                Icons.arrow_upward,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Income : ₹${totalIncome.toStringAsFixed(0)}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.white,
                              ),

                              child: Icon(
                                Icons.arrow_downward_rounded,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Expanse : ₹${totalExpense.toStringAsFixed(0)}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Analytics',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 5),
                SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 🔴 Expense (background circle)
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: expenseProgress,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey[200],
                          color: Colors.red,
                        ),
                      ),

                      // 🔵 Income (top circle)
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: incomeProgress,
                          strokeWidth: 12,
                          backgroundColor: Colors.transparent,
                          color: Colors.blue,
                        ),
                      ),

                      // 👇 Center Text
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "₹${totalBalance.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text("Balance", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Text(
                    'Transaction',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => Listdeatails()),
                      );
                    },
                    child: Text('Show More'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _transaction.length,
                      itemBuilder: (ctx, index) {
                        final tx = _transaction[index];
                        return Dismissible(
                          key: ValueKey(tx.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            return await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Transaction'),
                                content: const Text('Are you sure ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('yes'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) async {
                            await _deleteTransaction(tx.id, index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${tx.title} deleted')),
                            );
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          child: Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: tx.isExpense
                                    ? Colors.red
                                    : Colors.green,
                                child: Icon(
                                  tx.isExpense
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
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
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 104, 11, 234),
        onPressed: _startAddNewTransaction,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
