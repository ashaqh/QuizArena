import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/providers.dart';
import '../../models/quiz.dart';
import '../../models/question.dart';
import '../../models/answer.dart';
import '../../services/ai_service.dart';
import '../../services/image_upload_service.dart';
import '../../widgets/responsive_image.dart';
import 'ai_generation_dialog.dart';

// LTRTextInputFormatter remains for potential future use or other fields
class LTRTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;
    if (!newText.startsWith('\u200E') && newText.isNotEmpty) {
      newText = '\u200E$newText';
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset:
            newValue.selection.baseOffset +
            (newText.length - newValue.text.length),
      ),
    );
  }
}

class CreateEditQuizScreen extends ConsumerStatefulWidget {
  final Quiz? quiz;
  const CreateEditQuizScreen({super.key, this.quiz});
  @override
  ConsumerState<CreateEditQuizScreen> createState() =>
      _CreateEditQuizScreenState();
}

class _CreateEditQuizScreenState extends ConsumerState<CreateEditQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late List<Question> _questions;
  final Uuid _uuid =
      const Uuid(); // Correctly a final field in this State class

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quiz?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.quiz?.description ?? '',
    );
    _questions =
        widget.quiz?.questions.map((q) {
          return Question(
            id: q.id,
            text: q.text,
            answers: List<Answer>.from(
              q.answers.map(
                (a) => Answer(id: a.id, text: a.text, isCorrect: a.isCorrect),
              ),
            ),
            correctAnswerId: q.correctAnswerId,
            timeLimit: q.timeLimit,
            imageUrl: q.imageUrl,
          );
        }).toList() ??
        [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.quiz != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Quiz' : 'Create Quiz'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                _saveQuiz, // This should now correctly find the method below
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildQuizForm(),
              const SizedBox(height: 24),
              _buildQuestionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quiz Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _generateAIQuestions,
                  icon: const Icon(Icons.smart_toy),
                  label: const Text('Generate with AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_questions.isEmpty)
          const Center(
            child: Text(
              'No questions added yet',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ..._questions.map((question) => _buildQuestionCard(question)),
      ],
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(question.text),
        subtitle: Text(
          '${question.answers.length} answers • ${question.timeLimit}s${question.imageUrl != null ? " • Has image" : ""}',
        ),
        leading: question.imageUrl != null
            ? Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    question.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, color: Colors.grey, size: 30);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editQuestion(question),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteQuestion(question),
            ),
          ],
        ),
      ),
    );
  }

  void _addQuestion() => _showQuestionDialog();
  void _editQuestion(Question question) =>
      _showQuestionDialog(question: question);
  void _deleteQuestion(Question q) =>
      setState(() => _questions.removeWhere((item) => item.id == q.id));

  void _generateAIQuestions() => _showAIGenerationDialog();

  void _showQuestionDialog({Question? question}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _QuestionDialogContent(
          question: question,
          uuid: _uuid, // Use the _uuid from _CreateEditQuizScreenState
          onSave: (Question newOrUpdatedQuestion) {
            setState(() {
              if (question != null) {
                final index = _questions.indexWhere(
                  (q) => q.id == newOrUpdatedQuestion.id,
                );
                if (index != -1) {
                  _questions[index] = newOrUpdatedQuestion;
                }
              } else {
                _questions.add(newOrUpdatedQuestion);
              }
            });
          },
        );
      },
    );
  }

  void _showAIGenerationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AIGenerationDialogContent(
          onGenerate: (topic, difficulty, count, {String? modelId}) async {
            Navigator.pop(dialogContext); // Close dialog
            await _generateQuestionsWithAI(
              topic,
              difficulty,
              count,
              modelId: modelId,
            );
          },
        );
      },
    );
  }

  Future<void> _generateQuestionsWithAI(
    String topic,
    String difficulty,
    int count, {
    String? modelId,
  }) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating questions with AI...')),
      );

      final aiService = AIService();
      final generatedQuestions = await aiService.generateQuestions(
        topic: topic,
        difficulty: difficulty,
        count: count,
        modelId: modelId,
      );

      setState(() {
        _questions.addAll(generatedQuestions);
      });

      final isSampleQuestions = generatedQuestions.any(
        (q) => q.text.contains('Sample Question'),
      );
      final message = isSampleQuestions
          ? 'Created ${generatedQuestions.length} sample questions. Please edit them manually since AI generation failed.'
          : 'Successfully generated ${generatedQuestions.length} questions!';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate questions: $e')),
      );
    }
  }

  // Ensure _saveQuiz method is correctly defined within this class
  void _saveQuiz() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    final quizToSave = Quiz(
      id: widget.quiz?.id ?? _uuid.v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      createdBy: 'current_user', // TODO: Get from auth
      questions: _questions,
      createdAt: widget.quiz?.createdAt ?? DateTime.now(),
    );

    final quizzesNotifier = ref.read(quizzesProvider.notifier);
    if (widget.quiz != null) {
      quizzesNotifier.updateQuiz(quizToSave);
    } else {
      quizzesNotifier.addQuiz(quizToSave);
    }

    Navigator.pop(context); // Pop the CreateEditQuizScreen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${quizToSave.title} ${widget.quiz != null ? "updated" : "created"}',
        ),
      ),
    );
  }
} // End of _CreateEditQuizScreenState class

