import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/transaction_model.dart';
import 'recent_transactions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showAddUserDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<FinanceProvider>().addUser(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Selector<FinanceProvider, double>(
          selector: (_, finance) => finance.savings,
          builder: (context, savings, _) => IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.green),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Total Savings'),
                  content: Text(
                    '\$${savings.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        title: const Text('Money Map', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Selector<FinanceProvider, ({String currentUser, List<String> users, Map<String, String?> images})>(
            selector: (_, finance) => (
              currentUser: finance.currentUser,
              users: finance.users,
              images: finance.userImages,
            ),
            builder: (context, data, _) => PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 14,
                backgroundImage: data.images[data.currentUser] != null
                    ? FileImage(File(data.images[data.currentUser]!))
                    : null,
                child: data.images[data.currentUser] == null
                    ? const Icon(Icons.person, size: 18)
                    : null,
              ),
              onSelected: (value) {
                if (value == 'add_user') {
                  _showAddUserDialog(context);
                } else {
                  context.read<FinanceProvider>().switchUser(value);
                }
              },
              itemBuilder: (context) => [
                ...data.users.map((user) => PopupMenuItem(
                      value: user,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: data.images[user] != null
                                ? FileImage(File(data.images[user]!))
                                : null,
                            child: data.images[user] == null
                                ? const Icon(Icons.person, size: 14)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              user,
                              style: TextStyle(
                                fontWeight: user == data.currentUser
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (user == data.currentUser)
                            const Icon(Icons.check, color: Colors.blue, size: 16),
                        ],
                      ),
                    )),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'add_user',
                  child: Row(
                    children: [
                      Icon(Icons.person_add, size: 20),
                      SizedBox(width: 12),
                      Text('Add New User'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Section - Spent at Top (Wide)
            Selector<FinanceProvider, double>(
              selector: (_, finance) => finance.spentThisMonth,
              builder: (context, spent, _) => _SummaryCard(
                title: 'Spent This Month',
                amount: spent,
                color: Colors.red,
                icon: Icons.shopping_cart,
              ),
            ),
            const SizedBox(height: 12),
            // Balance at Bottom (Wide)
            Selector<FinanceProvider, double>(
              selector: (_, finance) => finance.currentBalance,
              builder: (context, balance, _) => _SummaryCard(
                title: 'Balance',
                amount: balance,
                color: Colors.blue,
                icon: Icons.account_balance_wallet,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recent Transactions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RecentTransactionsScreen()),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Recent Transactions List
            Selector<FinanceProvider, List<TransactionModel>>(
              selector: (_, finance) => finance.getRecentTransactions(5),
              shouldRebuild: (prev, next) {
                if (prev.length != next.length) return true;
                for (int i = 0; i < prev.length; i++) {
                  if (prev[i] != next[i]) return true;
                }
                return false;
              },
              builder: (context, recentTransactions, _) {
                if (recentTransactions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text('No recent transactions', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentTransactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final t = recentTransactions[index];
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 800 + (index * 150)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 40 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: t.isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          child: Icon(
                            t.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                            color: t.isIncome ? Colors.green : Colors.red,
                            size: 18,
                          ),
                        ),
                        title: Text(t.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${t.date.day}/${t.date.month}/${t.date.year}'),
                        trailing: Text(
                          '${t.isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: t.isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
