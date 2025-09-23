import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../models/quiz.dart';
import 'sqlite_service.dart';

/// Service for managing Firestore database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SQLiteService _sqliteService = SQLiteService();

  // Collection references
  CollectionReference get quizzes => _firestore.collection('quizzes');
  CollectionReference get games => _firestore.collection('games');
  CollectionReference get players => _firestore.collection('players');

  /// Create a new game
  Future<Game> createGame(String quizId, String hostId) async {
    // Generate a 6-character alphanumeric game code
    final gameCode = _generateGameCode();
    final gameId = gameCode; // Use the short code as the document ID

    // Fetch the quiz from appropriate storage
    Quiz quiz;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      // For logged-in users, fetch from Firestore
      final userQuizzes = await getUserQuizzes(user.uid);
      quiz = userQuizzes.firstWhere(
        (q) => q.id == quizId,
        orElse: () => throw Exception('Quiz not found'),
      );
    } else {
      if (kIsWeb) {
        // On web, SQLite is not supported for guest users
        throw Exception(
          'Guest users cannot create games on web platform. Please sign in to create and host games.',
        );
      }
      // For guests on mobile/desktop, fetch from SQLite
      final quizzes = await _sqliteService.getQuizzes();
      quiz = quizzes.firstWhere(
        (q) => q.id == quizId,
        orElse: () => throw Exception('Quiz not found'),
      );
    }

    final game = Game(
      id: gameId,
      quizId: quizId,
      hostId: hostId,
      players: [],
      status: 'waiting',
      currentQuestionIndex: 0,
      startedAt: DateTime.now(),
      quiz: quiz,
      playerAnswers: {},
    );

    await games.doc(gameId).set(game.toJson());
    return game;
  }

  /// Join an existing game
  Future<Game> joinGame(String gameId, Player player) async {
    final gameDoc = await games.doc(gameId).get();
    if (!gameDoc.exists) {
      throw Exception('Game not found');
    }

    final gameData = gameDoc.data() as Map<String, dynamic>;
    final game = Game.fromJson(gameData);

    // Add player to the game
    final updatedPlayers = [...game.players, player];
    final updatedGame = Game(
      id: game.id,
      quizId: game.quizId,
      hostId: game.hostId,
      players: updatedPlayers,
      status: game.status,
      currentQuestionIndex: game.currentQuestionIndex,
      startedAt: game.startedAt,
      quiz: game.quiz,
      playerAnswers: game.playerAnswers,
    );

    await games.doc(gameId).update({
      'players': updatedPlayers.map((p) => p.toJson()).toList(),
    });

    return updatedGame;
  }

  /// End a game
  Future<void> endGame(String gameId) async {
    await games.doc(gameId).update({'status': 'finished'});
  }

  /// Get a game by ID
  Future<Game?> getGame(String gameId) async {
    final gameDoc = await games.doc(gameId).get();
    if (!gameDoc.exists) return null;

    final gameData = gameDoc.data() as Map<String, dynamic>;
    return Game.fromJson(gameData);
  }

  /// Update game state
  Future<void> updateGame(Game game) async {
    await games.doc(game.id).update(game.toJson());
  }

  /// Listen to game updates
  Stream<Game> listenToGame(String gameId) {
    return games.doc(gameId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) throw Exception('Game not found');
      final gameData = Map<String, dynamic>.from(data as Map<String, dynamic>)
        ..['id'] = doc.id;
      return Game.fromJson(gameData);
    });
  }

  // Initialize basic collections with sample data
  Future<void> initializeCollections() async {
    // Add sample quiz
    await quizzes.doc('sample_quiz').set({
      'title': 'Sample Quiz',
      'description': 'A sample quiz for QuizArena',
      'questions': [
        {
          'question': 'What is 2 + 2?',
          'options': ['3', '4', '5', '6'],
          'correctAnswer': 1,
        },
      ],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Add sample game
    await games.doc('sample_game').set({
      'quizId': 'sample_quiz',
      'hostId': 'sample_host',
      'status': 'waiting',
      'players': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Add sample player
    await players.doc('sample_player').set({
      'name': 'Sample Player',
      'email': 'sample@example.com',
      'score': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Generate a unique 6-character alphabetic game code
  String _generateGameCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';

    // Generate 6-character code using timestamp as seed
    for (int i = 0; i < 6; i++) {
      final index = ((random + i * 7) % chars.length);
      code += chars[index];
    }

    return code;
  }

  /// Get quizzes for a specific user
  Future<List<Quiz>> getUserQuizzes(String userId) async {
    final snapshot = await quizzes.where('userId', isEqualTo: userId).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Quiz.fromJson(data..['id'] = doc.id);
    }).toList();
  }

  /// Save quiz for a user
  Future<void> saveUserQuiz(String userId, Quiz quiz) async {
    await quizzes.doc(quiz.id).set({...quiz.toJson(), 'userId': userId});
  }

  /// Update quiz for a user
  Future<void> updateUserQuiz(String userId, Quiz quiz) async {
    await quizzes.doc(quiz.id).set({...quiz.toJson(), 'userId': userId});
  }

  /// Delete quiz for a user
  Future<void> deleteUserQuiz(String userId, String quizId) async {
    // First verify the quiz belongs to the user
    final quizDoc = await quizzes.doc(quizId).get();
    if (quizDoc.exists) {
      final quizData = quizDoc.data() as Map<String, dynamic>;
      if (quizData['userId'] == userId) {
        await quizzes.doc(quizId).delete();
        debugPrint('Quiz $quizId deleted from Firestore for user $userId');
      } else {
        throw Exception('Quiz does not belong to the specified user');
      }
    } else {
      debugPrint('Quiz $quizId not found in Firestore');
    }
  }
}