// New StatefulWidget for the dialog content
class _QuestionDialogContent extends StatefulWidget {
  final Question? question;
  final Uuid uuid;
  final Function(Question) onSave;

  const _QuestionDialogContent({
    this.question,
    required this.uuid,
    required this.onSave,
  });

  @override
  _QuestionDialogContentState createState() => _QuestionDialogContentState();
}

class _QuestionDialogContentState extends State<_QuestionDialogContent> {
  late TextEditingController _questionTextController;
  late TextEditingController _timeLimitController;
  late TextEditingController _imageUrlController;
  late List<Answer> _dialogAnswers;
  late Map<String, TextEditingController> _answerControllers;
  bool _isUploadingImage = false;
  bool get _isEditingQuestion => widget.question != null;

  @override
  void initState() {
    super.initState();
    _questionTextController = TextEditingController(
      text: widget.question?.text ?? '',
    );
    _timeLimitController = TextEditingController(
      text: widget.question?.timeLimit.toString() ?? '30',
    );
    _imageUrlController = TextEditingController(
      text: widget.question?.imageUrl ?? '',
    );
    _dialogAnswers = List<Answer>.from(
      widget.question?.answers.map(
            (a) => Answer(id: a.id, text: a.text, isCorrect: a.isCorrect),
          ) ??
          [],
    );
    _answerControllers = {};
    for (var ans in _dialogAnswers) {
      String sanitizedText = ans.text
          .replaceAll('\u200E', '')
          .replaceAll('\u200F', '');
      _answerControllers[ans.id] = TextEditingController(text: sanitizedText);
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _timeLimitController.dispose();
    _imageUrlController.dispose();
    _answerControllers.forEach((_, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        contentPadding: const EdgeInsets.all(24),
        title: Text(_isEditingQuestion ? 'Edit Question' : 'Add Question'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _questionTextController,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'Question Text',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _timeLimitController,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'Time Limit (seconds)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildImageSection(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Answers',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          String newAnswerId = widget.uuid.v4();
                          _dialogAnswers.add(
                            Answer(id: newAnswerId, text: '', isCorrect: false),
                          );
                          _answerControllers[newAnswerId] =
                              TextEditingController();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._dialogAnswers.map((answer) {
                  if (_answerControllers[answer.id] == null) {
                    String sanitizedText = answer.text
                        .replaceAll('\u200E', '')
                        .replaceAll('\u200F', '');
                    _answerControllers[answer.id] = TextEditingController(
                      text: sanitizedText,
                    );
                  }
                  return _buildAnswerField(
                    answer,
                    _answerControllers[answer.id]!,
                    (updatedAnswer) {
                      setState(() {
                        final index = _dialogAnswers.indexWhere(
                          (a) => a.id == updatedAnswer.id,
                        );
                        if (index != -1) {
                          if (updatedAnswer.isCorrect) {
                            for (int i = 0; i < _dialogAnswers.length; i++) {
                              if (_dialogAnswers[i].id != updatedAnswer.id) {
                                _dialogAnswers[i] = _dialogAnswers[i].copyWith(
                                  isCorrect: false,
                                );
                              }
                            }
                          }
                          _dialogAnswers[index] = updatedAnswer;
                        }
                      });
                    },
                    () {
                      setState(() {
                        _answerControllers[answer.id]?.dispose();
                        _answerControllers.remove(answer.id);
                        _dialogAnswers.removeWhere((a) => a.id == answer.id);
                      });
                    },
                  );
                }),
              ],
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
              final questionText = _questionTextController.text.trim();
              final timeLimit = int.tryParse(_timeLimitController.text) ?? 30;

              if (questionText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter question text')),
                );
                return;
              }
              if (_dialogAnswers.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please add at least one answer'),
                  ),
                );
                return;
              }
              if (!_dialogAnswers.any((a) => a.isCorrect)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please mark at least one answer as correct'),
                  ),
                );
                return;
              }

              List<Answer> finalAnswers = _dialogAnswers.map((ans) {
                return Answer(
                  id: ans.id,
                  text: _answerControllers[ans.id]?.text.trim() ?? '',
                  isCorrect: ans.isCorrect,
                );
              }).toList();

              final newOrUpdatedQuestion = Question(
                id: widget.question?.id ?? widget.uuid.v4(),
                text: questionText,
                answers: finalAnswers,
                correctAnswerId: finalAnswers.firstWhere((a) => a.isCorrect).id,
                timeLimit: timeLimit,
                imageUrl: _imageUrlController.text.trim().isEmpty 
                    ? null 
                    : _imageUrlController.text.trim(),
              );
              widget.onSave(newOrUpdatedQuestion);
              Navigator.pop(context);
            },
            child: Text(_isEditingQuestion ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Question Image (Optional)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Device upload button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUploadingImage ? null : _pickImageFromDevice,
            icon: const Icon(Icons.upload_file),
            label: Text(_isUploadingImage ? 'Uploading...' : 'Upload Image from Device'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        if (_isUploadingImage) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text(
            'Uploading image to cloud storage...',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],

        if (_imageUrlController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          ImagePreview(
            imageUrl: _imageUrlController.text,
            onRemove: () {
              setState(() {
                _imageUrlController.clear();
              });
            },
          ),
        ],
        
        const SizedBox(height: 8),
        const Text(
          'Upload an image from your camera or gallery. Images are stored securely in the cloud.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _pickImageFromDevice() async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      // Show source selection dialog
      final ImageSource? source = await _showImageSourceSelectionDialog();
      if (source == null) {
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }

      // Pick image
      final XFile? imageFile = await ImageUploadService.pickImageFromDevice(source: source);
      if (imageFile == null) {
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }

      // Upload to Firebase Storage
      final String downloadUrl = await ImageUploadService.uploadImageToFirebase(imageFile);
      
      setState(() {
        _imageUrlController.text = downloadUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      
      if (mounted) {
        String errorMessage = 'Failed to upload image: $e';
        
        // Provide specific guidance for authorization errors
        if (e.toString().contains('unauthorized') || 
            e.toString().contains('permission') ||
            e.toString().contains('Firebase Storage: User is not authorized')) {
          errorMessage = 'Upload failed: Firebase Storage rules need configuration.\n\n'
                        'Please:\n'
                        '1. Go to Firebase Console\n'
                        '2. Navigate to Storage → Rules\n'
                        '3. Configure upload permissions for authenticated users\n\n'
                        'See FIREBASE_STORAGE_RULES.md for details.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Copy Rules',
              onPressed: () {
                // You can implement copying rules to clipboard here if needed
              },
            ),
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceSelectionDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: const Text('Choose where to pick the image from:'),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnswerField(
    Answer answer,
    TextEditingController controller,
    void Function(Answer updatedAnswer) onCorrectnessChanged,
    void Function() onDelete,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                child: TextField(
                  controller: controller,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  keyboardType: TextInputType.text,
                  inputFormatters: [],
                  decoration: InputDecoration(
                    hintText: 'Answer text',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                  ),
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
            Checkbox(
              value: answer.isCorrect,
              onChanged: (value) {
                Answer updatedAnswer = answer.copyWith(
                  isCorrect: value ?? false,
                );
                onCorrectnessChanged(updatedAnswer);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
