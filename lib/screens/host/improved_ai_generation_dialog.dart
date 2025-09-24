import 'package:flutter/material.dart';
import '../../services/improved_ai_service.dart';

/// Improved AI Generation Dialog with better UX and error handling
class ImprovedAIGenerationDialog extends StatefulWidget {
  final Function(String topic, String difficulty, int count, {String? modelId})
  onGenerate;

  const ImprovedAIGenerationDialog({super.key, required this.onGenerate});

  @override
  State<ImprovedAIGenerationDialog> createState() =>
      _ImprovedAIGenerationDialogState();
}

class _ImprovedAIGenerationDialogState
    extends State<ImprovedAIGenerationDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _topicController;
  String _difficulty = 'medium';
  late TextEditingController _countController;
  String? _selectedModelId;

  bool _isLoadingConnections = true;
  Map<String, bool> _connectionStatus = {};
  List<Map<String, dynamic>> _availableModels = [];

  // Predefined topic suggestions
  final List<String> _topicSuggestions = [
    'World History',
    'Mathematics',
    'Science',
    'Geography',
    'Literature',
    'Biology',
    'Chemistry',
    'Physics',
    'Computer Science',
    'Art History',
    'Philosophy',
    'Psychology',
    'Economics',
    'Environmental Science',
    'Astronomy',
  ];

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController();
    _countController = TextEditingController(text: '5');
    _testConnections();
  }

  Future<void> _testConnections() async {
    try {
      final aiService = ImprovedAIService();

      // Test connections and fetch models in parallel
      final futures = await Future.wait([
        aiService.testConnections(),
        aiService.getAvailableModels(),
      ]);

      final status = futures[0] as Map<String, bool>;
      final models = futures[1] as List<Map<String, dynamic>>;

      setState(() {
        _connectionStatus = status;
        _availableModels = models;
        _isLoadingConnections = false;
      });

      debugPrint('Loaded ${models.length} AI models');
    } catch (e) {
      debugPrint('Error testing connections: $e');
      setState(() {
        _isLoadingConnections = false;
      });
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.blue),
          SizedBox(width: 8),
          Text('Generate Questions with AI'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status Card
                _buildConnectionStatusCard(),
                const SizedBox(height: 16),

                // Topic Field with Suggestions
                _buildTopicField(),
                const SizedBox(height: 16),

                // Difficulty Selection
                _buildDifficultyField(),
                const SizedBox(height: 16),

                // Count Field
                _buildCountField(),
                const SizedBox(height: 16),

                // AI Model Selection
                _buildModelSelection(),
                const SizedBox(height: 16),

                // Tips Card
                _buildTipsCard(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _canGenerate() ? _handleGenerate : null,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate'),
        ),
      ],
    );
  }

  Widget _buildConnectionStatusCard() {
    if (_isLoadingConnections) {
      return Card(
        color: Colors.blue.shade50,
        child: const Padding(
          padding: EdgeInsets.all(12.0),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Testing AI connections...'),
            ],
          ),
        ),
      );
    }

    final hasConnection = _connectionStatus.values.any((status) => status);
    final workingServices = _connectionStatus.entries
        .where((entry) => entry.value)
        .length;
    final totalServices = _connectionStatus.length;

    return Card(
      color: hasConnection ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasConnection ? Icons.wifi : Icons.wifi_off,
                  color: hasConnection ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  hasConnection
                      ? 'AI Services: $workingServices/$totalServices available'
                      : 'AI Services: Using fallback mode',
                  style: TextStyle(
                    color: hasConnection
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (!hasConnection) ...[
              const SizedBox(height: 4),
              Text(
                'Don\'t worry! We\'ll create template questions you can edit.',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopicField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _topicController,
          decoration: const InputDecoration(
            labelText: 'Topic *',
            border: OutlineInputBorder(),
            hintText: 'e.g., World History, Mathematics, Science',
            prefixIcon: Icon(Icons.topic),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a topic';
            }
            if (value.trim().length < 3) {
              return 'Topic must be at least 3 characters';
            }
            return null;
          },
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Text(
          'Suggestions:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _topicSuggestions.map((suggestion) {
            return ActionChip(
              label: Text(suggestion, style: const TextStyle(fontSize: 11)),
              onPressed: () {
                _topicController.text = suggestion;
                setState(() {});
              },
              backgroundColor: Colors.blue.shade50,
              side: BorderSide(color: Colors.blue.shade200),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDifficultyField() {
    return DropdownButtonFormField<String>(
      value: _difficulty,
      decoration: const InputDecoration(
        labelText: 'Difficulty Level',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.trending_up),
      ),
      items: [
        DropdownMenuItem(
          value: 'easy',
          child: Row(
            children: [
              Icon(Icons.sentiment_satisfied, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              const Text('Easy'),
              const SizedBox(width: 8),
              Text(
                '(45s)',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'medium',
          child: Row(
            children: [
              Icon(Icons.sentiment_neutral, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              const Text('Medium'),
              const SizedBox(width: 8),
              Text(
                '(30s)',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'hard',
          child: Row(
            children: [
              Icon(
                Icons.sentiment_very_dissatisfied,
                color: Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text('Hard'),
              const SizedBox(width: 8),
              Text(
                '(20s)',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _difficulty = value!;
        });
      },
    );
  }

  Widget _buildCountField() {
    return TextFormField(
      controller: _countController,
      decoration: const InputDecoration(
        labelText: 'Number of Questions',
        border: OutlineInputBorder(),
        hintText: '1-10 questions',
        prefixIcon: Icon(Icons.format_list_numbered),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter number of questions';
        }
        final count = int.tryParse(value);
        if (count == null || count < 1 || count > 10) {
          return 'Please enter a number between 1 and 10';
        }
        return null;
      },
    );
  }

  Widget _buildModelSelection() {
    final hasWorkingConnections = _connectionStatus.values.any(
      (status) => status,
    );
    final hasModels = _availableModels.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedModelId,
          decoration: InputDecoration(
            labelText: hasModels
                ? 'AI Model (${_availableModels.length} available)'
                : 'AI Model (Optional)',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.psychology),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Auto-select best available'),
            ),
            if (hasWorkingConnections && hasModels) ...[
              // Show all available models from API
              ..._availableModels.map((model) {
                final id = model['id'] as String;
                final name = model['name'] as String;
                final isRecommended =
                    id.contains('llama') || id.contains('mistral');

                return DropdownMenuItem<String>(
                  value: id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRecommended) ...[
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          name.length > 35
                              ? '${name.substring(0, 32)}...'
                              : name,
                          style: TextStyle(
                            fontWeight: isRecommended
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else if (hasWorkingConnections && !hasModels) ...[
              // Fallback to hardcoded models if API fetch failed
              const DropdownMenuItem<String>(
                value: 'meta-llama/llama-3.2-3b-instruct:free',
                child: Text('Llama 3.2 (Recommended)'),
              ),
              const DropdownMenuItem<String>(
                value: 'mistralai/mistral-7b-instruct:free',
                child: Text('Mistral 7B'),
              ),
            ] else ...[
              DropdownMenuItem<String>(
                value: 'fallback',
                child: Text(
                  'Fallback Mode (Template Questions)',
                  style: TextStyle(color: Colors.orange.shade700),
                ),
              ),
            ],
          ],
          onChanged: (value) {
            setState(() {
              _selectedModelId = value;
            });
          },
        ),
        if (hasModels) ...[
          const SizedBox(height: 8),
          Text(
            '✨ Found ${_availableModels.length} free AI models! Starred models are recommended.',
            style: TextStyle(fontSize: 12, color: Colors.green.shade600),
          ),
        ] else if (!hasWorkingConnections) ...[
          const SizedBox(height: 8),
          Text(
            'AI services are not available. We\'ll create template questions based on your topic.',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
          ),
        ],
      ],
    );
  }

  Widget _buildTipsCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tips for better results:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...const [
              '• Be specific with your topic (e.g., "Ancient Rome" vs "History")',
              '• Use proper nouns and terminology',
              '• Start with fewer questions (3-5) to test quality',
              '• All generated questions can be edited after creation',
            ].map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  tip,
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canGenerate() {
    return _topicController.text.trim().length >= 3 &&
        _countController.text.isNotEmpty &&
        !_isLoadingConnections;
  }

  void _handleGenerate() {
    if (_formKey.currentState!.validate()) {
      final topic = _topicController.text.trim();
      final count = int.parse(_countController.text);

      // Close dialog first
      Navigator.pop(context);

      // Call the generation function
      widget.onGenerate(topic, _difficulty, count, modelId: _selectedModelId);
    }
  }
}
