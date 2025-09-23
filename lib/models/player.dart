import 'score.dart';

/// Represents a player in a game
class Player {
  final String id;
  final String name;
  final int totalScore;
  final List<Score> scores;

  Player({
    required this.id,
    required this.name,
    required this.totalScore,
    required this.scores,
  });

  /// Creates a Player from a JSON map
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      totalScore: json['totalScore'] as int,
      scores: (json['scores'] as List<dynamic>)
          .map((s) => Score.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Converts the Player to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalScore': totalScore,
      'scores': scores.map((s) => s.toJson()).toList(),
    };
  }

  /// Creates a copy of this player with updated fields
  Player copyWith({
    String? id,
    String? name,
    int? totalScore,
    List<Score>? scores,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      totalScore: totalScore ?? this.totalScore,
      scores: scores ?? this.scores,
    );
  }
}
