import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/bounce_button.dart';

class AddTransactionSheet extends StatefulWidget {
  final TransactionModel? transactionToEdit;
  const AddTransactionSheet({super.key, this.transactionToEdit});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _borrowerController = TextEditingController();
  bool _isIncome = true;
  String? _selectedCategory;
  late DateTime _selectedDate;
  DateTime? _returnDate;
  String? _amountError;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final t = widget.transactionToEdit!;
      _amountController.text = t.amount.toString();
      _isIncome = t.isIncome;
      _selectedCategory = t.category;
      _selectedDate = t.date;
      _borrowerController.text = t.borrowerName ?? '';
      _returnDate = t.returnDate;
    } else {
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
    }
    _amountController.addListener(_validateAmount);
    _validateAmount(); // Initial check
  }

  void _validateAmount() {
    final text = _amountController.text;
    if (text.isEmpty) {
      setState(() {
        _amountError = null;
        _isValid = false;
      });
      return;
    }

    final regExp = RegExp(r'^\d*\.?\d*$');
    if (!regExp.hasMatch(text)) {
      setState(() {
        _amountError = 'Only numbers and "." are allowed';
        _isValid = false;
      });
    } else {
      final amount = double.tryParse(text);
      if (amount == null || amount <= 0) {
        setState(() {
          _amountError = amount == 0 ? 'Amount must be greater than 0' : null;
          _isValid = false;
        });
      } else {
        setState(() {
          _amountError = null;
          _isValid = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _borrowerController.dispose();
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

  Future<void> _pickReturnDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? today,
      firstDate: today, // Business Rule: Cannot select returning date before today.
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _returnDate = picked);
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
            Text(
              widget.transactionToEdit != null ? 'Edit Transaction' : 'New Transaction',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '${context.read<FinanceProvider>().currencySymbol} ',
                border: const OutlineInputBorder(),
                errorText: _amountError,
                errorStyle: const TextStyle(color: Colors.red),
              ),
              onChanged: (_) => _validateAmount(),
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
            
            if (!_isIncome && _selectedCategory == 'Loan') ...[
              TextField(
                controller: _borrowerController,
                decoration: const InputDecoration(
                  labelText: 'Lent to (Borrower Name)',
                  hintText: 'Enter name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            ListTile(
              title: Text(isToday ? 'Date: Today' : 'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            
            if (!_isIncome && _selectedCategory == 'Loan') ...[
              const SizedBox(height: 16),
              ListTile(
                title: Text(_returnDate == null 
                    ? 'Date of return: Not set' 
                    : 'Date of return: ${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}'),
                trailing: const Icon(Icons.event_repeat),
                onTap: _pickReturnDate,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],

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
              onTap: !_isValid ? null : () {
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
                    borrowerName: (!_isIncome && _selectedCategory == 'Loan') ? _borrowerController.text : null,
                    returnDate: (!_isIncome && _selectedCategory == 'Loan') ? _returnDate : null,
                  );
                  
                  if (widget.transactionToEdit != null) {
                    context.read<FinanceProvider>().updateTransaction(widget.transactionToEdit!, transaction);
                  } else {
                    context.read<FinanceProvider>().addTransaction(transaction);
                  }
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
                    backgroundColor: _isValid ? Colors.blue : Colors.grey.shade300,
                    foregroundColor: _isValid ? Colors.white : Colors.grey.shade600,
                    elevation: _isValid ? 2 : 0,
                  ),
                  child: Text(
                    widget.transactionToEdit != null ? 'Update Transaction' : 'Save Transaction', 
                    style: const TextStyle(fontSize: 16)
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
