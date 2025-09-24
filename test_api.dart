import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple test script to verify OpenRouter API key works
void main() async {
  const apiKey =
      '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';

  print('🔑 Testing OpenRouter API key...');

  try {
    // Test 1: List models
    final response = await http
        .get(
          Uri.parse('https://openrouter.ai/api/v1/models'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 10));

    print('📡 Models API Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final models = data['data'] as List;
      print('✅ API Key is valid! Found ${models.length} models');

      // Show first few free models
      final freeModels = models
          .where((model) {
            final pricing = model['pricing'] as Map<String, dynamic>?;
            if (pricing == null) return false;
            final promptPrice = pricing['prompt'] as String?;
            final completionPrice = pricing['completion'] as String?;
            return (promptPrice == '0' || promptPrice == '0.0') &&
                (completionPrice == '0' || completionPrice == '0.0');
          })
          .take(5)
          .toList();

      print('🆓 Free models available:');
      for (final model in freeModels) {
        print('  - ${model['id']}');
      }

      // Test 2: Generate a simple question
      print('\n🤖 Testing question generation...');
      final testResponse = await http
          .post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://quizarena.app',
              'X-Title': 'QuizArena Test',
            },
            body: jsonEncode({
              'model': 'meta-llama/llama-3.2-3b-instruct:free',
              'messages': [
                {
                  'role': 'user',
                  'content':
                      'Create 1 multiple choice question about science. Format: Question: [question] A) [option] B) [option] C) [option] D) [option] Correct: [A/B/C/D]',
                },
              ],
              'temperature': 0.7,
              'max_tokens': 300,
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('🔬 Generation API Response: ${testResponse.statusCode}');

      if (testResponse.statusCode == 200) {
        final genData = jsonDecode(testResponse.body);
        final content =
            genData['choices']?[0]?['message']?['content'] as String?;
        print('✅ Question generation works!');
        print('📝 Generated content:\n$content');
      } else {
        print('❌ Question generation failed: ${testResponse.statusCode}');
        print('Error: ${testResponse.body}');
      }
    } else {
      print('❌ API Key invalid: ${response.statusCode}');
      print('Error: ${response.body}');
    }
  } catch (e) {
    print('❌ Test failed: $e');
  }
}
