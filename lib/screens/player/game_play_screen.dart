import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/game.dart';
import '../../models/player.dart';
import 'game_results_screen.dart';

/// Game play screen where players answer questions in real-time
class GamePlayScreen extends ConsumerStatefulWidget {
  const GamePlayScreen({super.key});

  @override
  ConsumerState<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends ConsumerState<GamePlayScreen> {
  String? _selectedAnswerId;
  bool _hasAnswered = false;
  int _lastQuestionIndex = -1;
  Timer? _questionTimer;
  int _timeLeft = 30;

  @override
  void dispose() {
    _questionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentGame = ref.watch(currentGameProvider);
    final currentPlayer = ref.watch(currentPlayerProvider);

    if (currentGame == null) {
      return const Scaffold(body: Center(child: Text('No active game')));
    }

    final isHost = currentPlayer?.id == currentGame.hostId;
    final currentQuestionIndex = currentGame.currentQuestionIndex;
    final questions = currentGame.quiz?.questions ?? [];

    // Reset state when question changes
    if (currentQuestionIndex != _lastQuestionIndex) {
      _lastQuestionIndex = currentQuestionIndex;
      _questionTimer?.cancel();
      _questionTimer = null;
      _timeLeft = 30;
      _selectedAnswerId = null;
      _hasAnswered = false;
    }

    if (currentQuestionIndex >= questions.length) {
      // Navigate to results screen when game is finished
      Future.delayed(Duration.zero, () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GameResultsScreen(game: currentGame),
            ),
          );
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Start timer for all players
    if (_questionTimer == null && !_hasAnswered) {
      _startQuestionTimer();
    }

    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${currentQuestionIndex + 1}/${questions.length}'),
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
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.blue.shade50],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentQuestion.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ...currentQuestion.answers.map(
                      (answer) => _buildAnswerButton(
                        answer,
                        currentQuestion.correctAnswerId,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (isHost) ...[
                      Text(
                        'Time left: $_timeLeft seconds',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _nextQuestion(currentGame),
                        child: Text(
                          currentQuestionIndex < questions.length - 1
                              ? 'Next Question'
                              : 'Show Results',
                        ),
                      ),
                    ] else if (_hasAnswered)
                      const Text(
                        'Waiting for next question...',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Time left: $_timeLeft seconds',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Select your answer!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButton(dynamic answer, String correctAnswerId) {
    final currentGame = ref.watch(currentGameProvider);
    final currentPlayer = ref.watch(currentPlayerProvider);
    final isHost = currentPlayer?.id == currentGame?.hostId;

    final isSelected = _selectedAnswerId == answer.id;
    final buttonColor = isHost
        ? Colors.grey.shade300
        : (isSelected ? Colors.blue : Colors.grey.shade300);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: (isHost || _hasAnswered)
            ? null
            : () => _selectAnswer(answer.id),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          backgroundColor: buttonColor,
          disabledBackgroundColor: buttonColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isSelected ? 8 : 2,
        ),
        child: Text(
          answer.text,
          style: const TextStyle(fontSize: 18, color: Colors.black),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _selectAnswer(String answerId) {
    setState(() {
      _selectedAnswerId = answerId;
      _hasAnswered = true;
    });

    // Submit answer to the game
    final currentGame = ref.read(currentGameProvider);
    final currentPlayer = ref.read(currentPlayerProvider);
    if (currentGame != null && currentPlayer != null) {
      final updatedAnswers = Map<String, Map<int, String>>.from(
        currentGame.playerAnswers,
      );
      updatedAnswers[currentPlayer.id] ??= {};
      updatedAnswers[currentPlayer.id]![currentGame.currentQuestionIndex] =
          answerId;

      final updatedGame = currentGame.copyWith(playerAnswers: updatedAnswers);
      ref.read(currentGameProvider.notifier).updateGame(updatedGame);
    }
  }

  void _startQuestionTimer() {
    _timeLeft = 30;
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0) {
        _questionTimer?.cancel();
        _questionTimer = null;
        final currentGame = ref.read(currentGameProvider);
        final currentPlayer = ref.read(currentPlayerProvider);
        final isHost = currentPlayer?.id == currentGame?.hostId;
        if (isHost && currentGame != null && mounted) {
          _nextQuestion(currentGame);
        }
      }
    });
  }

  Future<void> _nextQuestion(Game game) async {
    _questionTimer?.cancel();
    _questionTimer = null;
    _timeLeft = 30;

    try {
      // First, score the current question
      final updatedPlayers = _scoreCurrentQuestion(game);

      final nextIndex = game.currentQuestionIndex + 1;
      final questions = game.quiz?.questions ?? [];
      final status = nextIndex >= questions.length ? 'finished' : 'in_progress';

      final updatedGame = game.copyWith(
        currentQuestionIndex: nextIndex,
        status: status,
        players: updatedPlayers,
      );

      await ref.read(currentGameProvider.notifier).updateGame(updatedGame);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating game: $e')));
      }
    }
  }

  List<Player> _scoreCurrentQuestion(Game game) {
    final questions = game.quiz?.questions ?? [];
    if (game.currentQuestionIndex >= questions.length) return game.players;

    final currentQuestion = questions[game.currentQuestionIndex];
    final correctAnswerId = currentQuestion.correctAnswerId;

    return game.players.map((player) {
      final playerAnswers = game.playerAnswers[player.id];
      if (playerAnswers != null &&
          playerAnswers[game.currentQuestionIndex] == correctAnswerId) {
        // Correct answer, add 10 points
        return player.copyWith(totalScore: player.totalScore + 10);
      }
      return player;
    }).toList();
  }
}
