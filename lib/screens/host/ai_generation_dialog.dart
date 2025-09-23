import 'package:flutter/material.dart';
import '../../services/ai_service.dart';

// AI Generation Dialog Content
class AIGenerationDialogContent extends StatefulWidget {
  final Function(String topic, String difficulty, int count, {String? modelId})
  onGenerate;

  const AIGenerationDialogContent({super.key, required this.onGenerate});

  @override
  AIGenerationDialogContentState createState() =>
      AIGenerationDialogContentState();
}

class AIGenerationDialogContentState extends State<AIGenerationDialogContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _topicController;
  String _difficulty = 'medium';
  late TextEditingController _countController;
  String? _selectedModelId;
  List<Map<String, dynamic>> _availableModels = [];
  bool _isLoadingModels = true;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController();
    _countController = TextEditingController(text: '5');
    _loadModels();
  }

  Future<void> _loadModels() async {
    try {
      final aiService = AIService();
      final models = await aiService.getFreeModels();
      setState(() {
        _availableModels = models;
        _isLoadingModels = false;
      });
    } catch (e) {
      debugPrint('Error loading models: $e');
      setState(() {
        _isLoadingModels = false;
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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        contentPadding: const EdgeInsets.all(24),
        title: const Text('Generate Questions with AI'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _topicController,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'Topic',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., World History, Mathematics, Science',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a topic';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _difficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'easy', child: Text('Easy')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'hard', child: Text('Hard')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _difficulty = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedModelId,
                    decoration: const InputDecoration(
                      labelText: 'AI Model (Optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Select a model or use default free AI',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Default (Free AI)'),
                      ),
                      if (_isLoadingModels)
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Loading models...'),
                        )
                      else
                        ..._availableModels.map((model) {
                          final modelId = model['id'] as String;
                          final modelName =
                              model['name'] as String? ??
                              modelId.split('/').last;
                          return DropdownMenuItem<String>(
                            value: modelId,
                            child: Text(modelName),
                          );
                        }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedModelId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _countController,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'Number of Questions',
                      border: OutlineInputBorder(),
                      hintText: '1-10',
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
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final topic = _topicController.text.trim();
                final count = int.parse(_countController.text);
                widget.onGenerate(
                  topic,
                  _difficulty,
                  count,
                  modelId: _selectedModelId,
                );
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}
