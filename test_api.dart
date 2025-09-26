import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Simple test script to verify OpenRouter API key works
void main() async {
  // Load API key from .env file
  final envFile = File('.env');
  String? apiKey;
  
  if (await envFile.exists()) {
    final envContent = await envFile.readAsString();
    final lines = envContent.split('\n');
    for (final line in lines) {
      if (line.startsWith('OPENROUTER_API_KEY=')) {
        apiKey = line.split('=')[1].trim();
        break;
      }
    }
  }
  
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ OPENROUTER_API_KEY not found in .env file');
    return;
  }

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

      // Test 2: Check account status
      print('\n💳 Checking account status...');
      final statusResponse = await http
          .get(
            Uri.parse('https://openrouter.ai/api/v1/auth/key'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Auth Status: ${statusResponse.statusCode}');
      if (statusResponse.statusCode == 200) {
        final authData = jsonDecode(statusResponse.body);
        print('Account data: $authData');
      } else {
        print('Auth Error: ${statusResponse.body}');
      }

      // Test 3: Generate a simple question
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
                  'content': 'Hello, just say "TEST SUCCESS"',
                },
              ],
              'temperature': 0.7,
              'max_tokens': 50,
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
        
        // Try a different free model
        print('\n🔄 Trying different free model...');
        final testResponse2 = await http
            .post(
              Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'https://quizarena.app',
                'X-Title': 'QuizArena Test',
              },
              body: jsonEncode({
                'model': 'deepseek/deepseek-chat-v3.1:free',
                'messages': [
                  {
                    'role': 'user',
                    'content': 'Hello, just say "TEST SUCCESS"',
                  },
                ],
                'max_tokens': 50,
              }),
            )
            .timeout(const Duration(seconds: 30));

        print('Second model response: ${testResponse2.statusCode}');
        if (testResponse2.statusCode == 200) {
          final genData2 = jsonDecode(testResponse2.body);
          final content2 =
              genData2['choices']?[0]?['message']?['content'] as String?;
          print('✅ Second model works!');
          print('📝 Generated content:\n$content2');
        } else {
          print('❌ Second model also failed: ${testResponse2.body}');
        }
      }
    } else {
      print('❌ API Key invalid: ${response.statusCode}');
      print('Error: ${response.body}');
    }
  } catch (e) {
    print('❌ Test failed: $e');
  }
}
