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
  final int xpAwarded;
  final int coinsAwarded;
  final String? missionCompletedId;
  final String? missionCompletedDateKey;

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
    this.xpAwarded = 0,
    this.coinsAwarded = 0,
    this.missionCompletedId,
    this.missionCompletedDateKey,
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
      xpAwarded: json['xpAwarded'] ?? 0,
      coinsAwarded: json['coinsAwarded'] ?? 0,
      missionCompletedId: json['missionCompletedId'] as String?,
      missionCompletedDateKey: json['missionCompletedDateKey'] as String?,
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
      'xpAwarded': xpAwarded,
      'coinsAwarded': coinsAwarded,
      'missionCompletedId': missionCompletedId,
      'missionCompletedDateKey': missionCompletedDateKey,
    };
  }

  TransactionModel copyWith({
    TransactionType? type,
    ExpenseCategory? category,
    double? amount,
    String? description,
    DateTime? timestamp,
    String? receiptImageUrl,
    String? detectedCategory,
    double? latitude,
    double? longitude,
    String? locationName,
    int? xpAwarded,
    int? coinsAwarded,
    String? missionCompletedId,
    String? missionCompletedDateKey,
  }) {
    return TransactionModel(
      id: id,
      userId: userId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      detectedCategory: detectedCategory ?? this.detectedCategory,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      coinsAwarded: coinsAwarded ?? this.coinsAwarded,
      missionCompletedId: missionCompletedId ?? this.missionCompletedId,
      missionCompletedDateKey: missionCompletedDateKey ?? this.missionCompletedDateKey,
    );
  }
}