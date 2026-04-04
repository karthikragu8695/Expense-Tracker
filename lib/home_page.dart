import 'package:expanse_tracker/Profile_page.dart';
import 'package:expanse_tracker/home_content.dart';
import 'package:flutter/material.dart';

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [HomeContent(),ProfilePage()];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      //appBar: AppBar(title: const Text('Expanse Tracker')),
      body: IndexedStack(index: _selectIndex, children: pages),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFF5F7FA),
        currentIndex: _selectIndex,
        onTap: (index) {
          setState(() {
            _selectIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.analytics),
          //   label: 'Analytics',
          // ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),  
    );
  }
}
