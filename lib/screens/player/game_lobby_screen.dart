import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/providers.dart';
import '../../models/game.dart';
import '../../models/player.dart';
import '../../widgets/main_navigation.dart';
import 'game_play_screen.dart';

/// Game lobby screen where players wait for the game to start
class GameLobbyScreen extends ConsumerStatefulWidget {
  const GameLobbyScreen({super.key});

  @override
  ConsumerState<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends ConsumerState<GameLobbyScreen> {
  @override
  Widget build(BuildContext context) {
    final currentGame = ref.watch(currentGameProvider);

    if (currentGame == null) {
      return const Scaffold(body: Center(child: Text('No active game')));
    }

    final currentPlayer = ref.watch(currentPlayerProvider);
    final isHost = currentPlayer?.id == currentGame.hostId;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('games')
          .doc(currentGame.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final gameData = snapshot.data!.data() as Map<String, dynamic>?;
        if (gameData == null) {
          return const Scaffold(body: Center(child: Text('Game not found')));
        }

        final updatedGame = Game.fromJson({'id': currentGame.id, ...gameData});

        debugPrint(
          'Game status: ${updatedGame.status}, isHost: $isHost, currentPlayerId: ${currentPlayer?.id}, hostId: ${updatedGame.hostId}',
        );

        // If game has started, navigate to game play screen for all players including host
        if (updatedGame.status == 'in_progress') {
          debugPrint(
            'Navigating to game screen (hostId: ${updatedGame.hostId}, playerId: ${currentPlayer?.id})',
          );
          // Use Future.delayed to avoid build-time navigation
          Future.delayed(Duration.zero, () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const GamePlayScreen()),
              );
            }
          });
        }

        return _buildLobbyContent(context, updatedGame, currentPlayer, isHost);
      },
    );
  }

  Widget _buildLobbyContent(
    BuildContext context,
    Game currentGame,
    Player? currentPlayer,
    bool isHost,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game: ${currentGame.id}'),
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
                constraints: const BoxConstraints(maxWidth: 500),
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
                    const Text(
                      'Waiting for Game to Start',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Game Code: ${currentGame.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Players in Lobby:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...currentGame.players.map(
                      (player) => _buildPlayerCard(player, currentPlayer),
                    ),
                    const SizedBox(height: 32),
                    if (isHost)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: currentGame.players.length >= 2
                              ? () => _startGame(context, currentGame)
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            currentGame.players.length >= 2
                                ? 'Start Game'
                                : 'Waiting for players... (${currentGame.players.length}/2)',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Waiting for host to start the game...',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _leaveGame(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Leave Game',
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ),
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

  Widget _buildPlayerCard(Player player, Player? currentPlayer) {
    final isCurrentPlayer = currentPlayer?.id == player.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentPlayer ? Colors.blue : Colors.grey,
          child: Text(
            player.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          player.name,
          style: TextStyle(
            fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text('Score: ${player.totalScore}'),
        trailing: isCurrentPlayer
            ? const Icon(Icons.person, color: Colors.blue)
            : null,
      ),
    );
  }

  void _startGame(BuildContext context, Game game) async {
    debugPrint('Host starting game: ${game.id}');
    try {
      // Update game status to 'in_progress' in Firestore
      debugPrint('Updating game status to in_progress');
      await FirebaseFirestore.instance.collection('games').doc(game.id).update({
        'status': 'in_progress',
      });
      debugPrint('Game status updated successfully');

      // Navigate to game play screen
      debugPrint('Host navigating to game screen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GamePlayScreen()),
      );
    } catch (e) {
      debugPrint('Error starting game: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start game: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _leaveGame(BuildContext context) {
    // Clear current game and player
    ref.read(currentGameProvider.notifier).endGame();
    ref.read(currentPlayerProvider.notifier).state = null;

    // Navigate to main navigation
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainNavigationScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }
}
