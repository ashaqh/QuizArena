/// Game history record for tracking individual game performances
class GameHistoryRecord {
  final String id;
  final String gameId;
  final String userId;
  final String quizId;
  final String quizTitle;
  final String role; // 'host' or 'player'
  final DateTime playedAt;
  final int? playerScore; // null if user was host
  final int? playerRank; // null if user was host, 1-based ranking
  final int totalPlayers;
  final int totalQuestions;
  final double? accuracyPercentage; // null if user was host
  final Duration gameDuration;
  final Map<String, dynamic> metadata; // additional game-specific data

  GameHistoryRecord({
    required this.id,
    required this.gameId,
    required this.userId,
    required this.quizId,
    required this.quizTitle,
    required this.role,
    required this.playedAt,
    this.playerScore,
    this.playerRank,
    required this.totalPlayers,
    required this.totalQuestions,
    this.accuracyPercentage,
    required this.gameDuration,
    this.metadata = const {},
  });

  /// Creates a GameHistoryRecord from a JSON map
  factory GameHistoryRecord.fromJson(Map<String, dynamic> json) {
    return GameHistoryRecord(
      id: json['id'] as String,
      gameId: json['gameId'] as String,
      userId: json['userId'] as String,
      quizId: json['quizId'] as String,
      quizTitle: json['quizTitle'] as String,
      role: json['role'] as String,
      playedAt: DateTime.parse(json['playedAt'] as String),
      playerScore: json['playerScore'] as int?,
      playerRank: json['playerRank'] as int?,
      totalPlayers: json['totalPlayers'] as int,
      totalQuestions: json['totalQuestions'] as int,
      accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble(),
      gameDuration: Duration(
        milliseconds: json['gameDurationMs'] as int,
      ),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Converts the GameHistoryRecord to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameId': gameId,
      'userId': userId,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'role': role,
      'playedAt': playedAt.toIso8601String(),
      'playerScore': playerScore,
      'playerRank': playerRank,
      'totalPlayers': totalPlayers,
      'totalQuestions': totalQuestions,
      'accuracyPercentage': accuracyPercentage,
      'gameDurationMs': gameDuration.inMilliseconds,
      'metadata': metadata,
    };
  }

  /// Creates a copy of this record with updated values
  GameHistoryRecord copyWith({
    String? id,
    String? gameId,
    String? userId,
    String? quizId,
    String? quizTitle,
    String? role,
    DateTime? playedAt,
    int? playerScore,
    int? playerRank,
    int? totalPlayers,
    int? totalQuestions,
    double? accuracyPercentage,
    Duration? gameDuration,
    Map<String, dynamic>? metadata,
  }) {
    return GameHistoryRecord(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      userId: userId ?? this.userId,
      quizId: quizId ?? this.quizId,
      quizTitle: quizTitle ?? this.quizTitle,
      role: role ?? this.role,
      playedAt: playedAt ?? this.playedAt,
      playerScore: playerScore ?? this.playerScore,
      playerRank: playerRank ?? this.playerRank,
      totalPlayers: totalPlayers ?? this.totalPlayers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      accuracyPercentage: accuracyPercentage ?? this.accuracyPercentage,
      gameDuration: gameDuration ?? this.gameDuration,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if this was a winning game (1st place for player)
  bool get isWin => role == 'player' && playerRank == 1;

  /// Check if this was a hosted game
  bool get isHosted => role == 'host';

  /// Get performance level based on rank and total players
  String get performanceLevel {
    if (role == 'host') return 'Host';
    if (playerRank == null) return 'Unknown';
    
    final percentage = playerRank! / totalPlayers;
    if (percentage <= 0.1) return 'Excellent';
    if (percentage <= 0.25) return 'Great';
    if (percentage <= 0.5) return 'Good';
    if (percentage <= 0.75) return 'Fair';
    return 'Needs Improvement';
  }

  /// Get a formatted duration string
  String get formattedDuration {
    final minutes = gameDuration.inMinutes;
    final seconds = gameDuration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}

/// Achievement model for tracking user milestones
class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final DateTime unlockedAt;
  final AchievementCategory category;
  final int points;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.unlockedAt,
    required this.category,
    required this.points,
  });

  /// Creates an Achievement from a JSON map
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AchievementCategory.general,
      ),
      points: json['points'] as int,
    );
  }

  /// Converts the Achievement to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconUrl': iconUrl,
      'unlockedAt': unlockedAt.toIso8601String(),
      'category': category.name,
      'points': points,
    };
  }
}

/// Categories for achievements
enum AchievementCategory {
  general,
  hosting,
  playing,
  social,
  creative,
  streak,
}

/// Leaderboard entry model
class LeaderboardEntry {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int score;
  final int rank;
  final String category; // 'global', 'weekly', 'quiz-specific', etc.

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.score,
    required this.rank,
    required this.category,
  });

  /// Creates a LeaderboardEntry from a JSON map
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      score: json['score'] as int,
      rank: json['rank'] as int,
      category: json['category'] as String,
    );
  }

  /// Converts the LeaderboardEntry to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'avatarUrl': avatarUrl,
      'score': score,
      'rank': rank,
      'category': category,
    };
  }
}