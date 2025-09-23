import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/game_history.dart';
import '../models/game.dart';
import '../models/player.dart';

/// Service for managing user data, profiles, and game history
class UserDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get userProfiles => _firestore.collection('userProfiles');
  CollectionReference get gameHistory => _firestore.collection('gameHistory');
  CollectionReference get achievements => _firestore.collection('achievements');
  CollectionReference get leaderboards => _firestore.collection('leaderboards');

  /// Get or create user profile
  Future<UserProfile> getOrCreateUserProfile(String userId, String name, String email) async {
    final docRef = userProfiles.doc(userId);
    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return UserProfile.fromJson({...data, 'id': userId});
    } else {
      // Create new user profile
      final newProfile = UserProfile(
        id: userId,
        name: name,
        email: email,
        joinDate: DateTime.now(),
        statistics: UserStatistics(lastActive: DateTime.now()),
      );

      await docRef.set(newProfile.toJson());
      return newProfile;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    await userProfiles.doc(profile.id).set(profile.toJson());
  }

  /// Save game history record
  Future<void> saveGameHistory(GameHistoryRecord record) async {
    final user = _auth.currentUser;
    if (user == null || !record.userId.startsWith(user.uid)) {
      return; // Only save history for authenticated users and their own records
    }

    await gameHistory.doc(record.id).set(record.toJson());
    await _updateUserStatistics(record);
  }

  /// Get user's game history with pagination
  Future<List<GameHistoryRecord>> getUserGameHistory(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? role, // 'host', 'player', or null for all
  }) async {
    try {
      Query query = gameHistory
          .where('userId', isEqualTo: userId)
          .orderBy('playedAt', descending: true)
          .limit(limit);

      if (role != null) {
        query = query.where('role', isEqualTo: role);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GameHistoryRecord.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      debugPrint('Error getting game history (likely missing Firestore index): $e');
      
      // Fallback: Get all user documents and sort in memory
      // This is less efficient but works without an index
      final snapshot = await gameHistory
          .where('userId', isEqualTo: userId)
          .limit(limit * 2) // Get more to account for filtering
          .get();
      
      List<GameHistoryRecord> records = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GameHistoryRecord.fromJson({...data, 'id': doc.id});
      }).toList();
      
      // Filter by role if specified
      if (role != null) {
        records = records.where((record) => record.role == role).toList();
      }
      
      // Sort by date in memory
      records.sort((a, b) => b.playedAt.compareTo(a.playedAt));
      
      // Limit results
      if (records.length > limit) {
        records = records.take(limit).toList();
      }
      
      return records;
    }
  }

  /// Create game history record from completed game
  Future<void> createGameHistoryFromGame(Game game, String userId, String role) async {
    if (game.quiz?.title.isEmpty != false) return;

    final player = game.players.firstWhere(
      (p) => p.id == userId,
      orElse: () => Player(id: userId, name: 'Unknown', totalScore: 0, scores: []),
    );

    // Calculate player rank if playing
    int? playerRank;
    if (role == 'player') {
      final sortedPlayers = [...game.players]..sort((a, b) => b.totalScore.compareTo(a.totalScore));
      playerRank = sortedPlayers.indexWhere((p) => p.id == userId) + 1;
    }

    // Calculate accuracy percentage
    double? accuracyPercentage;
    if (role == 'player' && game.quiz != null) {
      final totalQuestions = game.quiz!.questions.length;
      final playerAnswers = game.playerAnswers[userId];
      if (playerAnswers != null && totalQuestions > 0) {
        int correctAnswers = 0;
        for (int i = 0; i < totalQuestions; i++) {
          final question = game.quiz!.questions[i];
          final playerAnswer = playerAnswers[i];
          if (playerAnswer == question.correctAnswerId) {
            correctAnswers++;
          }
        }
        accuracyPercentage = (correctAnswers / totalQuestions) * 100;
      }
    }

    final record = GameHistoryRecord(
      id: '${game.id}_$userId',
      gameId: game.id,
      userId: userId,
      quizId: game.quizId,
      quizTitle: game.quiz?.title ?? 'Unknown Quiz',
      role: role,
      playedAt: DateTime.now(),
      playerScore: role == 'player' ? player.totalScore : null,
      playerRank: playerRank,
      totalPlayers: game.players.length,
      totalQuestions: game.quiz?.questions.length ?? 0,
      accuracyPercentage: accuracyPercentage,
      gameDuration: DateTime.now().difference(game.startedAt),
      metadata: {
        'quizCategory': game.quiz?.title ?? 'General',
        'gameCode': game.id,
      },
    );

    await saveGameHistory(record);
  }

  /// Update user statistics based on game history
  Future<void> _updateUserStatistics(GameHistoryRecord record) async {
    final profileDoc = await userProfiles.doc(record.userId).get();
    if (!profileDoc.exists) return;

    final profile = UserProfile.fromJson({
      ...profileDoc.data() as Map<String, dynamic>,
      'id': record.userId,
    });

    final stats = profile.statistics;
    UserStatistics updatedStats;

    if (record.role == 'host') {
      updatedStats = stats.copyWith(
        totalGamesHosted: stats.totalGamesHosted + 1,
        totalPlayersHosted: stats.totalPlayersHosted + record.totalPlayers,
        lastActive: DateTime.now(),
      );
    } else {
      // Calculate new average score
      final totalScorePoints = (stats.averageScoreAsPlayer * stats.totalGamesPlayed) + (record.playerScore ?? 0);
      final newTotalGames = stats.totalGamesPlayed + 1;
      final newAverage = totalScorePoints / newTotalGames;

      // Update win streak
      int newCurrentStreak = stats.currentWinStreak;
      int newLongestStreak = stats.longestWinStreak;
      
      if (record.isWin) {
        newCurrentStreak += 1;
        if (newCurrentStreak > newLongestStreak) {
          newLongestStreak = newCurrentStreak;
        }
      } else {
        newCurrentStreak = 0;
      }

      updatedStats = stats.copyWith(
        totalGamesPlayed: newTotalGames,
        averageScoreAsPlayer: newAverage,
        bestScoreAsPlayer: math.max(stats.bestScoreAsPlayer, record.playerScore ?? 0),
        currentWinStreak: newCurrentStreak,
        longestWinStreak: newLongestStreak,
        lastActive: DateTime.now(),
      );
    }

    // Check for new achievements
    final newAchievements = await _checkForNewAchievements(updatedStats, record);
    if (newAchievements.isNotEmpty) {
      updatedStats = updatedStats.copyWith(
        achievements: [...stats.achievements, ...newAchievements],
      );
    }

    final updatedProfile = profile.copyWith(statistics: updatedStats);
    await updateUserProfile(updatedProfile);
  }

  /// Check for new achievements based on updated statistics
  Future<List<String>> _checkForNewAchievements(
    UserStatistics stats,
    GameHistoryRecord record,
  ) async {
    final newAchievements = <String>[];
    final existingAchievements = stats.achievements;

    // First game achievements
    if (stats.totalGamesPlayed == 1 && !existingAchievements.contains('first_game')) {
      newAchievements.add('first_game');
    }
    if (stats.totalGamesHosted == 1 && !existingAchievements.contains('first_host')) {
      newAchievements.add('first_host');
    }

    // Win streak achievements
    if (stats.currentWinStreak >= 3 && !existingAchievements.contains('win_streak_3')) {
      newAchievements.add('win_streak_3');
    }
    if (stats.currentWinStreak >= 5 && !existingAchievements.contains('win_streak_5')) {
      newAchievements.add('win_streak_5');
    }

    // Score achievements
    if (record.playerScore != null && record.playerScore! >= 1000 && !existingAchievements.contains('high_scorer')) {
      newAchievements.add('high_scorer');
    }

    // Perfect game achievement
    if (record.accuracyPercentage != null && record.accuracyPercentage! >= 100.0 && !existingAchievements.contains('perfect_game')) {
      newAchievements.add('perfect_game');
    }

    // Milestone achievements
    if (stats.totalGamesPlayed >= 10 && !existingAchievements.contains('veteran_player')) {
      newAchievements.add('veteran_player');
    }
    if (stats.totalGamesHosted >= 10 && !existingAchievements.contains('experienced_host')) {
      newAchievements.add('experienced_host');
    }

    return newAchievements;
  }

  /// Get leaderboard entries
  Future<List<LeaderboardEntry>> getLeaderboard({
    String category = 'global',
    int limit = 100,
  }) async {
    final snapshot = await leaderboards
        .doc(category)
        .collection('entries')
        .orderBy('score', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return LeaderboardEntry.fromJson({...data, 'userId': doc.id});
    }).toList();
  }

  /// Export user data (GDPR compliance)
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    final profile = await userProfiles.doc(userId).get();
    final history = await getUserGameHistory(userId, limit: 1000);

    return {
      'profile': profile.data(),
      'gameHistory': history.map((h) => h.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Delete user data (GDPR compliance)
  Future<void> deleteUserData(String userId) async {
    // Delete profile
    await userProfiles.doc(userId).delete();

    // Delete game history
    final historyQuery = await gameHistory.where('userId', isEqualTo: userId).get();
    final batch = _firestore.batch();
    for (final doc in historyQuery.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(String userId, {
    bool? sharePublicly,
    bool? saveHistory,
  }) async {
    final updates = <String, dynamic>{};
    if (sharePublicly != null) updates['sharePublicly'] = sharePublicly;
    if (saveHistory != null) updates['saveHistory'] = saveHistory;

    if (updates.isNotEmpty) {
      await userProfiles.doc(userId).update(updates);
    }
  }
}