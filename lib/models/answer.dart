/// Represents an answer option for a question
class Answer {
  final String id;
  final String text;
  final bool isCorrect;

  Answer({required this.id, required this.text, required this.isCorrect});

  /// Creates an Answer from a JSON map
  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'] as String,
      text: json['text'] as String,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  /// Converts the Answer to a JSON map
  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'isCorrect': isCorrect};
  }

  // Add this copyWith method:
  Answer copyWith({
    String? id,
    String? text,
    bool? isCorrect,
  }) {
    return Answer(
      id: id ?? this.id,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}
