import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../models/question.dart';
import '../models/answer.dart';

/// Status of AI generation process
enum GenerationStatus {
  initializing,
  fetchingModels,
  trying,
  retrying,
  switching,
  processing,
  finalizing,
  completed,
  failed,
}

/// Progress information for AI generation
class GenerationProgress {
  final GenerationStatus status;
  final String message;
  final String? currentProvider;
  final String? currentModel;
  final int? attempt;
  final int? maxAttempts;
  final double progress; // 0.0 to 1.0
  final Duration? estimatedTimeRemaining;
  final List<String> logs;
  final List<Question>? questions; // Add questions field

  GenerationProgress({
    required this.status,
    required this.message,
    this.currentProvider,
    this.currentModel,
    this.attempt,
    this.maxAttempts,
    required this.progress,
    this.estimatedTimeRemaining,
    this.logs = const [],
    this.questions, // Add questions parameter
  });

  GenerationProgress copyWith({
    GenerationStatus? status,
    String? message,
    String? currentProvider,
    String? currentModel,
    int? attempt,
    int? maxAttempts,
    double? progress,
    Duration? estimatedTimeRemaining,
    List<String>? logs,
    List<Question>? questions,
  }) {
    return GenerationProgress(
      status: status ?? this.status,
      message: message ?? this.message,
      currentProvider: currentProvider ?? this.currentProvider,
      currentModel: currentModel ?? this.currentModel,
      attempt: attempt ?? this.attempt,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      progress: progress ?? this.progress,
      estimatedTimeRemaining:
          estimatedTimeRemaining ?? this.estimatedTimeRemaining,
      logs: logs ?? this.logs,
      questions: questions ?? this.questions,
    );
  }
}

/// Result of AI generation
class GenerationResult {
  final bool success;
  final List<Question> questions;
  final String? error;
  final String? usedProvider;
  final String? usedModel;
  final Duration totalTime;
  final int totalAttempts;

  GenerationResult({
    required this.success,
    required this.questions,
    this.error,
    this.usedProvider,
    this.usedModel,
    required this.totalTime,
    required this.totalAttempts,
  });
}

/// Enhanced AI Provider with more intelligence
class EnhancedAIProvider {
  final String name;
  final String baseUrl;
  final List<String> models;
  final bool requiresAuth;
  final int priority; // Lower = higher priority
  final Duration timeout;
  final int maxRetries;
  final bool supportsBatch;
  final Map<String, dynamic> headers;

  // Success tracking
  int successCount = 0;
  int totalAttempts = 0;
  DateTime? lastSuccess;
  DateTime? lastFailure;
  List<String> recentErrors = [];

  EnhancedAIProvider({
    required this.name,
    required this.baseUrl,
    required this.models,
    this.requiresAuth = false,
    this.priority = 5,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.supportsBatch = false,
    this.headers = const {},
  });

  double get successRate =>
      totalAttempts > 0 ? successCount / totalAttempts : 0.0;

  bool get isRecentlySuccessful =>
      lastSuccess != null &&
      DateTime.now().difference(lastSuccess!).inMinutes < 30;

  void recordSuccess() {
    successCount++;
    totalAttempts++;
    lastSuccess = DateTime.now();
    recentErrors.clear();
  }

  void recordFailure(String error) {
    totalAttempts++;
    lastFailure = DateTime.now();
    recentErrors.add(error);
    if (recentErrors.length > 5) {
      recentErrors.removeAt(0);
    }
  }
}

/// Robust AI Service with intelligent fallbacks and progress tracking
class RobustAIService {
  final Uuid _uuid = const Uuid();
  final List<EnhancedAIProvider> _providers = [];
  final Map<String, List<Question>> _questionCache = {};

