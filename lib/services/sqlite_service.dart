import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quiz.dart';

/// Service for managing local SQLite database operations
class SQLiteService {
  static Database? _database;

  /// Get the database instance
  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web platform');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web platform');
    }
    final path = join(await getDatabasesPath(), 'quizarena.db');
    return await openDatabase(path, version: 1, onCreate: _createTables);
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web platform');
    }
    await db.execute('''
      CREATE TABLE quizzes(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        createdBy TEXT NOT NULL,
        questions TEXT NOT NULL, -- JSON string
        createdAt TEXT NOT NULL
      )
    ''');
  }

  /// Get all quizzes from local storage
  Future<List<Quiz>> getQuizzes() async {
    if (kIsWeb) {
      debugPrint('SQLite not supported on web, returning empty list');
      return [];
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('quizzes');
    debugPrint('Found ${maps.length} quizzes in database');
    final quizzes = List.generate(maps.length, (i) {
      try {
        final quiz = Quiz.fromJson(maps[i]);
        debugPrint('Loaded quiz: ${quiz.title}');
        return quiz;
      } catch (e) {
        debugPrint('Error loading quiz at index $i: $e');
        return null;
      }
    }).where((quiz) => quiz != null).cast<Quiz>().toList();
    debugPrint('Successfully loaded ${quizzes.length} quizzes');
    return quizzes;
  }

  /// Insert a quiz into local storage
  Future<void> insertQuiz(Quiz quiz) async {
    if (kIsWeb) {
      debugPrint('SQLite not supported on web, quiz not saved locally');
      return;
    }
    final db = await database;
    debugPrint('Inserting quiz: ${quiz.title}');
    debugPrint('Quiz JSON: ${quiz.toJson()}');
    await db.insert(
      'quizzes',
      quiz.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('Quiz inserted successfully');
  }

  /// Update a quiz in local storage
  Future<void> updateQuiz(Quiz quiz) async {
    if (kIsWeb) {
      debugPrint('SQLite not supported on web, quiz not updated locally');
      return;
    }
    final db = await database;
    await db.update(
      'quizzes',
      quiz.toJson(),
      where: 'id = ?',
      whereArgs: [quiz.id],
    );
  }

  /// Delete a quiz from local storage
  Future<void> deleteQuiz(String id) async {
    if (kIsWeb) {
      debugPrint('SQLite not supported on web, quiz not deleted locally');
      return;
    }
    final db = await database;
    await db.delete('quizzes', where: 'id = ?', whereArgs: [id]);
  }

  /// Close the database
  Future<void> close() async {
    if (kIsWeb) {
      debugPrint('SQLite not supported on web, no database to close');
      return;
    }
    final db = await database;
    db.close();
  }
}
