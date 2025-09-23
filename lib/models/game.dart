import 'player.dart';
import 'quiz.dart';

/// Represents a game session
class Game {
  final String id;
  final String quizId;
  final String hostId;
  final List<Player> players;
  final String status; // 'waiting', 'in_progress', 'finished'
  final int currentQuestionIndex;
  final DateTime startedAt;
  final Quiz? quiz; // Optional quiz object for game play
  final Map<String, Map<int, String>>
  playerAnswers; // playerId -> {questionIndex: answerId}

  Game({
    required this.id,
    required this.quizId,
    required this.hostId,
    required this.players,
    required this.status,
    required this.currentQuestionIndex,
    required this.startedAt,
    this.quiz,
    this.playerAnswers = const {},
  });

  /// Creates a Game from a JSON map
  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as String,
      quizId: json['quizId'] as String,
      hostId: json['hostId'] as String,
      players: (json['players'] as List<dynamic>)
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String,
      currentQuestionIndex: json['currentQuestionIndex'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
      quiz: json['quiz'] != null
          ? Quiz.fromJson(json['quiz'] as Map<String, dynamic>)
          : null,
      playerAnswers: json['playerAnswers'] != null
          ? Map<String, Map<int, String>>.from(
              (json['playerAnswers'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(
                  key,
                  Map<int, String>.from(
                    (value as Map<String, dynamic>).map(
                      (k, v) => MapEntry(int.parse(k), v as String),
                    ),
                  ),
                ),
              ),
            )
          : {},
    );
  }

  /// Converts the Game to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'hostId': hostId,
      'players': players.map((p) => p.toJson()).toList(),
      'status': status,
      'currentQuestionIndex': currentQuestionIndex,
      'startedAt': startedAt.toIso8601String(),
      'quiz': quiz?.toJson(),
      'playerAnswers': playerAnswers.map(
        (key, value) =>
            MapEntry(key, value.map((k, v) => MapEntry(k.toString(), v))),
      ),
    };
  }

  /// Creates a copy of this game with updated fields
  Game copyWith({
    String? id,
    String? quizId,
    String? hostId,
    List<Player>? players,
    String? status,
    int? currentQuestionIndex,
    DateTime? startedAt,
    Quiz? quiz,
    Map<String, Map<int, String>>? playerAnswers,
  }) {
    return Game(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      hostId: hostId ?? this.hostId,
      players: players ?? this.players,
      status: status ?? this.status,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      startedAt: startedAt ?? this.startedAt,
      quiz: quiz ?? this.quiz,
      playerAnswers: playerAnswers ?? this.playerAnswers,
    );
  }
}
