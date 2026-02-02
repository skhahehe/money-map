class TransactionModel {
  final double amount;
  final DateTime date;
  final bool isIncome;
  final String category;

  TransactionModel({
    required this.amount,
    required this.date,
    required this.isIncome,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'isIncome': isIncome,
      'category': category,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      isIncome: map['isIncome'],
      category: map['category'],
    );
  }
}
