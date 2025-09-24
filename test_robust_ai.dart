import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'lib/services/robust_ai_service.dart';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: '.env');

  final aiService = RobustAIService();

  print('🧪 Testing Robust AI Service...');
  print('================================');

  // Test 1: Check if we can generate with all available models
  print('\n📋 Test 1: Generate with auto-select (all models)');
  await testGeneration(aiService, 'Mathematics', 'medium', 3, null);

  // Test 2: Check if we can generate with a specific model
  print('\n📋 Test 2: Generate with specific model');
  await testGeneration(
    aiService,
    'History',
    'easy',
    2,
    'meta-llama/llama-3.2-3b-instruct:free',
  );

  print('\n✅ Test completed!');
}

Future<void> testGeneration(
  RobustAIService service,
  String topic,
  String difficulty,
  int count,
  String? preferredModel,
) async {
  print('Topic: $topic, Difficulty: $difficulty, Count: $count');
  if (preferredModel != null) {
    print('Preferred Model: $preferredModel');
  }

  final stopwatch = Stopwatch()..start();

  try {
    await for (final progress in service.generateQuestionsWithProgress(
      topic: topic,
      difficulty: difficulty,
      count: count,
      preferredModel: preferredModel,
    )) {
      print('${(progress.progress * 100).toInt()}% - ${progress.message}');

      if (progress.status == GenerationStatus.completed) {
        stopwatch.stop();
        print('✅ Generation completed in ${stopwatch.elapsedMilliseconds}ms');

        // Get final result
        final result = await service.generateQuestions(
          topic: topic,
          difficulty: difficulty,
          count: count,
          preferredModel: preferredModel,
        );

        print('📊 Result: ${result.questions.length} questions generated');
        print(
          '🔧 Used: ${result.usedProvider} / ${result.usedModel ?? "auto"}',
        );
        print('⏱️  Total time: ${result.totalTime.inMilliseconds}ms');
        print('🔄 Attempts: ${result.totalAttempts}');

        break;
      } else if (progress.status == GenerationStatus.failed) {
        print('❌ Generation failed: ${progress.message}');
        break;
      }
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
