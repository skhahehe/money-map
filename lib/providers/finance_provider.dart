import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class FinanceProvider with ChangeNotifier {
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  Map<String, String?> _userImages = {};
  double _balance = 0;

  // Settings & Users
  ThemeMode _themeMode = ThemeMode.system;
  List<String> _users = ['Default User'];
  String _currentUser = 'Default User';
  int _startDayOfMonth = 1;

  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  double get balance => _balance;
  Map<String, String?> get userImages => _userImages;
  String? get currentUserImage => _userImages[_currentUser];

  ThemeMode get themeMode => _themeMode;
  List<String> get users => _users;
  String get currentUser => _currentUser;
  int get startDayOfMonth => _startDayOfMonth;

  FinanceProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadGlobalSettings();
    await _loadUserData();
  }

  Future<void> refreshAllData() async {
    await _init();
    notifyListeners();
  }

  // --- Core Utility: Date Normalization & Validation ---

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool isFutureDate(DateTime date) {
    final today = _normalizeDate(DateTime.now());
    final target = _normalizeDate(date);
    return target.isAfter(today);
  }

  // --- Global Settings ---

  Future<void> _loadGlobalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 2;
    _themeMode = ThemeMode.values[themeIndex];
    _users = prefs.getStringList('users_list') ?? ['Default User'];
    _currentUser = prefs.getString('current_user') ?? _users.first;
    _startDayOfMonth = prefs.getInt('startDayOfMonth') ?? 1;

    final imagesJson = prefs.getString('user_images');
    if (imagesJson != null) {
      _userImages = Map<String, String?>.from(jsonDecode(imagesJson));
    }

    notifyListeners();
  }

  // --- User-Specific Data Loading ---

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final catData = prefs.getString('${_currentUser}_categories');
    if (catData != null) {
      final List decoded = jsonDecode(catData);
      _categories = decoded.map((e) => CategoryModel.fromMap(e)).toList();
    } else {
      _categories = [
        CategoryModel(name: 'Salary', isIncome: true),
        CategoryModel(name: 'Food', isIncome: false),
      ];
    }

    final transData = prefs.getString('${_currentUser}_transactions');
    if (transData != null) {
      final List decoded = jsonDecode(transData);
      _transactions = decoded.map((e) => TransactionModel.fromMap(e)).toList();
      _transactions.removeWhere((t) => isFutureDate(t.date));
      _transactions.sort((a, b) => a.date.compareTo(b.date));
    } else {
      _transactions = [];
    }
    
    _calculateBalance();
  }

  // --- User Management ---

  Future<void> switchUser(String name) async {
    if (!_users.contains(name)) return;
    _currentUser = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', name);
    await _loadUserData();
    notifyListeners();
  }

  Future<void> addUser(String name) async {
    if (name.isEmpty || _users.contains(name)) return;
    _users.add(name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('users_list', _users);
    await switchUser(name);
  }

  Future<void> removeUser(String name) async {
    if (_users.length <= 1 || !_users.contains(name)) return;
    _users.remove(name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('users_list', _users);
    await prefs.remove('${name}_categories');
    await prefs.remove('${name}_transactions');
    if (_currentUser == name) {
      await switchUser(_users.first);
    } else {
      notifyListeners();
    }
  }

  // --- Settings ---

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> setStartDayOfMonth(int day) async {
    _startDayOfMonth = day;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('startDayOfMonth', day);
    notifyListeners();
  }

  void _calculateBalance() {
    _balance = 0;
    for (var t in _transactions) {
      if (t.isIncome) {
        _balance += t.amount;
      } else {
        _balance -= t.amount;
      }
    }
    notifyListeners();
  }

  Future<void> setUserImage(String name, String? path) async {
    _userImages[name] = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_images', jsonEncode(_userImages));
    notifyListeners();
  }

  // --- Category Operations ---

  Future<void> saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_categories.map((e) => e.toMap()).toList());
    await prefs.setString('${_currentUser}_categories', encoded);
  }

  void addCategory(String name, bool isIncome) {
    _categories.add(CategoryModel(name: name, isIncome: isIncome));
    saveCategories();
    notifyListeners();
  }

  void deleteCategory(CategoryModel category) {
    _categories.remove(category);
    saveCategories();
    notifyListeners();
  }

  // --- Transaction Operations ---

  Future<void> saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    _transactions.sort((a, b) => a.date.compareTo(b.date));
    final encoded = jsonEncode(_transactions.map((e) => e.toMap()).toList());
    await prefs.setString('${_currentUser}_transactions', encoded);
  }

  void addTransaction(TransactionModel transaction) {
    if (isFutureDate(transaction.date)) {
      debugPrint('🚨 BLOCKED: Attempt to add a transaction with a future date: ${transaction.date}');
      return; 
    }
    _transactions.add(transaction);
    _calculateBalance();
    saveTransactions();
  }

  // --- Dashboard & Filtering Calculations ---

  double get currentBalance => _balance;

  double get savings {
    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, _startDayOfMonth);
    double amount = 0;
    for (var t in _transactions) {
      if (t.date.isBefore(startDay)) amount += t.isIncome ? t.amount : -t.amount;
    }
    return amount;
  }

  double get spentThisMonth {
    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, _startDayOfMonth);
    double amount = 0;
    for (var t in _transactions) {
      if (!t.isIncome && (t.date.isAtSameMomentAs(startDay) || t.date.isAfter(startDay))) {
        amount += t.amount;
      }
    }
    return amount;
  }

  /// 📊 Returns daily income/expense stats for a specific month/year.
  Map<int, Map<String, double>> getDailyStatsForMonth(int year, int month) {
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final Map<int, Map<String, double>> stats = {
      for (int i = 1; i <= lastDayOfMonth; i++) 
        i: {'income': 0.0, 'expense': 0.0}
    };

    for (var t in _transactions) {
      if (t.date.year == year && t.date.month == month) {
        final day = t.date.day;
        if (t.isIncome) {
          stats[day]!['income'] = stats[day]!['income']! + t.amount;
        } else {
          stats[day]!['expense'] = stats[day]!['expense']! + t.amount;
        }
      }
    }
    return stats;
  }

  List<TransactionModel> getRecentTransactions(int count) {
    final sorted = List<TransactionModel>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(count).toList();
  }

  List<TransactionModel> getTransactionsInPastDays(int days) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    return _transactions
        .where((t) => t.date.isAfter(cutoff) || (t.date.year == cutoff.year && t.date.month == cutoff.month && t.date.day == cutoff.day))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TransactionModel> getTransactionsByMonth(int year, int month) {
    final filtered = _transactions.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  List<int> getAvailableYears() {
    final currentYear = DateTime.now().year;
    final List<int> years = [];
    for (int i = currentYear; i >= 1900; i--) {
      years.add(i);
    }
    return years;
  }

  /// 📅 Returns transactions within a specific range, normalized to start/end of day.
  List<TransactionModel> getTransactionsInRange(DateTime from, DateTime to) {
    final start = _normalizeDate(from);
    final end = _normalizeDate(to);
    
    final filtered = _transactions.where((t) {
      final tDate = _normalizeDate(t.date);
      return (tDate.isAtSameMomentAs(start) || tDate.isAfter(start)) &&
             (tDate.isAtSameMomentAs(end) || tDate.isBefore(end));
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }
}
