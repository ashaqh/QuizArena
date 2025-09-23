import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/game.dart';
import '../../models/player.dart';

class GameHostScreen extends ConsumerStatefulWidget {
  const GameHostScreen({super.key});

  @override
  ConsumerState<GameHostScreen> createState() => _GameHostScreenState();
}

class _GameHostScreenState extends ConsumerState<GameHostScreen> {
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
    if (currentGame == null) {
      return const Scaffold(body: Center(child: Text('No active game')));
    }

    final questions = currentGame.quiz?.questions ?? [];
    final currentIndex = currentGame.currentQuestionIndex;

    // Start timer for current question
    if (currentIndex < questions.length && _questionTimer == null) {
      _startQuestionTimer();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hosting: ${currentGame.id}'),
        actions: [
          if (currentIndex >= questions.length)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _endGame,
              tooltip: 'End Game',
            ),
        ],
      ),
      body: Column(
        children: [
          if (currentIndex < questions.length) ...[
            _buildQuestionDisplay(currentGame),
            const Divider(),
            _buildPlayerScores(currentGame),
            const Spacer(),
            _buildTimerAndNextButton(currentGame),
          ] else ...[
            _buildGameResults(currentGame),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionDisplay(Game game) {
    final question = game.quiz!.questions[game.currentQuestionIndex];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              question.text,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...question.answers.map(
              (a) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: null, // Disabled for host view
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(a.text, style: const TextStyle(color: Colors.black)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerScores(Game game) {
    return Expanded(
      child: ListView.builder(
        itemCount: game.players.length,
        itemBuilder: (context, index) {
          final player = game.players[index];
          return ListTile(
            leading: CircleAvatar(child: Text(player.name[0])),
            title: Text(player.name),
            trailing: Text('${player.totalScore} pts'),
          );
        },
      ),
    );
  }

  Widget _buildGameResults(Game game) {
    return Expanded(
      child: Column(
        children: [
          const Text('Final Results', style: TextStyle(fontSize: 24)),
          Expanded(
            child: ListView.builder(
              itemCount: game.players.length,
              itemBuilder: (context, index) {
                final player = game.players[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(player.name[0])),
                    title: Text(player.name),
                    subtitle: LinearProgressIndicator(
                      value: game.players.isNotEmpty
                          ? player.totalScore /
                                game.players
                                    .map((p) => p.totalScore)
                                    .reduce((a, b) => a > b ? a : b)
                          : 0,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    trailing: Text('${player.totalScore} pts'),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(onPressed: _endGame, child: const Text('End Game')),
        ],
      ),
    );
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
        if (currentGame != null && mounted) {
          _nextQuestion(currentGame);
        }
      }
    });
  }

  Widget _buildTimerAndNextButton(Game game) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Time left: $_timeLeft seconds',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _nextQuestion(game),
            child: Text(
              game.currentQuestionIndex < game.quiz!.questions.length - 1
                  ? 'Next Question'
                  : 'Show Results',
            ),
          ),
        ],
      ),
    );
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

  void _endGame() async {
    await ref.read(currentGameProvider.notifier).endGame();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
