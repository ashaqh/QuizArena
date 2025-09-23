import 'dart:convert';
import 'question.dart';

/// Represents a quiz with its metadata and questions
class Quiz {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final List<Question> questions;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.questions,
    required this.createdAt,
  });

  /// Creates a Quiz from a JSON map
  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdBy: json['createdBy'] as String,
      questions: (jsonDecode(json['questions']) as List<dynamic>)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Converts the Quiz to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'questions': jsonEncode(questions.map((q) => q.toJson()).toList()),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