  RobustAIService() {
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    // Prevent duplicate initialization
    if (_providers.isNotEmpty) return;
    
    // Get available models dynamically from OpenRouter
    final availableModels = await _getAvailableModels();

    _providers.addAll([
      // Primary: OpenRouter with all available free models
      EnhancedAIProvider(
        name: 'OpenRouter',
        baseUrl: 'https://openrouter.ai/api/v1/chat/completions',
        models: availableModels.isNotEmpty
            ? availableModels.map((model) => model['id'] as String).toList()
            : [
                'meta-llama/llama-3.2-3b-instruct:free',
                'mistralai/mistral-7b-instruct:free',
              ],
        requiresAuth: true,
        priority: 1,
        timeout: const Duration(seconds: 45),
        maxRetries: 3,
        supportsBatch: true,
      ),

      // Fallback: Smart Template Generator (high-quality templates)
      EnhancedAIProvider(
        name: 'Smart Templates',
        baseUrl: 'local://smart-templates',
        models: ['knowledge-based-generator'],
        requiresAuth: false,
        priority: 2, // Higher priority than old templates
        timeout: const Duration(seconds: 2),
        maxRetries: 1,
        supportsBatch: true,
      ),

      // Final Fallback: Template Generator (always works)
      EnhancedAIProvider(
        name: 'Template Generator',
        baseUrl: 'local://templates',
        models: ['intelligent-templates'],
        requiresAuth: false,
        priority: 10,
        timeout: const Duration(seconds: 5),
        maxRetries: 1,
        supportsBatch: true,
      ),
    ]);

    debugPrint(
      '🤖 RobustAI: Initialized with ${availableModels.length} OpenRouter models and ${_providers.length} total providers',
    );
    
    for (final provider in _providers) {
      debugPrint('🤖 RobustAI: Provider ${provider.name} with priority ${provider.priority}');
    }
  }

  Future<List<Map<String, dynamic>>> _getAvailableModels() async {
    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('🤖 RobustAI: No OpenRouter API key found');
        return [];
      }

