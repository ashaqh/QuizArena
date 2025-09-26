import 'package:flutter/foundation.dart';
import 'lib/services/robust_ai_service.dart';

/// Test script to verify answer randomization in AI-generated questions
void main() async {
  debugPrint('🧪 Testing Answer Randomization...');

  final aiService = RobustAIService();

  // Test with fallback questions (template-based)
  final fallbackQuestions = aiService._createIntelligentFallbacks(
    'Science',
    'medium',
    5,
  );

  debugPrint('\n📊 Fallback Questions Test:');
  for (int i = 0; i < fallbackQuestions.length; i++) {
    final question = fallbackQuestions[i];
    final correctIndex = question.answers.indexWhere(
      (answer) => answer.isCorrect,
    );
    debugPrint(
      'Question ${i + 1}: Correct answer at position ${correctIndex + 1}/4',
    );
  }

  // Check if positions are varied (not all at position 0)
  final positions = fallbackQuestions
      .map((q) => q.answers.indexWhere((answer) => answer.isCorrect))
      .toList();
  final uniquePositions = positions.toSet().length;

  debugPrint('\n✅ Results:');
  debugPrint('- Total questions tested: ${fallbackQuestions.length}');
  debugPrint('- Correct answer positions found: $positions');
  debugPrint('- Unique positions: $uniquePositions/4 possible positions');
  debugPrint(
    '- Randomization ${uniquePositions > 1 ? "✅ WORKING" : "❌ NOT WORKING"}',
  );

  if (uniquePositions == 1 && positions.first == 0) {
    debugPrint(
      '⚠️  All correct answers are at position 1 - randomization failed!',
    );
  } else {
    debugPrint('🎉 Answer positions are randomized correctly!');
  }
}
