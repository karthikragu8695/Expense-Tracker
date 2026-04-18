import 'package:expanse_tracker/ListDeatails.dart';
import 'package:expanse_tracker/home_content.dart';
import 'package:flutter/material.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [HomeContent(),Listdeatails(),];

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
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Cash Flow',
          ),
          // BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),  
    );
  }
}
