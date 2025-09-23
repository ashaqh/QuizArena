import 'answer.dart';

/// Represents a question in a quiz
class Question {
  final String id;
  final String text;
  final List<Answer> answers;
  final String correctAnswerId;
  final int timeLimit; // in seconds

  Question({
    required this.id,
    required this.text,
    required this.answers,
    required this.correctAnswerId,
    required this.timeLimit,
  });

  /// Creates a Question from a JSON map
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      answers: (json['answers'] as List<dynamic>)
          .map((a) => Answer.fromJson(a as Map<String, dynamic>))
          .toList(),
      correctAnswerId: json['correctAnswerId'] as String,
      timeLimit: json['timeLimit'] as int,
    );
  }

  /// Converts the Question to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'answers': answers.map((a) => a.toJson()).toList(),
      'correctAnswerId': correctAnswerId,
      'timeLimit': timeLimit,
    };
  }
}
