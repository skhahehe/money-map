import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/bounce_button.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountController = TextEditingController();
  bool _isIncome = true;
  String? _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// 🛡️ LAYER 1: UI Constraint
  /// Prevents the user from even seeing future dates in the picker.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: today, // Business Rule: Cannot select future dates.
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final categories = finance.categories.where((c) => c.isIncome == _isIncome).toList();
    
    // Set default category
    _selectedCategory ??= categories.isNotEmpty ? categories.first.name : null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = _selectedDate.year == today.year && 
                   _selectedDate.month == today.month && 
                   _selectedDate.day == today.day;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'New Transaction',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Income'), icon: Icon(Icons.add)),
                ButtonSegment(value: false, label: Text('Expense'), icon: Icon(Icons.remove)),
              ],
              selected: {_isIncome},
              onSelectionChanged: (val) {
                setState(() {
                  _isIncome = val.first;
                  _selectedCategory = null;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (categories.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((c) {
                  return DropdownMenuItem(value: c.name, child: Text(c.name));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
              )
            else
              const Text('No categories found.', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ListTile(
              title: Text(isToday ? 'Date: Today' : 'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (finance.isFutureDate(_selectedDate))
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  '⚠️ This date is in the future. Please select today or a past date.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),
            BounceButton(
              onTap: () {
                final amount = double.tryParse(_amountController.text);
                
                // 🛡️ LAYER 2: Explicit UI Guard
                // Final check before state mutation.
                if (finance.isFutureDate(_selectedDate)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ You cannot add transactions for future dates.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
  
                if (amount != null && amount > 0 && _selectedCategory != null) {
                  final transaction = TransactionModel(
                    amount: amount,
                    date: _selectedDate,
                    isIncome: _isIncome,
                    category: _selectedCategory!,
                  );
                  context.read<FinanceProvider>().addTransaction(transaction);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount and select a category')),
                  );
                }
              },
              child: IgnorePointer(
                child: ElevatedButton(
                  onPressed: () {}, // Simply provide a dummy to keep it enabled visually
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Transaction', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