      final response = await http
          .get(
            Uri.parse('https://openrouter.ai/api/v1/models'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = data['data'] as List<dynamic>;

        // Filter for free models only
        final freeModels = models
            .where(
              (model) =>
                  model['pricing']?['prompt']?.toString() == '0' ||
                  model['id']?.toString().contains(':free') == true,
            )
            .map(
              (model) => {
                'id': model['id'] as String,
                'name': model['name'] as String? ?? model['id'] as String,
              },
            )
            .toList();

        debugPrint('🤖 RobustAI: Found ${freeModels.length} free models');
        return freeModels;
      } else {
        debugPrint(
          '🤖 RobustAI: Failed to fetch models: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('🤖 RobustAI: Error fetching models: $e');
      return [];
    }
  }

  /// Generate questions with comprehensive progress tracking
  Stream<GenerationProgress> generateQuestionsWithProgress({
    required String topic,
    required String difficulty,
    required int count,
    String? preferredModel,
  }) async* {
    // Initialize providers if not already done
    if (_providers.isEmpty) {
      yield GenerationProgress(
        status: GenerationStatus.initializing,
        message: 'Initializing AI services...',
        progress: 0.0,
      );
      await _initializeProviders();
    }

    yield GenerationProgress(
      status: GenerationStatus.fetchingModels,
      message: 'Preparing to generate questions...',
      progress: 0.1,
    );

    // If user selected a specific model, only use that model
    if (preferredModel != null && preferredModel != 'fallback') {
      yield* _generateWithSpecificModel(
        topic,
        difficulty,
        count,
        preferredModel,
      );
      return;
    }

    // Otherwise, try all available models
    final sortedProviders = _getSortedProviders();

    // Try each provider with intelligent retry logic
    for (
      int providerIndex = 0;
      providerIndex < sortedProviders.length;
      providerIndex++
    ) {
      final provider = sortedProviders[providerIndex];

      yield GenerationProgress(
        status: GenerationStatus.trying,
        message: 'Generating questions with AI...',
        progress: 0.2 + (providerIndex * 0.6 / sortedProviders.length),
      );

      // Try models for this provider
      final modelsToTry = _getOptimalModels(provider, preferredModel);

      for (int modelIndex = 0; modelIndex < modelsToTry.length; modelIndex++) {
        final model = modelsToTry[modelIndex];

        yield GenerationProgress(
          status: GenerationStatus.processing,
          message: 'Generating questions...',
          progress:
              0.3 +
              (providerIndex * 0.5 / sortedProviders.length) +
              (modelIndex * 0.2 / modelsToTry.length),
        );

        try {
          final questions = await _tryGenerateWithProvider(
            provider,
            model,
            topic,
            difficulty,
            count,
          );

          if (questions.isNotEmpty) {
            provider.recordSuccess();

            yield GenerationProgress(
              status: GenerationStatus.finalizing,
              message: 'Finalizing ${questions.length} questions...',
              progress: 0.9,
            );

            // Cache successful results
            _cacheQuestions(topic, difficulty, questions);

            yield GenerationProgress(
              status: GenerationStatus.completed,
              message: 'Successfully generated ${questions.length} questions!',
              progress: 1.0,
              questions: questions,
            );

            return;
          }
        } catch (e) {
          provider.recordFailure(e.toString());
          debugPrint('Failed with ${provider.name}/${model}: $e');
          // Continue to next model
        }
      }
    }

    // All providers failed - create intelligent fallbacks
    yield GenerationProgress(
      status: GenerationStatus.processing,
      message: 'Creating template questions...',
      progress: 0.85,
    );

    final fallbackQuestions = _createIntelligentFallbacks(
      topic,
      difficulty,
      count,
    );

    yield GenerationProgress(
      status: GenerationStatus.completed,
      message: 'Generated ${fallbackQuestions.length} template questions',
      progress: 1.0,
    );
  }

  /// Generate with a specific user-selected model
  Stream<GenerationProgress> _generateWithSpecificModel(
    String topic,
    String difficulty,
    int count,
    String selectedModel,
  ) async* {
    yield GenerationProgress(
      status: GenerationStatus.trying,
      message: 'Generating with your selected model...',
      progress: 0.2,
    );

    // Find the provider that has this model
    final provider = _providers.firstWhere(
      (p) => p.models.contains(selectedModel),
      orElse: () => _providers.first, // Fallback to first provider
    );

    yield GenerationProgress(
      status: GenerationStatus.processing,
      message: 'Generating questions...',
      progress: 0.5,
    );

    try {
      final questions = await _tryGenerateWithProvider(
        provider,
        selectedModel,
        topic,
        difficulty,
        count,
      );

      if (questions.isNotEmpty) {
        provider.recordSuccess();
        _cacheQuestions(topic, difficulty, questions);

        yield GenerationProgress(
          status: GenerationStatus.completed,
          message: 'Successfully generated ${questions.length} questions!',
          progress: 1.0,
        );
        return;
      }
    } catch (e) {
      provider.recordFailure(e.toString());
      debugPrint('Failed with selected model $selectedModel: $e');
    }

    // If selected model fails, create fallbacks
    yield GenerationProgress(
      status: GenerationStatus.processing,
      message: 'Selected model unavailable, creating template questions...',
      progress: 0.8,
    );

    final fallbackQuestions = _createIntelligentFallbacks(
      topic,
      difficulty,
      count,
    );

    yield GenerationProgress(
      status: GenerationStatus.completed,
      message: 'Generated ${fallbackQuestions.length} template questions',
      progress: 1.0,
      questions: fallbackQuestions,
    );
  }

  /// Get the final result after stream completes
  Future<GenerationResult> generateQuestions({
    required String topic,
    required String difficulty,
    required int count,
    String? preferredModel,
  }) async {
    final startTime = DateTime.now();
    List<Question> finalQuestions = [];
    String? usedProvider;
    String? usedModel;
    String? error;
    int totalAttempts = 0;
    bool success = false;

    await for (final progress in generateQuestionsWithProgress(
      topic: topic,
      difficulty: difficulty,
      count: count,
      preferredModel: preferredModel,
    )) {
      if (progress.attempt != null) {
        totalAttempts = progress.attempt!;
      }

      if (progress.status == GenerationStatus.completed) {
        success = true;
        usedProvider = progress.currentProvider;
        usedModel = progress.currentModel;

        // Get the cached questions or fallbacks
        final cacheKey = '${topic}_${difficulty}_$count';
        finalQuestions =
            _questionCache[cacheKey] ??
            _createIntelligentFallbacks(topic, difficulty, count);
        break;
      } else if (progress.status == GenerationStatus.failed) {
        error = progress.message;
        finalQuestions = _createIntelligentFallbacks(topic, difficulty, count);
        break;
      }
    }

    return GenerationResult(
      success: success,
      questions: finalQuestions,
      error: error,
      usedProvider: usedProvider,
      usedModel: usedModel,
      totalTime: DateTime.now().difference(startTime),
      totalAttempts: totalAttempts,
    );
  }

  List<EnhancedAIProvider> _getSortedProviders() {
    final providers = List<EnhancedAIProvider>.from(_providers);

    // Sort by priority, then by success rate, then by recent success
    providers.sort((a, b) {
      // Primary: Priority (lower is better)
      if (a.priority != b.priority) {
        return a.priority.compareTo(b.priority);
      }

      // Secondary: Recent success
      if (a.isRecentlySuccessful != b.isRecentlySuccessful) {
        return a.isRecentlySuccessful ? -1 : 1;
      }

      // Tertiary: Success rate
      return b.successRate.compareTo(a.successRate);
    });

    return providers;
  }

  List<String> _getOptimalModels(
    EnhancedAIProvider provider,
    String? preferredModel,
  ) {
    final models = List<String>.from(provider.models);

    // Put preferred model first if it exists in this provider
    if (preferredModel != null && models.contains(preferredModel)) {
      models.remove(preferredModel);
      models.insert(0, preferredModel);
    }

    // Shuffle remaining models to distribute load
    if (models.length > 1) {
      final random = Random();
      final remaining = models.sublist(1);
      remaining.shuffle(random);
      models.replaceRange(1, models.length, remaining);
    }

    return models;
  }

  Future<List<Question>> _tryGenerateWithProvider(
    EnhancedAIProvider provider,
    String model,
    String topic,
    String difficulty,
    int count,
  ) async {
    debugPrint('🤖 RobustAI: Trying provider ${provider.name} with model $model');
    
    switch (provider.name) {
      case 'OpenRouter':
      case 'OpenRouter Premium':
        return await _tryOpenRouter(provider, model, topic, difficulty, count);
      case 'Smart Templates':
        return _createSmartTemplates(topic, difficulty, count);
      case 'Template Generator':
        return _createIntelligentFallbacks(topic, difficulty, count);
      default:
        throw Exception('Unknown provider: ${provider.name}');
    }
  }

  Future<List<Question>> _tryOpenRouter(
    EnhancedAIProvider provider,
    String model,
    String topic,
    String difficulty,
    int count,
  ) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('🤖 RobustAI: OpenRouter API key not configured');
      throw Exception('OpenRouter API key not configured');
    }
    
