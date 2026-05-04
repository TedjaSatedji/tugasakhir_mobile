class LeaderboardEntry {
  final int rank;
  final String name;
  final String? avatarUrl;
  final int highScore;
  final String emailPrefix;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    this.avatarUrl,
    required this.highScore,
    required this.emailPrefix,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json,
      {bool isCurrentUser = false}) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      highScore: json['high_score'] as int,
      emailPrefix: json['email_prefix'] as String,
      isCurrentUser: isCurrentUser,
    );
  }
}
