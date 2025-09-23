import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/question.dart';
import '../models/answer.dart';

class AIService {
  final Uuid _uuid = const Uuid();

  // OpenRouter API configuration
  final String _openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
  final String _openRouterModelsUrl = 'https://openrouter.ai/api/v1/models';

  // Free AI API endpoints (no API keys required)
  final String _huggingFaceUrl =
      'https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium';
  final String _backupUrl = 'https://api-inference.huggingface.co/models/gpt2';

  // Free OpenRouter models (no cost or very low cost)
  final List<String> _freeModels = [
    'meta-llama/llama-3.2-3b-instruct:free',
    'microsoft/wizardlm-2-8x22b:free',
    'mistralai/mistral-7b-instruct:free',
    'huggingface/zephyr-7b-beta:free',
    'google/gemma-7b-it:free',
  ];

  // Test OpenRouter API key and connection
  Future<bool> testOpenRouterConnection() async {
    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('AIService: No OpenRouter API key configured');
        return false;
      }

      debugPrint(
        'AIService: Testing OpenRouter connection with key: ${apiKey.substring(0, 10)}...',
      );

      final response = await http
          .get(
            Uri.parse(_openRouterModelsUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('AIService: OpenRouter test response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['data'] as List<dynamic>?;
        debugPrint(
          'AIService: OpenRouter connection successful, found ${models?.length ?? 0} models',
        );
        return true;
      } else {
        debugPrint(
          'AIService: OpenRouter connection failed: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('AIService: OpenRouter connection test failed: $e');
      return false;
    }
  }

  // Get available free models from OpenRouter
  Future<List<Map<String, dynamic>>> getFreeModels() async {
    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('AIService: No OpenRouter API key found');
        return _getDefaultFreeModels();
      }

      final response = await http.get(
        Uri.parse(_openRouterModelsUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['data'] as List<dynamic>;

        // Filter for free models
        final freeModels = models.where((model) {
          final modelId = model['id'] as String;
          debugPrint('AIService: Checking model: $modelId');
          final pricing = model['pricing'] as Map<String, dynamic>?;
          if (pricing == null) return false;

          final promptPrice = pricing['prompt'] as String?;
          final completionPrice = pricing['completion'] as String?;

          // Consider it free if pricing is 0 or very low
          return (promptPrice == '0' || promptPrice == '0.0') &&
              (completionPrice == '0' || completionPrice == '0.0');
        }).toList();

        debugPrint('AIService: Found ${freeModels.length} free models');
        return freeModels.cast<Map<String, dynamic>>();
      } else {
        debugPrint('AIService: Failed to fetch models: ${response.statusCode}');
        return _getDefaultFreeModels();
      }
    } catch (e) {
      debugPrint('AIService: Error fetching models: $e');
      return _getDefaultFreeModels();
    }
  }

  List<Map<String, dynamic>> _getDefaultFreeModels() {
    return _freeModels
        .map(
          (modelId) => {
            'id': modelId,
            'name': modelId.split('/').last.split(':').first,
            'pricing': {'prompt': '0', 'completion': '0'},
          },
        )
        .toList();
  }

  // Generate questions using OpenRouter
  Future<String?> _generateWithOpenRouter(
    String topic,
    String difficulty,
    int count,
    String modelId,
  ) async {
    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint(
          'AIService: No OpenRouter API key found - falling back to free APIs',
        );
        return null;
      }

      debugPrint('AIService: Using OpenRouter with model: $modelId');

      final prompt =
          '''
You are an expert educator creating multiple-choice quiz questions.

Create $count high-quality multiple-choice questions specifically about: "$topic"
Difficulty level: $difficulty

IMPORTANT REQUIREMENTS:
- Questions must be directly related to "$topic"
- Each question needs exactly 4 answer options (A, B, C, D)
- Only one answer should be correct
- Questions should be educational and accurate
- Avoid generic questions - make them topic-specific

Format each question exactly like this:
Question: [Specific question about $topic]
A) [Answer option 1]
B) [Answer option 2]
C) [Answer option 3]
D) [Answer option 4]
Correct: [A/B/C/D]

Separate each complete question with ---
''';

      final response = await http
          .post(
            Uri.parse(_openRouterUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://quizarena.app',
              'X-Title': 'QuizArena',
            },
            body: jsonEncode({
              'model': modelId,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.7,
              'max_tokens': 2000,
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('AIService: OpenRouter API status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          debugPrint(
            'AIService: OpenRouter success - generated ${content.length} chars',
          );
          debugPrint(
            'AIService: Content preview: ${content.substring(0, content.length > 100 ? 100 : content.length)}...',
          );
          return content;
        } else {
          debugPrint('AIService: OpenRouter returned empty content');
        }
      } else {
        debugPrint(
          'AIService: OpenRouter API error (${response.statusCode}): ${response.body}',
        );
        // Check for specific error types
        if (response.statusCode == 401) {
          debugPrint(
            'AIService: OpenRouter authentication failed - check API key',
          );
        } else if (response.statusCode == 429) {
          debugPrint('AIService: OpenRouter rate limit exceeded');
        } else if (response.statusCode == 402) {
          debugPrint('AIService: OpenRouter insufficient credits');
        }
      }
    } catch (e) {
      debugPrint('AIService: OpenRouter API failed: $e');
      if (e.toString().contains('timeout')) {
        debugPrint('AIService: OpenRouter request timed out');
      }
    }
    debugPrint('AIService: OpenRouter failed, will try fallback APIs');
    return null;
  }

