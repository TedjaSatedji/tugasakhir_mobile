enum QuestStatus { active, completed, failed }
enum QuestCategory { gadget, travel, emergency, investment, other }

class QuestModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final int xpReward;
  final double targetAmount; // Formerly moneyReward
  final double currentSavedAmount; // New field
  final QuestCategory category;
  final QuestStatus status;
  final DateTime deadline;
  final DateTime createdAt;
  final int progressPercentage; // Kept for legacy/UI convenience

  QuestModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.targetAmount,
    required this.currentSavedAmount,
    required this.category,
    required this.status,
    required this.deadline,
    required this.createdAt,
    required this.progressPercentage,
  });

  factory QuestModel.fromJson(Map<String, dynamic> json) {
    return QuestModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      description: json['description'] ?? '',
      xpReward: json['xpReward'] ?? 500, // Fixed XP reward for completing a goal
      targetAmount: (json['targetAmount'] ?? json['moneyReward'] ?? 0).toDouble(), // Support legacy key
      currentSavedAmount: (json['currentSavedAmount'] ?? 0).toDouble(),
      category: QuestCategory.values[json['category'] ?? 0],
      status: QuestStatus.values[json['status'] ?? 0],
      deadline: DateTime.parse(json['deadline'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      progressPercentage: json['progressPercentage'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'xpReward': xpReward,
      'targetAmount': targetAmount,
      'currentSavedAmount': currentSavedAmount,
      'category': category.index,
      'status': status.index,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'progressPercentage': progressPercentage,
    };
  }

  QuestModel copyWith({
    int? progressPercentage,
    QuestStatus? status,
    double? currentSavedAmount,
  }) {
    return QuestModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      xpReward: xpReward,
      targetAmount: targetAmount,
      currentSavedAmount: currentSavedAmount ?? this.currentSavedAmount,
      category: category,
      status: status ?? this.status,
      deadline: deadline,
      createdAt: createdAt,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }
}