import 'package:flutter/material.dart';

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

  void _submit(){
    final enteredTitle = _titleController.text;
    final enteredAmount  = double.tryParse(_amountController.text);
    if (enteredTitle.isEmpty || enteredAmount == null) return;  
    widget.addTx(enteredTitle,enteredAmount,isExpense);
    Navigator.of(context).pop();
  }
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: "tite"),
        ),
        TextField(
          controller: _amountController,
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Expense'),
             Switch(
                value: isExpense,
                onChanged: (val) {
                  setState(() {
                    isExpense = val;
                  });
                },
              ),
          ],
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Add Transaction'))
      ],
    ),);
  }
}
