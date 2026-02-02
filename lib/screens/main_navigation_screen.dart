import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'home_screen.dart';
import 'transaction_overview_screen.dart';
import 'category_screen.dart';
import 'settings_screen.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/bounce_button.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = const [
    HomeScreen(),
    TransactionOverviewScreen(),
    CategoryScreen(),
    SettingsScreen(),
  ];

  void _openAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );
  }

  Drag? _drag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _pages,
          ),
          // Bottom Swipe Zone - Restricted to lower part of the screen
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 150, // Slightly larger zone for better touch target
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (details) {
                _drag = _pageController.position.drag(details, () {
                  _drag = null;
                });
              },
              onHorizontalDragUpdate: (details) {
                _drag?.update(details);
              },
              onHorizontalDragEnd: (details) {
                _drag?.end(details);
              },
              onHorizontalDragCancel: () {
                _drag?.cancel();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            BounceButton(
              onTap: () {
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.home, color: _currentIndex == 0 ? Colors.blue : Colors.grey),
              ),
            ),
            BounceButton(
              onTap: () {
                _pageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.list_alt, color: _currentIndex == 1 ? Colors.blue : Colors.grey),
              ),
            ),
            const SizedBox(width: 48), // Space for floating button
            BounceButton(
              onTap: () {
                _pageController.animateToPage(
                  2,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.category, color: _currentIndex == 2 ? Colors.blue : Colors.grey),
              ),
            ),
            BounceButton(
              onTap: () {
                _pageController.animateToPage(
                  3,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.settings, color: _currentIndex == 3 ? Colors.blue : Colors.grey),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: BounceButton(
        onTap: _openAddTransactionSheet,
        child: FloatingActionButton(
          onPressed: null, // Handled by BounceButton
          heroTag: 'main_nav_fab',
          shape: const CircleBorder(),
          tooltip: 'Add Transaction',
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
