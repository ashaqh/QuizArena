import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/providers.dart';
import '../../models/player.dart';
import 'game_lobby_screen.dart';

/// Screen for players to join an existing game
class JoinGameScreen extends ConsumerStatefulWidget {
  const JoinGameScreen({super.key});

  @override
  ConsumerState<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends ConsumerState<JoinGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gameCodeController = TextEditingController();
  final _playerNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePlayerName();
  }

  @override
  void dispose() {
    _gameCodeController.dispose();
    _playerNameController.dispose();
    super.dispose();
  }

  /// Initialize player name from authentication data
  void _initializePlayerName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Try to get display name first, then email username, then fallback
      String? userName;
      
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        userName = user.displayName;
      } else if (user.email != null && user.email!.isNotEmpty) {
        // Extract username from email (part before @)
        userName = user.email!.split('@').first;
      }
      
      if (userName != null && userName.isNotEmpty) {
        // Set the initial text but keep it editable
        _playerNameController.text = userName;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Game'),
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
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.blue.shade50],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Join a Quiz Game',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter the game code and your name',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _gameCodeController,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'Game Code',
                          hintText: 'Enter 6-letter code',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.code),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a game code';
                          }
                          if (value.length != 6) {
                            return 'Game code must be 6 letters';
                          }
                          if (!RegExp(r'^[A-Z]+$').hasMatch(value)) {
                            return 'Game code must contain only letters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _playerNameController,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'Your Name',
                          hintText: 'Enter your display name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        maxLength: 20,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          if (value.length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _joinGame,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Join Game',
                                  style: TextStyle(fontSize: 18),
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
      ),
    );
  }

  Future<void> _joinGame() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gameCode = _gameCodeController.text.trim().toUpperCase();
      final playerName = _playerNameController.text.trim();

      final player = Player(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: playerName,
        totalScore: 0,
        scores: [],
      );

      final currentGameNotifier = ref.read(currentGameProvider.notifier);
      await currentGameNotifier.joinGame(gameCode, player);

      // Set current player
      ref.read(currentPlayerProvider.notifier).state = player;

      // Navigate to game lobby
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GameLobbyScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join game: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
