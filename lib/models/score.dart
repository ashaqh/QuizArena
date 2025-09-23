/// Represents a score for a player's answer to a question
class Score {
  final String playerId;
  final String questionId;
  final int points;
  final int timeTaken; // in milliseconds

  Score({
    required this.playerId,
    required this.questionId,
    required this.points,
    required this.timeTaken,
  });

  /// Creates a Score from a JSON map
  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      playerId: json['playerId'] as String,
      questionId: json['questionId'] as String,
      points: json['points'] as int,
      timeTaken: json['timeTaken'] as int,
    );
  }

  /// Converts the Score to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'questionId': questionId,
      'points': points,
      'timeTaken': timeTaken,
    };
  }
}
