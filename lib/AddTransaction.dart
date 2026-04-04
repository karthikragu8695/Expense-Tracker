import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Addtransaction extends StatefulWidget {
  final Function(String, double, bool) addTx;

  const Addtransaction(this.addTx, {super.key});

  @override
  State<Addtransaction> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Addtransaction> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool isExpense = true;
  bool _isTouched = false;

  void _submit() {
    final enteredTitle = _titleController.text;
    final enteredAmount = double.tryParse(_amountController.text);
    if (enteredTitle.isEmpty || enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid title & amount")),
      );
      return;
    }
    widget.addTx(enteredTitle, enteredAmount, isExpense);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
    
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add Transaction",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 25),
            TextField(
              controller: _titleController,
              keyboardType: TextInputType.name,
              onChanged: (_) {
                setState(() {
                  _isTouched = true;
                }); // 🔥 refresh UI
              },
              decoration: InputDecoration(
                labelText: "tite",
                errorText: _isTouched && _titleController.text.isEmpty
                    ? 'Enter a title'
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                prefixStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(isExpense ? 'Expense' : 'Income',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
                ),
                Switch(
                  value: isExpense,
                  activeColor: Colors.white,
                  activeTrackColor: isExpense ? Colors.red : Colors.green,
                  onChanged: (val) {
                    setState(() {
                      isExpense = val;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 10,),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text('Save', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 104, 11, 234),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
