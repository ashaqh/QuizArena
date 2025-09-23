import 'answer.dart';

/// Represents a question in a quiz
class Question {
  final String id;
  final String text;
  final List<Answer> answers;
  final String correctAnswerId;
  final int timeLimit; // in seconds
  final String? imageUrl; // Optional image URL (can be web URL or local path)

  Question({
    required this.id,
    required this.text,
    required this.answers,
    required this.correctAnswerId,
    required this.timeLimit,
    this.imageUrl,
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
      imageUrl: json['imageUrl'] as String?,
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
      'imageUrl': imageUrl,
    };
  }

  /// Creates a copy of this Question with optionally updated fields
  Question copyWith({
    String? id,
    String? text,
    List<Answer>? answers,
    String? correctAnswerId,
    int? timeLimit,
    String? imageUrl,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      answers: answers ?? this.answers,
      correctAnswerId: correctAnswerId ?? this.correctAnswerId,
      timeLimit: timeLimit ?? this.timeLimit,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
