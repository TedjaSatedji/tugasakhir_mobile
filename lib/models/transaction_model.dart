enum TransactionType { income, expense, transfer }
enum ExpenseCategory {
  food,
  fashion,
  hobby,
  transport,
  health,
  education,
  entertainment,
  other
}

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final ExpenseCategory? category;
  final double amount;
  final String description;
  final DateTime timestamp;
  final String? receiptImageUrl;
  final String? detectedCategory;
  final double? latitude;
  final double? longitude;
  final String? locationName;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    this.category,
    required this.amount,
    required this.description,
    required this.timestamp,
    this.receiptImageUrl,
    this.detectedCategory,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['userId'],
      type: TransactionType.values[json['type'] ?? 0],
      category: json['category'] != null
          ? ExpenseCategory.values[json['category']]
          : null,
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      receiptImageUrl: json['receiptImageUrl'] as String?,
      detectedCategory: json['detectedCategory'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['locationName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.index,
      'category': category?.index,
      'amount': amount,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'receiptImageUrl': receiptImageUrl,
      'detectedCategory': detectedCategory,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
    };
  }
}