  Future<List<Question>> generateQuestions({
    required String topic,
    required String difficulty,
    required int count,
    String? modelId,
  }) async {
    final prompt =
        '''
You are an expert educator creating multiple-choice quiz questions.

Create $count high-quality multiple-choice questions specifically about: "$topic"
Difficulty level: $difficulty

IMPORTANT REQUIREMENTS:
- Questions must be directly related to "$topic"
- Each question needs exactly 4 answer options (A, B, C, D)
- Only one answer should be correct
- Questions should be educational and accurate
- Avoid generic questions - make them topic-specific

Format each question exactly like this:
Question: [Specific question about $topic]
A) [Answer option 1]
B) [Answer option 2]
C) [Answer option 3]
D) [Answer option 4]
Correct: [A/B/C/D]

Separate each complete question with ---
''';

    try {
      debugPrint(
        'AIService: Attempting AI generation with model: ${modelId ?? 'default'}...',
      );

      // Check if environment variables are loaded
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      debugPrint(
        'AIService: OpenRouter API key loaded: ${apiKey != null && apiKey.isNotEmpty ? 'YES' : 'NO'}',
      );

      // If a specific model is selected, try OpenRouter first
      String? generatedText;
      if (modelId != null && modelId.isNotEmpty) {
        generatedText = await _generateWithOpenRouter(
          topic,
          difficulty,
          count,
          modelId,
        );
      }

      // If OpenRouter failed or no model selected, try multiple free APIs in order of preference

      // Method 1: Try DialoGPT via Hugging Face (free, no auth required)
      if (generatedText == null || generatedText.isEmpty) {
        try {
          debugPrint('AIService: Trying DialoGPT API...');
          final response = await http
              .post(
                Uri.parse(_huggingFaceUrl),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'inputs': {
                    'past_user_inputs': [],
                    'generated_responses': [],
                    'text': prompt,
                  },
                  'parameters': {
                    'max_length': 500,
                    'do_sample': true,
                    'temperature': 0.8,
                    'top_p': 0.9,
                  },
                }),
              )
              .timeout(const Duration(seconds: 20));

          debugPrint('AIService: DialoGPT API status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is List && data.isNotEmpty) {
              generatedText = data[0]['generated_text'] ?? '';
            } else if (data is Map && data.containsKey('generated_text')) {
              generatedText = data['generated_text'];
            }
            debugPrint(
              'AIService: DialoGPT API success - generated ${generatedText?.length ?? 0} chars',
            );
            debugPrint(
              'AIService: Response preview: ${generatedText?.substring(0, generatedText.length > 100 ? 100 : generatedText.length) ?? 'empty'}...',
            );
          } else {
            debugPrint(
              'AIService: DialoGPT API error (${response.statusCode}): ${response.body}',
            );
            if (response.statusCode == 503) {
              debugPrint(
                'AIService: DialoGPT model is loading, try again later',
              );
            }
          }
        } catch (e) {
          debugPrint('AIService: DialoGPT API failed: $e');
        }
      }

      // Method 2: Try GPT-2 as backup
      if (generatedText == null || generatedText.isEmpty) {
        try {
          debugPrint('AIService: Trying GPT-2 API...');
          final response = await http
              .post(
                Uri.parse(_backupUrl),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'inputs': prompt,
                  'parameters': {
                    'max_length': 400,
                    'do_sample': true,
                    'temperature': 0.9,
                  },
                }),
              )
              .timeout(const Duration(seconds: 20));

          debugPrint('AIService: GPT-2 API status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is List && data.isNotEmpty) {
              generatedText = data[0]['generated_text'] ?? '';
              debugPrint(
                'AIService: GPT-2 API success - generated ${generatedText?.length ?? 0} chars',
              );
              debugPrint(
                'AIService: GPT-2 Response preview: ${generatedText?.substring(0, generatedText.length > 100 ? 100 : generatedText.length) ?? 'empty'}...',
              );
            }
          } else {
            debugPrint(
              'AIService: GPT-2 API error (${response.statusCode}): ${response.body}',
            );
            if (response.statusCode == 503) {
              debugPrint('AIService: GPT-2 model is loading, try again later');
            }
          }
        } catch (e) {
          debugPrint('AIService: GPT-2 API failed: $e');
        }
      }

      // If all AI APIs fail, provide helpful fallback
      if (generatedText == null || generatedText.isEmpty) {
        debugPrint(
          'AIService: All AI APIs failed - providing manual creation guidance',
        );

        // Create sample questions as fallback to demonstrate the format
        final sampleQuestions = _createSampleQuestions(
          topic,
          difficulty,
          count,
        );
        debugPrint(
          'AIService: Created ${sampleQuestions.length} sample questions as fallback',
        );

        return sampleQuestions;
      }

      if (generatedText.isEmpty) {
        throw Exception(
          'Unable to generate questions. Please try again or add questions manually.',
        );
      }

      debugPrint('AIService: Generated text length: ${generatedText.length}');

      return _parseQuestions(generatedText, count);
    } catch (e) {
      debugPrint('AIService: Error generating questions: $e');
      throw Exception('Failed to generate questions: $e');
    }
  }

  List<Question> _parseQuestions(String response, int expectedCount) {
    final questions = <Question>[];

    // Split by question separator
    final questionBlocks = response
        .split('---')
        .where((block) => block.trim().isNotEmpty);

    for (final block in questionBlocks) {
      if (questions.length >= expectedCount) break;

      final question = _parseSingleQuestion(block.trim());
      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  Question? _parseSingleQuestion(String block) {
    final lines = block
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);

    String? questionText;
    final options = <String>[];
    String? correctLetter;
    int timeLimit = 30; // Default time limit

    for (final line in lines) {
      if (line.startsWith('Question:')) {
        questionText = line.substring(9).trim();
      } else if (line.startsWith('A)') ||
          line.startsWith('B)') ||
          line.startsWith('C)') ||
          line.startsWith('D)')) {
        final optionText = line.substring(2).trim();
        options.add(optionText);
      } else if (line.startsWith('Correct:')) {
        correctLetter = line.substring(8).trim();
      }
    }

    if (questionText == null || options.length != 4 || correctLetter == null) {
      return null; // Invalid question format
    }

    // Map correct letter to index
    final correctIndex = _letterToIndex(correctLetter);
    if (correctIndex == -1) return null;

    // Create answers
    final answers = <Answer>[];
    for (int i = 0; i < options.length; i++) {
      answers.add(
        Answer(id: _uuid.v4(), text: options[i], isCorrect: i == correctIndex),
      );
    }

    return Question(
      id: _uuid.v4(),
      text: questionText,
      answers: answers,
      correctAnswerId: answers[correctIndex].id,
      timeLimit: timeLimit,
    );
  }

  int _letterToIndex(String letter) {
    switch (letter.toUpperCase()) {
      case 'A':
        return 0;
      case 'B':
        return 1;
      case 'C':
        return 2;
      case 'D':
        return 3;
      default:
        return -1;
    }
  }

  List<Question> _createSampleQuestions(
    String topic,
    String difficulty,
    int count,
  ) {
    // Create sample questions when AI fails
    final questions = <Question>[];

    for (int i = 0; i < count && i < 5; i++) {
      // Limit to 5 sample questions
      final questionNumber = i + 1;
      final correctAnswerId = _uuid.v4();
      final question = Question(
        id: _uuid.v4(),
        text:
            'Sample Question $questionNumber about $topic ($difficulty level). Please edit this question manually.',
        answers: [
          Answer(
            id: correctAnswerId,
            text: 'Sample Answer A (Correct)',
            isCorrect: true,
          ),
          Answer(id: _uuid.v4(), text: 'Sample Answer B', isCorrect: false),
          Answer(id: _uuid.v4(), text: 'Sample Answer C', isCorrect: false),
          Answer(id: _uuid.v4(), text: 'Sample Answer D', isCorrect: false),
        ],
        correctAnswerId: correctAnswerId,
        timeLimit: 30,
      );

      questions.add(question);
    }

    return questions;
  }
}
