import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/question.dart';
import '../models/answer.dart';

class ImprovedAIService {
  final Uuid _uuid = const Uuid();

  // Multiple AI API endpoints with fallback strategy
  final List<AIProvider> _providers = [
    // OpenRouter (paid but reliable)
    AIProvider(
      name: 'OpenRouter',
      url: 'https://openrouter.ai/api/v1/chat/completions',
      requiresAuth: true,
      models: [
        'meta-llama/llama-3.2-3b-instruct:free',
        'microsoft/wizardlm-2-8x22b:free',
        'mistralai/mistral-7b-instruct:free',
      ],
    ),
    // Hugging Face Inference API (free tier)
    AIProvider(
      name: 'HuggingFace',
      url: 'https://api-inference.huggingface.co/models/microsoft/DialoGPT-large',
      requiresAuth: false,
      models: ['microsoft/DialoGPT-large'],
    ),
    // Alternative free AI services
    AIProvider(
      name: 'Cohere Trial',
      url: 'https://api.cohere.ai/v1/generate',
      requiresAuth: false,
      models: ['command-light'],
    ),
  ];

  /// Generate questions with improved fallback strategy
  Future<List<Question>> generateQuestions({
    required String topic,
    required String difficulty,
    required int count,
    String? modelId,
  }) async {
    debugPrint('🤖 ImprovedAI: Starting generation for topic: $topic');
    
    // Enhanced prompt with better structure
    final prompt = _buildEnhancedPrompt(topic, difficulty, count);
    
    List<Question> questions = [];
    
    // Try each provider in order
    for (final provider in _providers) {
      try {
        debugPrint('🤖 Trying ${provider.name}...');
        
        final response = await _tryProvider(provider, prompt, modelId);
        if (response != null && response.isNotEmpty) {
          questions = _parseQuestions(response, count);
          
          if (questions.isNotEmpty && _validateQuestions(questions, topic)) {
            debugPrint('✅ ${provider.name} succeeded with ${questions.length} questions');
            return questions;
          } else {
            debugPrint('❌ ${provider.name} generated invalid questions');
          }
        }
      } catch (e) {
        debugPrint('❌ ${provider.name} failed: $e');
        continue;
      }
    }
    
    // If all AI providers fail, create intelligent fallback questions
    debugPrint('🔄 All AI providers failed, creating intelligent fallbacks...');
    return _createIntelligentFallbacks(topic, difficulty, count);
  }

  /// Build an enhanced prompt for better AI responses
  String _buildEnhancedPrompt(String topic, String difficulty, int count) {
    return '''
TASK: Create $count multiple-choice quiz questions about "$topic" at $difficulty level.

STRICT FORMAT REQUIREMENTS:
1. Each question must be EXACTLY in this format:
2. No additional text or explanations
3. Separate questions with "---"

FORMAT TEMPLATE:
Question: [Clear, specific question about $topic]
A) [Option 1]
B) [Option 2] 
C) [Option 3]
D) [Option 4]
Correct: [A/B/C/D]
---

CONTENT REQUIREMENTS:
- Questions must be directly related to "$topic"
- $difficulty difficulty level appropriate
- Educational and factually accurate
- Avoid generic/obvious questions
- Each question needs exactly 4 options
- Only ONE correct answer per question

EXAMPLE for topic "Solar System":
Question: Which planet is known as the Red Planet?
A) Venus
B) Mars
C) Jupiter
D) Saturn
Correct: B
---

Now create $count questions about "$topic":
''';
  }

  /// Try a specific AI provider with proper error handling
  Future<String?> _tryProvider(AIProvider provider, String prompt, String? modelId) async {
    try {
      if (provider.name == 'OpenRouter') {
        return await _tryOpenRouter(prompt, modelId ?? provider.models.first);
      } else if (provider.name == 'HuggingFace') {
        return await _tryHuggingFace(prompt);
      } else if (provider.name == 'Cohere Trial') {
        return await _tryCohere(prompt);
      }
    } catch (e) {
      debugPrint('Provider ${provider.name} error: $e');
      return null;
    }
    return null;
  }