    debugPrint('🤖 RobustAI: Making OpenRouter API call with model $model');

    final prompt = _buildEnhancedPrompt(topic, difficulty, count);

    final response = await http
        .post(
          Uri.parse(provider.baseUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://github.com/your-repo',
            'X-Title': 'QuizArena AI Generation',
          },
          body: json.encode({
            'model': model,
            'messages': [
              {
                'role': 'system',
                'content': 'You are an expert quiz question generator.',
              },
              {'role': 'user', 'content': prompt},
            ],
            'max_tokens': 2000,
            'temperature': 0.7,
            'stream': false,
          }),
        )
        .timeout(provider.timeout);

    debugPrint('🤖 RobustAI: OpenRouter response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final content = data['choices']?[0]?['message']?['content'] as String?;

      if (content != null) {
        debugPrint('🤖 RobustAI: OpenRouter returned content, parsing questions...');
        return _parseQuestionsFromResponse(content);
      }
    } else {
      debugPrint('🤖 RobustAI: OpenRouter API failed with status ${response.statusCode}: ${response.body}');
    }

    throw Exception(
      'OpenRouter API error: ${response.statusCode} - ${response.body}',
    );
  }



  String _buildEnhancedPrompt(String topic, String difficulty, int count) {
    return '''Create $count multiple-choice quiz questions about "$topic" with $difficulty difficulty level.

STRICT FORMAT REQUIREMENTS:
- Return ONLY valid JSON array
- Each question must have exactly 4 answer choices
- Mark correct answer with "isCorrect": true
- All other answers must have "isCorrect": false
- Place the correct answer in ANY position (not always first)
- Use this exact structure:

[
  {
    "question": "Your question here?",
    "answers": [
      {"text": "Answer option 1", "isCorrect": false},
      {"text": "Correct answer", "isCorrect": true},
      {"text": "Answer option 3", "isCorrect": false},
      {"text": "Answer option 4", "isCorrect": false}
    ]
  }
]

Requirements:
- Questions should be clear and unambiguous
- Avoid trick questions or overly obscure facts
- Wrong answers should be plausible but clearly incorrect
- Vary question types: facts, concepts, applications
- No duplicate questions or answers
- RANDOMIZE the position of correct answers across questions
- Difficulty: $difficulty means ${_getDifficultyDescription(difficulty)}

Topic: $topic
Generate exactly $count questions now:''';
  }



  String _getDifficultyDescription(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'basic facts and simple concepts';
      case 'medium':
        return 'moderate understanding and application';
      case 'hard':
        return 'advanced concepts and critical thinking';
      default:
        return 'appropriate level of challenge';
    }
  }

  List<Question> _parseQuestionsFromResponse(String content) {
    final questions = <Question>[];

    try {
      // Try to parse as JSON first
      if (content.trim().startsWith('[') || content.trim().startsWith('{')) {
        final jsonData = json.decode(content);
        final questionsData = jsonData is List ? jsonData : [jsonData];

        for (final questionData in questionsData) {
          final question = _parseJsonQuestion(questionData);
          if (question != null) questions.add(question);
        }
      } else {
        // Parse text format
        questions.addAll(_parseTextQuestions(content));
      }
    } catch (e) {
      debugPrint('Parse error: $e');
      // Try text parsing as fallback
      questions.addAll(_parseTextQuestions(content));
    }

    return questions;
  }

  Question? _parseJsonQuestion(Map<String, dynamic> data) {
    try {
      final questionText = data['question'] as String?;
      final answersData = data['answers'] as List<dynamic>?;

      if (questionText == null ||
          answersData == null ||
          answersData.length != 4) {
        return null;
      }

      final answers = <Answer>[];
      String? correctAnswerId;

      for (final answerData in answersData) {
        final answerId = _uuid.v4();
        final answerText = answerData['text'] as String;
        final isCorrect = answerData['isCorrect'] as bool? ?? false;

        answers.add(
          Answer(id: answerId, text: answerText, isCorrect: isCorrect),
        );

        if (isCorrect) correctAnswerId = answerId;
      }

      // Shuffle answers to randomize correct answer position
      answers.shuffle(Random());

      return Question(
        id: _uuid.v4(),
        text: questionText,
        answers: answers,
        correctAnswerId: correctAnswerId ?? answers.first.id,
        timeLimit: _getDifficultyTimeLimit('medium'),
      );
    } catch (e) {
      return null;
    }
  }

  List<Question> _parseTextQuestions(String content) {
    final questions = <Question>[];
    final lines = content
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('Q:') || line.contains('?')) {
        final questionText = line.replaceFirst(RegExp(r'^Q:\s*'), '').trim();
        final answers = <Answer>[];
        String? correctAnswerId;

        // Look for answers in next few lines
        for (int j = i + 1; j < lines.length && j < i + 5; j++) {
          final answerLine = lines[j].trim();
          if (answerLine.isEmpty) break;

          final match = RegExp(
            r'^[A-D]\)\s*(.+?)(\s*✓)?$',
          ).firstMatch(answerLine);
          if (match != null) {
            final answerId = _uuid.v4();
            final answerText = match.group(1)!.trim();
            final isCorrect = match.group(2) != null;

            answers.add(
              Answer(id: answerId, text: answerText, isCorrect: isCorrect),
            );

            if (isCorrect) correctAnswerId = answerId;
          }
        }

        if (answers.length >= 3) {
          // Ensure we have exactly 4 answers
          while (answers.length < 4) {
            answers.add(
              Answer(
                id: _uuid.v4(),
                text: 'None of the above',
                isCorrect: false,
              ),
            );
          }

          // Shuffle answers to randomize correct answer position
          answers.shuffle(Random());

          questions.add(
            Question(
              id: _uuid.v4(),
              text: questionText.endsWith('?')
                  ? questionText
                  : '$questionText?',
              answers: answers.take(4).toList(),
              correctAnswerId: correctAnswerId ?? answers.first.id,
              timeLimit: _getDifficultyTimeLimit('medium'),
            ),
          );
        }
      }
    }

    return questions;
  }

  void _cacheQuestions(
    String topic,
    String difficulty,
    List<Question> questions,
  ) {
    final key = '${topic}_${difficulty}_${questions.length}';
    _questionCache[key] = questions;
  }

  List<Question> _createIntelligentFallbacks(
    String topic,
    String difficulty,
    int count,
  ) {
    // This would be a comprehensive fallback system
    // For now, creating basic template questions
    final questions = <Question>[];
    final templates = _getTopicTemplates(topic);

    for (int i = 0; i < count && i < templates.length; i++) {
      final template = templates[i];
      final correctAnswerId = _uuid.v4();

      final answers = [
        Answer(
          id: correctAnswerId,
          text: template['correct']!,
          isCorrect: true,
        ),
        Answer(id: _uuid.v4(), text: template['wrong1']!, isCorrect: false),
        Answer(id: _uuid.v4(), text: template['wrong2']!, isCorrect: false),
        Answer(id: _uuid.v4(), text: template['wrong3']!, isCorrect: false),
      ];

      // Shuffle answers to randomize correct answer position
      answers.shuffle(Random());

      questions.add(
        Question(
          id: _uuid.v4(),
          text: template['question']!.replaceAll('[TOPIC]', topic),
          answers: answers,
          correctAnswerId: correctAnswerId,
          timeLimit: _getDifficultyTimeLimit(difficulty),
        ),
      );
    }

    return questions;
  }

  List<Map<String, String>> _getTopicTemplates(String topic) {
    // Intelligent template selection based on topic
    return [
      {
        'question': 'What is a fundamental concept in [TOPIC]?',
        'correct': 'A core principle or basic element',
        'wrong1': 'An advanced technique',
        'wrong2': 'A complex theory',
        'wrong3': 'A specialized tool',
      },
      {
        'question': 'Which of the following is most associated with [TOPIC]?',
        'correct': 'Primary characteristic',
        'wrong1': 'Unrelated concept',
        'wrong2': 'Different field entirely',
        'wrong3': 'Opposite principle',
      },
      // Add more intelligent templates...
    ];
  }

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

  /// Generate high-quality questions using smart templates and knowledge bases
  List<Question> _createSmartTemplates(
    String topic,
    String difficulty,
    int count,
  ) {
    debugPrint('🤖 RobustAI: Creating smart template questions for topic: $topic');
    
    final questions = <Question>[];
    final topicLower = topic.toLowerCase();
    
    // Enhanced question bank based on topic keywords
    if (topicLower.contains('science') || topicLower.contains('physics') || topicLower.contains('chemistry') || topicLower.contains('biology')) {
      questions.addAll(_createScienceQuestions(difficulty, count));
    } else if (topicLower.contains('history') || topicLower.contains('historical')) {
      questions.addAll(_createHistoryQuestions(difficulty, count));
    } else if (topicLower.contains('geography') || topicLower.contains('world') || topicLower.contains('countries')) {
      questions.addAll(_createGeographyQuestions(difficulty, count));
    } else if (topicLower.contains('math') || topicLower.contains('mathematics') || topicLower.contains('calculation')) {
      questions.addAll(_createMathQuestions(difficulty, count));
    } else if (topicLower.contains('technology') || topicLower.contains('computer') || topicLower.contains('programming')) {
      questions.addAll(_createTechnologyQuestions(difficulty, count));
    } else if (topicLower.contains('sports') || topicLower.contains('games') || topicLower.contains('athletics')) {
      questions.addAll(_createSportsQuestions(difficulty, count));
    } else if (topicLower.contains('literature') || topicLower.contains('books') || topicLower.contains('writing')) {
      questions.addAll(_createLiteratureQuestions(difficulty, count));
    } else if (topicLower.contains('art') || topicLower.contains('painting') || topicLower.contains('artist')) {
      questions.addAll(_createArtQuestions(difficulty, count));
    } else {
      // Create general questions for any topic
      questions.addAll(_createEnhancedGeneralQuestions(topic, difficulty, count));
    }
    
    // Ensure we have enough questions
    while (questions.length < count) {
      questions.addAll(_createEnhancedGeneralQuestions(topic, difficulty, 1));
    }
    
    // Shuffle and limit to requested count
    questions.shuffle(Random());
    return questions.take(count).toList();
  }

  /// Helper method to create a question with proper structure
  Question _createQuestion(String questionText, List<String> options, String correctAnswer, String difficulty) {
    final answers = <Answer>[];
    String correctAnswerId = '';
    
    // Create shuffled answers
    final shuffledOptions = List<String>.from(options);
    shuffledOptions.shuffle(Random());
    
    for (final option in shuffledOptions) {
      final answerId = _uuid.v4();
      final isCorrect = option == correctAnswer;
      if (isCorrect) correctAnswerId = answerId;
      
      answers.add(Answer(
        id: answerId,
        text: option,
        isCorrect: isCorrect,
      ));
    }
    
    return Question(
      id: _uuid.v4(),
      text: questionText,
      answers: answers,
      correctAnswerId: correctAnswerId,
      timeLimit: _getDifficultyTimeLimit(difficulty),
    );
  }

  /// Create science-specific questions
  List<Question> _createScienceQuestions(String difficulty, int count) {
    final scienceQuestions = [
      _createQuestion(
        'What is the speed of light in a vacuum?',
        ['299,792,458 m/s', '300,000,000 m/s', '186,000 mph', '150,000,000 m/s'],
        '299,792,458 m/s',
        difficulty,
      ),
      _createQuestion(
        'Which element has the chemical symbol "Au"?',
        ['Silver', 'Gold', 'Aluminum', 'Argon'],
        'Gold',
        difficulty,
      ),
      _createQuestion(
        'What is the powerhouse of the cell?',
        ['Nucleus', 'Mitochondria', 'Ribosome', 'Endoplasmic Reticulum'],
        'Mitochondria',
        difficulty,
      ),
      _createQuestion(
        'How many chambers does a human heart have?',
        ['2', '3', '4', '5'],
        '4',
        difficulty,
      ),
      _createQuestion(
        'What is the smallest unit of matter?',
        ['Atom', 'Molecule', 'Proton', 'Electron'],
        'Atom',
        difficulty,
      ),
    ];
    
    scienceQuestions.shuffle(Random());
    return scienceQuestions.take(count).toList();
  }

  /// Create history-specific questions  
  List<Question> _createHistoryQuestions(String difficulty, int count) {
    final historyQuestions = [
      _createQuestion('In which year did World War II end?', ['1944', '1945', '1946', '1947'], '1945', difficulty),
      _createQuestion('Who was the first President of the United States?', ['Thomas Jefferson', 'John Adams', 'George Washington', 'Benjamin Franklin'], 'George Washington', difficulty),
      _createQuestion('Which ancient wonder was located in Alexandria?', ['Hanging Gardens', 'Lighthouse of Alexandria', 'Colossus of Rhodes', 'Temple of Artemis'], 'Lighthouse of Alexandria', difficulty),
    ];
    historyQuestions.shuffle(Random());
    return historyQuestions.take(count).toList();
  }

  /// Create geography-specific questions
  List<Question> _createGeographyQuestions(String difficulty, int count) {
    final geographyQuestions = [
      _createQuestion('What is the capital of Australia?', ['Sydney', 'Melbourne', 'Canberra', 'Perth'], 'Canberra', difficulty),
      _createQuestion('Which is the longest river in the world?', ['Amazon River', 'Nile River', 'Yangtze River', 'Mississippi River'], 'Nile River', difficulty),
      _createQuestion('Mount Everest is located in which mountain range?', ['Alps', 'Andes', 'Himalayas', 'Rocky Mountains'], 'Himalayas', difficulty),
    ];
    geographyQuestions.shuffle(Random());
    return geographyQuestions.take(count).toList();
  }

  /// Create math-specific questions
  List<Question> _createMathQuestions(String difficulty, int count) {
    final mathQuestions = [
      _createQuestion('What is the value of π (pi) to two decimal places?', ['3.14', '3.15', '3.13', '3.16'], '3.14', difficulty),
      _createQuestion('What is 15% of 200?', ['25', '30', '35', '40'], '30', difficulty),
      _createQuestion('What is the square root of 144?', ['11', '12', '13', '14'], '12', difficulty),
    ];
    mathQuestions.shuffle(Random());
    return mathQuestions.take(count).toList();
  }

  /// Create literature-specific questions
  List<Question> _createLiteratureQuestions(String difficulty, int count) {
    final literatureQuestions = [
      _createQuestion('Who wrote "Romeo and Juliet"?', ['Charles Dickens', 'William Shakespeare', 'Jane Austen', 'Mark Twain'], 'William Shakespeare', difficulty),
      _createQuestion('Which novel begins with "It was the best of times..."?', ['Great Expectations', 'A Tale of Two Cities', 'Oliver Twist', 'David Copperfield'], 'A Tale of Two Cities', difficulty),
    ];
    literatureQuestions.shuffle(Random());
    return literatureQuestions.take(count).toList();
  }

  /// Create technology-specific questions
  List<Question> _createTechnologyQuestions(String difficulty, int count) {
    final techQuestions = [
      _createQuestion('What does "HTML" stand for?', ['Hypertext Markup Language', 'High-Tech Modern Language', 'Home Tool Markup Language', 'Hypertext Machine Language'], 'Hypertext Markup Language', difficulty),
      _createQuestion('Who founded Microsoft?', ['Steve Jobs', 'Bill Gates', 'Mark Zuckerberg', 'Larry Page'], 'Bill Gates', difficulty),
    ];
    techQuestions.shuffle(Random());
    return techQuestions.take(count).toList();
  }

  /// Create sports-specific questions
  List<Question> _createSportsQuestions(String difficulty, int count) {
    final sportsQuestions = [
      _createQuestion('How many players are on a basketball team on the court at one time?', ['4', '5', '6', '7'], '5', difficulty),
      _createQuestion('In which sport would you perform a slam dunk?', ['Tennis', 'Basketball', 'Volleyball', 'Soccer'], 'Basketball', difficulty),
    ];
    sportsQuestions.shuffle(Random());
    return sportsQuestions.take(count).toList();
  }

  /// Create art-specific questions
  List<Question> _createArtQuestions(String difficulty, int count) {
    final artQuestions = [
      _createQuestion('Who painted the Mona Lisa?', ['Vincent van Gogh', 'Pablo Picasso', 'Leonardo da Vinci', 'Claude Monet'], 'Leonardo da Vinci', difficulty),
      _createQuestion('Which art movement was Pablo Picasso associated with?', ['Impressionism', 'Cubism', 'Surrealism', 'Pop Art'], 'Cubism', difficulty),
    ];
    artQuestions.shuffle(Random());
    return artQuestions.take(count).toList();
  }

  /// Create enhanced general questions for any topic
  List<Question> _createEnhancedGeneralQuestions(String topic, String difficulty, int count) {
    final generalQuestions = [
      _createQuestion('What is a key concept related to $topic?', ['Primary principle', 'Secondary aspect', 'Unrelated concept', 'Opposite idea'], 'Primary principle', difficulty),
      _createQuestion('Which is most important when studying $topic?', ['Understanding fundamentals', 'Memorizing details', 'Ignoring basics', 'Avoiding practice'], 'Understanding fundamentals', difficulty),
      _createQuestion('What approach works best for learning $topic?', ['Practice and study', 'Guessing answers', 'Avoiding questions', 'Memorizing randomly'], 'Practice and study', difficulty),
    ];
    generalQuestions.shuffle(Random());
    return generalQuestions.take(count).toList();
  }
}
