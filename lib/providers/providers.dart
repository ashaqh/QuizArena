import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../services/sqlite_service.dart';
import '../services/firestore_service.dart';
import '../services/user_data_service.dart';

/// Provider for SQLite service
final sqliteServiceProvider = Provider<SQLiteService>((ref) {
  return SQLiteService();
});

/// Provider for Firestore service
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Provider for UserData service
final userDataServiceProvider = Provider<UserDataService>((ref) {
  return UserDataService();
});

/// Provider for list of quizzes
final quizzesProvider = StateNotifierProvider<QuizzesNotifier, List<Quiz>>((
  ref,
) {
  final sqliteService = ref.watch(sqliteServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return QuizzesNotifier(sqliteService, firestoreService);
});

/// Notifier for managing quizzes state
class QuizzesNotifier extends StateNotifier<List<Quiz>> {
  final SQLiteService _sqliteService;
  final FirestoreService _firestoreService;

  QuizzesNotifier(this._sqliteService, this._firestoreService) : super([]) {
    loadQuizzes();
  }

  /// Load quizzes from storage (Firestore for logged-in users, SQLite for guests)
  Future<void> loadQuizzes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      // Load from Firestore for logged-in users
      debugPrint('Loading quizzes from Firestore for user: ${user.uid}');
      try {
        final userQuizzes = await _firestoreService.getUserQuizzes(user.uid);
        state = userQuizzes;
        debugPrint('Loaded ${userQuizzes.length} quizzes from Firestore');
      } catch (e) {
        debugPrint('Error loading from Firestore: $e');
        state = [];
      }
    } else {
      if (kIsWeb) {
        // On web, SQLite is not supported for guest users
        debugPrint(
          'SQLite not supported on web for guest users, no quizzes loaded',
        );
        state = [];
      } else {
        // Load from SQLite for guests on mobile/desktop
        debugPrint('Loading quizzes from SQLite for guest user');
        final quizzes = await _sqliteService.getQuizzes();
        state = quizzes;
        debugPrint('Loaded ${quizzes.length} quizzes from SQLite');
      }
    }
  }

  /// Add a new quiz
  Future<void> addQuiz(Quiz quiz) async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('Adding quiz to state: ${quiz.title}');

    if (user != null && !user.isAnonymous) {
      // Save to Firestore for logged-in users
      await _firestoreService.saveUserQuiz(user.uid, quiz);
      state = [...state, quiz];
      debugPrint('Quiz added to Firestore and state');
    } else {
      if (kIsWeb) {
        // On web, SQLite is not supported for guest users
        debugPrint(
          'SQLite not supported on web for guest users, quiz not saved locally',
        );
        state = [...state, quiz]; // Still add to state for current session
      } else {
        // Save to SQLite for guests on mobile/desktop
        await _sqliteService.insertQuiz(quiz);
        state = [...state, quiz];
        debugPrint('Quiz added to SQLite and state');
      }
    }
  }

  /// Update an existing quiz
  Future<void> updateQuiz(Quiz quiz) async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('Updating quiz: ${quiz.title}');

    if (user != null && !user.isAnonymous) {
      // Update in Firestore for logged-in users
      await _firestoreService.updateUserQuiz(user.uid, quiz);
      debugPrint('Quiz updated in Firestore');
    } else {
      if (!kIsWeb) {
        // Update in SQLite for guests on mobile/desktop
        await _sqliteService.updateQuiz(quiz);
        debugPrint('Quiz updated in SQLite');
      }
    }
    state = state.map((q) => q.id == quiz.id ? quiz : q).toList();
  }

  /// Delete a quiz
  Future<void> deleteQuiz(String quizId) async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('Deleting quiz: $quizId for user: ${user?.uid ?? 'guest'}');

    if (user != null && !user.isAnonymous) {
      // Delete from Firestore for logged-in users
      try {
        await _firestoreService.deleteUserQuiz(user.uid, quizId);
        debugPrint('Quiz deleted from Firestore');
      } catch (e) {
        debugPrint('Error deleting quiz from Firestore: $e');
        // Continue with state update even if Firestore deletion fails
      }
    } else {
      if (!kIsWeb) {
        // Delete from SQLite for guests on mobile/desktop
        await _sqliteService.deleteQuiz(quizId);
        debugPrint('Quiz deleted from SQLite');
      }
    }

    // Update local state regardless of storage method
    state = state.where((q) => q.id != quizId).toList();
    debugPrint('Quiz removed from local state');
  }
}

/// Provider for current game state
final currentGameProvider = StateNotifierProvider<GameNotifier, Game?>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return GameNotifier(firestoreService);
});

/// Notifier for managing current game state
class GameNotifier extends StateNotifier<Game?> {
  final FirestoreService _firestoreService;
  StreamSubscription<Game>? _gameSubscription;

  GameNotifier(this._firestoreService) : super(null);

  /// Create a new game
  Future<void> createGame(String quizId, String hostId) async {
    final game = await _firestoreService.createGame(quizId, hostId);
    state = game;
    _startListening(game.id);
  }

  /// Join an existing game
  Future<void> joinGame(String gameId, Player player) async {
    final game = await _firestoreService.joinGame(gameId, player);
    state = game;
    _startListening(game.id);
  }

  /// Update game state
  Future<void> updateGame(Game game) async {
    try {
      await _firestoreService.updateGame(game);
      state = game;
    } catch (e) {
      debugPrint('Error updating game: $e');
      rethrow;
    }
  }

  /// End the current game
  Future<void> endGame() async {
    if (state != null) {
      await _firestoreService.endGame(state!.id);
      _gameSubscription?.cancel();
      state = null;
    }
  }

  /// Start listening to game updates
  void _startListening(String gameId) {
    _gameSubscription?.cancel();
    _gameSubscription = _firestoreService.listenToGame(gameId).listen((game) {
      state = game;
    });
  }
}

/// Provider for current player
final currentPlayerProvider = StateProvider<Player?>((ref) => null);
