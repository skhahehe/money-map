class CategoryModel {
  final String name;
  final bool isIncome;

  CategoryModel({
    required this.name,
    required this.isIncome,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isIncome': isIncome,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      name: map['name'],
      isIncome: map['isIncome'],
    );
  }
}