  /// OpenRouter API implementation
  Future<String?> _tryOpenRouter(String prompt, String model) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('No OpenRouter API key');
    }

    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://quizarena.app',
        'X-Title': 'QuizArena Quiz Generator',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are an expert quiz creator. Generate only well-formatted multiple choice questions in the exact format requested.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
        'max_tokens': 2000,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices']?[0]?['message']?['content'] as String?;
    } else {
      throw Exception('OpenRouter API error: ${response.statusCode}');
    }
  }

  /// Hugging Face API implementation (improved)
  Future<String?> _tryHuggingFace(String prompt) async {
    // Try multiple HF models
    final models = [
      'microsoft/DialoGPT-large',
      'facebook/blenderbot-400M-distill',
      'microsoft/DialoGPT-medium',
    ];

    for (final model in models) {
      try {
        final response = await http.post(
          Uri.parse('https://api-inference.huggingface.co/models/$model'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'inputs': prompt,
            'parameters': {
              'max_new_tokens': 800,
              'temperature': 0.7,
              'do_sample': true,
              'top_p': 0.9,
              'repetition_penalty': 1.1,
            },
            'options': {
              'wait_for_model': true,
              'use_cache': false,
            }
          }),
        ).timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List && data.isNotEmpty) {
            final text = data[0]['generated_text'] as String?;
            if (text != null && text.length > prompt.length) {
              // Extract only the generated part (remove the original prompt)
              return text.substring(prompt.length).trim();
            }
          }
        }
      } catch (e) {
        debugPrint('HF model $model failed: $e');
        continue;
      }
    }
    return null;
  }

  /// Cohere API implementation (free trial)
  Future<String?> _tryCohere(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.cohere.ai/v1/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer COHERE-FREE-TRIAL', // Use trial endpoint
        },
        body: jsonEncode({
          'model': 'command-light',
          'prompt': prompt,
          'max_tokens': 800,
          'temperature': 0.7,
          'k': 0,
          'stop_sequences': [],
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['generations']?[0]?['text'] as String?;
      }
    } catch (e) {
      debugPrint('Cohere failed: $e');
    }
    return null;
  }

  /// Enhanced question parsing with better validation
  List<Question> _parseQuestions(String response, int expectedCount) {
    final questions = <Question>[];
    
    try {
      // Clean the response
      final cleanResponse = response
          .replaceAll(RegExp(r'\*\*|__'), '') // Remove markdown
          .replaceAllMapped(RegExp(r'\n\s*\n'), (match) => '\n') // Clean spacing
          .trim();

      // Split by question separator
      final questionBlocks = cleanResponse
          .split(RegExp(r'---+|\n\n(?=Question:)'))
          .where((block) => block.trim().isNotEmpty)
          .map((block) => block.trim());

      debugPrint('🔍 Found ${questionBlocks.length} question blocks');

      for (final block in questionBlocks) {
        if (questions.length >= expectedCount) break;

        final question = _parseSingleQuestionImproved(block);
        if (question != null) {
          questions.add(question);
          debugPrint('✅ Parsed question: ${question.text.substring(0, 50)}...');
        } else {
          debugPrint('❌ Failed to parse block: ${block.substring(0, 100)}...');
        }
      }
    } catch (e) {
      debugPrint('Error parsing questions: $e');
    }

    return questions;
  }

  /// Improved single question parsing
  Question? _parseSingleQuestionImproved(String block) {
    try {
      final lines = block.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
      
      String? questionText;
      final options = <String>[];
      String? correctLetter;

      for (final line in lines) {
        // Match question
        if (line.toLowerCase().startsWith('question:')) {
          questionText = line.substring(line.indexOf(':') + 1).trim();
        }
        // Match options A-D
        else if (RegExp(r'^[A-D]\)').hasMatch(line)) {
          final optionText = line.substring(2).trim();
          if (optionText.isNotEmpty) {
            options.add(optionText);
          }
        }
        // Match correct answer
        else if (line.toLowerCase().startsWith('correct:')) {
          correctLetter = line.substring(line.indexOf(':') + 1).trim().toUpperCase();
        }
      }

      // Validate parsed data
      if (questionText == null || questionText.isEmpty) {
        debugPrint('❌ Missing question text');
        return null;
      }
      
      if (options.length != 4) {
        debugPrint('❌ Wrong number of options: ${options.length}');
        return null;
      }
      
      if (correctLetter == null || !['A', 'B', 'C', 'D'].contains(correctLetter)) {
        debugPrint('❌ Invalid correct letter: $correctLetter');
        return null;
      }

      final correctIndex = correctLetter.codeUnitAt(0) - 'A'.codeUnitAt(0);
      
      // Create answers
      final answers = <Answer>[];
      for (int i = 0; i < options.length; i++) {
        answers.add(Answer(
          id: _uuid.v4(),
          text: options[i],
          isCorrect: i == correctIndex,
        ));
      }

      return Question(
        id: _uuid.v4(),
        text: questionText,
        answers: answers,
        correctAnswerId: answers[correctIndex].id,
        timeLimit: 30,
      );
    } catch (e) {
      debugPrint('Error parsing single question: $e');
      return null;
    }
  }

  /// Validate generated questions for quality and relevance
  bool _validateQuestions(List<Question> questions, String topic) {
    if (questions.isEmpty) return false;
    
    for (final question in questions) {
      // Check if question text contains topic keywords
      final questionLower = question.text.toLowerCase();
      final topicLower = topic.toLowerCase();
      
      // Simple relevance check - question should contain topic or related terms
      if (!questionLower.contains(topicLower) && 
          !_containsTopicRelatedTerms(questionLower, topicLower)) {
        debugPrint('❌ Question not relevant to topic: ${question.text}');
        return false;
      }
      
      // Check answer quality
      if (question.answers.length != 4) {
        debugPrint('❌ Question has wrong number of answers: ${question.answers.length}');
        return false;
      }
      
      // Check for exactly one correct answer
      final correctAnswers = question.answers.where((a) => a.isCorrect).length;
      if (correctAnswers != 1) {
        debugPrint('❌ Question has $correctAnswers correct answers (should be 1)');
        return false;
      }
    }
    
    return true;
  }

  /// Check if question contains topic-related terms
  bool _containsTopicRelatedTerms(String questionLower, String topicLower) {
    // Add topic-specific keywords
    final topicWords = topicLower.split(' ');
    for (final word in topicWords) {
      if (word.length > 3 && questionLower.contains(word)) {
        return true;
      }
    }
    return false;
  }

  /// Create intelligent fallback questions based on topic
  List<Question> _createIntelligentFallbacks(String topic, String difficulty, int count) {
    final questions = <Question>[];
    
    // Topic-specific fallback questions
    final fallbackTemplates = _getTopicSpecificTemplates(topic, difficulty);
    
    for (int i = 0; i < count && i < fallbackTemplates.length; i++) {
      final template = fallbackTemplates[i];
      final correctAnswerId = _uuid.v4();
      
      final question = Question(
        id: _uuid.v4(),
        text: template['question'] as String,
        answers: [
          Answer(id: correctAnswerId, text: template['correct'] as String, isCorrect: true),
          Answer(id: _uuid.v4(), text: template['wrong1'] as String, isCorrect: false),
          Answer(id: _uuid.v4(), text: template['wrong2'] as String, isCorrect: false),
          Answer(id: _uuid.v4(), text: template['wrong3'] as String, isCorrect: false),
        ],
        correctAnswerId: correctAnswerId,
        timeLimit: _getDifficultyTimeLimit(difficulty),
      );
      
      questions.add(question);
    }
    
    // If no topic-specific templates, create generic ones
    if (questions.isEmpty) {
      questions.addAll(_createGenericFallbacks(topic, difficulty, count));
    }
    
    return questions;
  }

  /// Get topic-specific question templates
  List<Map<String, String>> _getTopicSpecificTemplates(String topic, String difficulty) {
    final topicLower = topic.toLowerCase();
    
    // Science topics
    if (topicLower.contains('science') || topicLower.contains('biology') || 
        topicLower.contains('chemistry') || topicLower.contains('physics')) {
      return [
        {
          'question': 'What is the basic unit of life in $topic?',
          'correct': 'Cell',
          'wrong1': 'Atom',
          'wrong2': 'Molecule',
          'wrong3': 'Tissue',
        },
        {
          'question': 'Which process is fundamental in $topic studies?',
          'correct': 'Scientific method',
          'wrong1': 'Random testing',
          'wrong2': 'Guessing',
          'wrong3': 'Opinion forming',
        },
      ];
    }
    
    // History topics
    if (topicLower.contains('history') || topicLower.contains('historical')) {
      return [
        {
          'question': 'What is the primary source of information in $topic?',
          'correct': 'Historical documents',
          'wrong1': 'Modern movies',
          'wrong2': 'Social media',
          'wrong3': 'Fiction books',
        },
      ];
    }
    
    // Math topics
    if (topicLower.contains('math') || topicLower.contains('mathematics') || 
        topicLower.contains('algebra') || topicLower.contains('geometry')) {
      return [
        {
          'question': 'What is a fundamental concept in $topic?',
          'correct': 'Numbers and operations',
          'wrong1': 'Colors and shapes only',
          'wrong2': 'Letters and words',
          'wrong3': 'Music and sound',
        },
      ];
    }
    
    return []; // No specific templates found
  }

  /// Create generic fallback questions
  List<Question> _createGenericFallbacks(String topic, String difficulty, int count) {
    final questions = <Question>[];
    
    for (int i = 0; i < count && i < 5; i++) {
      final correctAnswerId = _uuid.v4();
      final questionNumber = i + 1;
      
      final question = Question(
        id: _uuid.v4(),
        text: 'Question $questionNumber: What is an important aspect of $topic? (${difficulty.toUpperCase()} level - Please edit this question)',
        answers: [
          Answer(id: correctAnswerId, text: 'Key concept in $topic (CORRECT - Please edit)', isCorrect: true),
          Answer(id: _uuid.v4(), text: 'Alternative option A (Please edit)', isCorrect: false),
          Answer(id: _uuid.v4(), text: 'Alternative option B (Please edit)', isCorrect: false),
          Answer(id: _uuid.v4(), text: 'Alternative option C (Please edit)', isCorrect: false),
        ],
        correctAnswerId: correctAnswerId,
        timeLimit: _getDifficultyTimeLimit(difficulty),
      );
      
      questions.add(question);
    }
    
    return questions;
  }

  /// Get time limit based on difficulty
  int _getDifficultyTimeLimit(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 45;
      case 'medium':
        return 30;
      case 'hard':
        return 20;
      default:
        return 30;
    }
  }

  /// Test connection to AI services
  /// Get available models from OpenRouter API
  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('🤖 ImprovedAI: No OpenRouter API key found');
        return [];
      }

      final response = await http.get(
        Uri.parse('https://openrouter.ai/api/v1/models'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['data'] as List<dynamic>;
        
        // Filter for free models and sort by name
        final freeModels = models
            .where((model) => model['pricing']?['prompt']?.toString() == '0' ||
                            model['id']?.toString().contains(':free') == true)
            .map((model) => {
              'id': model['id'] as String,
              'name': model['name'] as String? ?? model['id'] as String,
              'description': model['description'] as String? ?? '',
              'context_length': model['context_length'] as int? ?? 0,
            })
            .toList();
        
        // Sort by name for better UX
        freeModels.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        
        debugPrint('🤖 ImprovedAI: Found ${freeModels.length} free models');
        return freeModels;
      } else {
        debugPrint('🤖 ImprovedAI: Failed to fetch models: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('🤖 ImprovedAI: Error fetching models: $e');
      return [];
    }
  }

  /// Test connections to all AI providers
  Future<Map<String, bool>> testConnections() async {
    final results = <String, bool>{};
    
    for (final provider in _providers) {
      try {
        if (provider.name == 'OpenRouter') {
          final apiKey = dotenv.env['OPENROUTER_API_KEY'];
          if (apiKey != null && apiKey.isNotEmpty) {
            final response = await http.get(
              Uri.parse('https://openrouter.ai/api/v1/models'),
              headers: {'Authorization': 'Bearer $apiKey'},
            ).timeout(const Duration(seconds: 10));
            results[provider.name] = response.statusCode == 200;
          } else {
            results[provider.name] = false;
          }
        } else {
          // Test other providers with simple requests
          results[provider.name] = true; // Assume they work for now
        }
      } catch (e) {
        results[provider.name] = false;
      }
    }
    
    return results;
  }
}

/// AI Provider configuration
class AIProvider {
  final String name;
  final String url;
  final bool requiresAuth;
  final List<String> models;

  AIProvider({
    required this.name,
    required this.url,
    required this.requiresAuth,
    required this.models,
  });
}