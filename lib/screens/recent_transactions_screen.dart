import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';

class RecentTransactionsScreen extends StatelessWidget {
  const RecentTransactionsScreen({super.key});

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Last 3 Days Activity', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Selector<FinanceProvider, List<TransactionModel>>(
        selector: (_, finance) => finance.getTransactionsInPastDays(3),
        builder: (context, transactions, _) {
          if (transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No transactions in the last 3 days', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final Map<String, List<TransactionModel>> grouped = {};
          for (var t in transactions) {
            final dateStr = '${t.date.year}-${t.date.month}-${t.date.day}';
            grouped.putIfAbsent(dateStr, () => []).add(t);
          }

          final keys = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: keys.length,
            itemBuilder: (context, groupIndex) {
              final dateKey = keys[groupIndex];
              final groupTransactions = grouped[dateKey]!;
              final firstDate = groupTransactions.first.date;
              
              final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
              final dayName = days[firstDate.weekday - 1];
              final formattedDate = '${firstDate.day} ${_months[firstDate.month - 1]} ${firstDate.year}';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Beautiful Date Header
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                                color: Theme.of(context).colorScheme.primary
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Divider(thickness: 2, height: 1), // "Big Line"
                        ),
                      ],
                    ),
                  ),
                  // Transactions for this date
                  ...groupTransactions.map((t) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                    leading: CircleAvatar(
                      backgroundColor: t.isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      child: Icon(
                        t.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                        color: t.isIncome ? Colors.green : Colors.red,
                        size: 18,
                      ),
                    ),
                    title: Text(t.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}'),
                    trailing: Text(
                      '${t.isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: t.isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
