import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/category_model.dart';
import '../widgets/bounce_button.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog(bool isIncome) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${isIncome ? 'Income' : 'Expense'} Category'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(hintText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_categoryController.text.isNotEmpty) {
                context.read<FinanceProvider>().addCategory(
                      _categoryController.text,
                      isIncome,
                    );
                _categoryController.clear();
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
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Income'),
            Tab(text: 'Expense'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(true),
          _buildCategoryList(false),
        ],
      ),
      floatingActionButton: BounceButton(
        onTap: () => _showAddCategoryDialog(_tabController.index == 0),
        child: FloatingActionButton(
          onPressed: null, // Handled by BounceButton
          heroTag: 'category_fab',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildCategoryList(bool isIncome) {
    return Selector<FinanceProvider, List<CategoryModel>>(
      selector: (_, finance) => finance.categories.where((c) => c.isIncome == isIncome).toList(),
      shouldRebuild: (prev, next) {
        if (prev.length != next.length) return true;
        for (int i = 0; i < prev.length; i++) {
          if (prev[i] != next[i]) return true;
        }
        return false;
      },
      builder: (context, filteredCategories, _) {
        if (filteredCategories.isEmpty) {
          return Center(child: Text('No ${isIncome ? 'Income' : 'Expense'} categories'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: filteredCategories.length,
          itemBuilder: (context, index) {
            final category = filteredCategories[index];
            return Card(
              child: ListTile(
                title: Text(category.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => context.read<FinanceProvider>().deleteCategory(category),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
