/// User profile model for storing user information and preferences
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime joinDate;
  final bool sharePublicly;
  final bool saveHistory;
  final UserStatistics statistics;
  final Map<String, dynamic> preferences;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.joinDate,
    this.sharePublicly = true,
    this.saveHistory = true,
    required this.statistics,
    this.preferences = const {},
  });

  /// Creates a UserProfile from a JSON map
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      joinDate: DateTime.parse(json['joinDate'] as String),
      sharePublicly: json['sharePublicly'] as bool? ?? true,
      saveHistory: json['saveHistory'] as bool? ?? true,
      statistics: UserStatistics.fromJson(
        json['statistics'] as Map<String, dynamic>? ?? {},
      ),
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Converts the UserProfile to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'joinDate': joinDate.toIso8601String(),
      'sharePublicly': sharePublicly,
      'saveHistory': saveHistory,
      'statistics': statistics.toJson(),
      'preferences': preferences,
    };
  }

  /// Creates a copy of this UserProfile with updated values
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    DateTime? joinDate,
    bool? sharePublicly,
    bool? saveHistory,
    UserStatistics? statistics,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinDate: joinDate ?? this.joinDate,
      sharePublicly: sharePublicly ?? this.sharePublicly,
      saveHistory: saveHistory ?? this.saveHistory,
      statistics: statistics ?? this.statistics,
      preferences: preferences ?? this.preferences,
    );
  }
}

/// User statistics model for tracking game performance
class UserStatistics {
  final int totalGamesHosted;
  final int totalGamesPlayed;
  final int totalPlayersHosted;
  final int totalQuizzesCreated;
  final double averageScoreAsPlayer;
  final int bestScoreAsPlayer;
  final int currentWinStreak;
  final int longestWinStreak;
  final List<String> achievements;
  final Map<String, int> categoryPerformance; // category -> average score
  final DateTime lastActive;

  UserStatistics({
    this.totalGamesHosted = 0,
    this.totalGamesPlayed = 0,
    this.totalPlayersHosted = 0,
    this.totalQuizzesCreated = 0,
    this.averageScoreAsPlayer = 0.0,
    this.bestScoreAsPlayer = 0,
    this.currentWinStreak = 0,
    this.longestWinStreak = 0,
    this.achievements = const [],
    this.categoryPerformance = const {},
    required this.lastActive,
  });

  /// Creates UserStatistics from a JSON map
  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      totalGamesHosted: json['totalGamesHosted'] as int? ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] as int? ?? 0,
      totalPlayersHosted: json['totalPlayersHosted'] as int? ?? 0,
      totalQuizzesCreated: json['totalQuizzesCreated'] as int? ?? 0,
      averageScoreAsPlayer:
          (json['averageScoreAsPlayer'] as num?)?.toDouble() ?? 0.0,
      bestScoreAsPlayer: json['bestScoreAsPlayer'] as int? ?? 0,
      currentWinStreak: json['currentWinStreak'] as int? ?? 0,
      longestWinStreak: json['longestWinStreak'] as int? ?? 0,
      achievements: List<String>.from(json['achievements'] as List? ?? []),
      categoryPerformance: Map<String, int>.from(
        json['categoryPerformance'] as Map<String, dynamic>? ?? {},
      ),
      lastActive: DateTime.parse(
        json['lastActive'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Converts UserStatistics to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'totalGamesHosted': totalGamesHosted,
      'totalGamesPlayed': totalGamesPlayed,
      'totalPlayersHosted': totalPlayersHosted,
      'totalQuizzesCreated': totalQuizzesCreated,
      'averageScoreAsPlayer': averageScoreAsPlayer,
      'bestScoreAsPlayer': bestScoreAsPlayer,
      'currentWinStreak': currentWinStreak,
      'longestWinStreak': longestWinStreak,
      'achievements': achievements,
      'categoryPerformance': categoryPerformance,
      'lastActive': lastActive.toIso8601String(),
    };
  }

  /// Creates a copy with updated values
  UserStatistics copyWith({
    int? totalGamesHosted,
    int? totalGamesPlayed,
    int? totalPlayersHosted,
    int? totalQuizzesCreated,
    double? averageScoreAsPlayer,
    int? bestScoreAsPlayer,
    int? currentWinStreak,
    int? longestWinStreak,
    List<String>? achievements,
    Map<String, int>? categoryPerformance,
    DateTime? lastActive,
  }) {
    return UserStatistics(
      totalGamesHosted: totalGamesHosted ?? this.totalGamesHosted,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalPlayersHosted: totalPlayersHosted ?? this.totalPlayersHosted,
      totalQuizzesCreated: totalQuizzesCreated ?? this.totalQuizzesCreated,
      averageScoreAsPlayer: averageScoreAsPlayer ?? this.averageScoreAsPlayer,
      bestScoreAsPlayer: bestScoreAsPlayer ?? this.bestScoreAsPlayer,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      longestWinStreak: longestWinStreak ?? this.longestWinStreak,
      achievements: achievements ?? this.achievements,
      categoryPerformance: categoryPerformance ?? this.categoryPerformance,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
