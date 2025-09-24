import 'package:flutter/material.dart';
import 'dart:async';
import '../services/robust_ai_service.dart';
import '../models/question.dart';

/// Progress dialog for AI generation with detailed status updates
class AIGenerationProgressDialog extends StatefulWidget {
  final String topic;
  final String difficulty;
  final int count;
  final String? preferredModel;
  final Function(List<Question>) onSuccess;
  final Function(String error) onError;

  const AIGenerationProgressDialog({
    super.key,
    required this.topic,
    required this.difficulty,
    required this.count,
    this.preferredModel,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<AIGenerationProgressDialog> createState() =>
      _AIGenerationProgressDialogState();
}

class _AIGenerationProgressDialogState extends State<AIGenerationProgressDialog>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  StreamSubscription<GenerationProgress>? _progressSubscription;
  GenerationProgress? _currentProgress;
  bool _canCancel = true;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startGeneration();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startGeneration() async {
    final aiService = RobustAIService();

    _progressSubscription = aiService
        .generateQuestionsWithProgress(
          topic: widget.topic,
          difficulty: widget.difficulty,
          count: widget.count,
          preferredModel: widget.preferredModel,
        )
        .listen(
          (progress) {
            setState(() {
              _currentProgress = progress;
            });

            // Animate progress bar
            _progressController.animateTo(progress.progress);

            // Handle completion
            if (progress.status == GenerationStatus.completed) {
              _handleSuccess(progress.questions ?? []);
            } else if (progress.status == GenerationStatus.failed) {
              _handleError(progress.message);
            }

            // Disable cancel after a certain point
            if (progress.progress > 0.8) {
              setState(() {
                _canCancel = false;
              });
            }
          },
          onError: (error) {
            _handleError(error.toString());
          },
        );
  }

  void _handleSuccess(List<Question> questions) async {
    setState(() {
      _isCompleted = true;
      _canCancel = false;
    });

    _pulseController.stop();
    _progressController.animateTo(1.0);

    // Small delay to show completion
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.of(context).pop();
      widget.onSuccess(questions);
    }
  }

  void _handleError(String error) {
    setState(() {
      _isCompleted = true;
      _canCancel = false;
    });

    _pulseController.stop();

    if (mounted) {
      Navigator.of(context).pop();
      widget.onError(error);
    }
  }

  void _cancelGeneration() {
    _progressSubscription?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _currentProgress;

    return WillPopScope(
      onWillPop: () async => _canCancel,
      child: AlertDialog(
        contentPadding: const EdgeInsets.all(24),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with AI icon
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isCompleted ? 1.0 : _pulseAnimation.value,
                        child: Icon(
                          _isCompleted
                              ? Icons.check_circle
                              : Icons.auto_awesome,
                          color: _isCompleted ? Colors.green : Colors.blue,
                          size: 32,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Generating Questions',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.count} questions about "${widget.topic}"',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Progress bar
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            progress?.message ?? 'Initializing...',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${(_progressAnimation.value * 100).toInt()}%',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isCompleted ? Colors.green : Colors.blue,
                        ),
                        minHeight: 6,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Simple tip text
              if (progress != null &&
                  progress.status != GenerationStatus.completed) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This may take a few moments. We\'re trying multiple AI models to get the best results.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.blue.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (_canCancel && !_isCompleted) ...[
            TextButton(
              onPressed: _cancelGeneration,
              child: const Text('Cancel'),
            ),
          ],
          if (_isCompleted) ...[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Utility function to show the AI generation progress dialog
Future<void> showAIGenerationProgress({
  required BuildContext context,
  required String topic,
  required String difficulty,
  required int count,
  String? preferredModel,
  required Function(List<Question>) onSuccess,
  required Function(String error) onError,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AIGenerationProgressDialog(
      topic: topic,
      difficulty: difficulty,
      count: count,
      preferredModel: preferredModel,
      onSuccess: onSuccess,
      onError: onError,
    ),
  );
}
