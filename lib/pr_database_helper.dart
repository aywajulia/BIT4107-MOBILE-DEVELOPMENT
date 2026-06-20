/// pr_database_helper.dart
/// Location: lib/data/pr_database_helper.dart
/// SQLite helper for Personal Records.
/// Provides full CRUD — insert, getAll, search, update, delete.
library;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../personal_record_model.dart';

class PRDatabaseHelper {
  // Singleton — only one DB instance throughout the app
  static final PRDatabaseHelper instance = PRDatabaseHelper._init();
  static Database? _db;
  PRDatabaseHelper._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  // ── Initialise ─────────────────────────────────────────────────────────────

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'pr_records.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  /// Called once on first run — creates the table
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE personal_records (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise TEXT    NOT NULL,
        value    REAL    NOT NULL,
        unit     TEXT    NOT NULL,
        date     TEXT    NOT NULL,
        notes    TEXT
      )
    ''');
  }

  // ── CREATE ─────────────────────────────────────────────────────────────────

  Future<int> insertPR(PersonalRecord pr) async {
    final db = await database;
    return db.insert('personal_records', pr.toMap());
  }

  // ── READ — all ─────────────────────────────────────────────────────────────

  Future<List<PersonalRecord>> getAllPRs() async {
    final db = await database;
    final rows = await db.query('personal_records', orderBy: 'date DESC');
    return rows.map(PersonalRecord.fromMap).toList();
  }

  // ── SEARCH ─────────────────────────────────────────────────────────────────

  /// Returns records whose exercise name contains [query]
  Future<List<PersonalRecord>> searchPRs(String query) async {
    final db = await database;
    final rows = await db.query(
      'personal_records',
      where: 'LOWER(exercise) LIKE ?',
      whereArgs: ['%${query.toLowerCase()}%'],
      orderBy: 'date DESC',
    );
    return rows.map(PersonalRecord.fromMap).toList();
  }

  // ── UPDATE ─────────────────────────────────────────────────────────────────

  Future<int> updatePR(PersonalRecord pr) async {
    final db = await database;
    return db.update(
      'personal_records',
      pr.toMap(),
      where: 'id = ?',
      whereArgs: [pr.id],
    );
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────

  Future<int> deletePR(int id) async {
    final db = await database;
    return db.delete(
      'personal_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}