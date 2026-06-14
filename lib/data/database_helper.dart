/// database_helper.dart
/// Location: lib/data/database_helper.dart
///
/// SQLite database helper for Shredded Squad.
/// Implements full CRUD operations for Member records.
///
/// Add to pubspec.yaml:
///   sqflite: ^2.3.2
///   path: ^1.9.0

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/member_model.dart';

class DatabaseHelper {
  // ─── Singleton pattern ────────────────────────────────────────────────────
  // Only one database instance exists throughout the app lifecycle
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Returns the database, initialising it on first access.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shredded_squad.db');
    return _database!;
  }

  // ─── Initialise database ──────────────────────────────────────────────────

  Future<Database> _initDB(String fileName) async {
    // Get the platform-appropriate path for the database file
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB, // called only the very first time
    );
  }

  /// Creates the members table on first run.
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE members (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT    NOT NULL,
        email       TEXT    NOT NULL UNIQUE,
        phone       TEXT,
        height      REAL,
        weight      REAL,
        targetWeight REAL,
        activityLevel TEXT  NOT NULL DEFAULT 'Beginner',
        joinDate    TEXT    NOT NULL,
        goal        TEXT
      )
    ''');
  }

  // ─── CREATE ───────────────────────────────────────────────────────────────

  /// Inserts a new member and returns the auto-generated id.
  Future<int> insertMember(Member member) async {
    final db = await database;
    return await db.insert(
      'members',
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort, // fail on duplicate email
    );
  }

  // ─── READ — all ───────────────────────────────────────────────────────────

  /// Returns all members ordered by name A→Z.
  Future<List<Member>> getAllMembers() async {
    final db = await database;
    final maps = await db.query(
      'members',
      orderBy: 'name ASC',
    );
    return maps.map((m) => Member.fromMap(m)).toList();
  }

  // ─── READ — single ────────────────────────────────────────────────────────

  /// Returns a single member by id, or null if not found.
  Future<Member?> getMemberById(int id) async {
    final db = await database;
    final maps = await db.query(
      'members',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Member.fromMap(maps.first);
  }

  // ─── SEARCH ───────────────────────────────────────────────────────────────

  /// Searches members by name OR email containing [query] (case-insensitive).
  Future<List<Member>> searchMembers(String query) async {
    final db = await database;
    final pattern = '%${query.toLowerCase()}%';
    final maps = await db.rawQuery(
      '''
      SELECT * FROM members
      WHERE LOWER(name) LIKE ? OR LOWER(email) LIKE ?
      ORDER BY name ASC
      ''',
      [pattern, pattern],
    );
    return maps.map((m) => Member.fromMap(m)).toList();
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────

  /// Updates an existing member record. Returns number of rows affected.
  Future<int> updateMember(Member member) async {
    final db = await database;
    return await db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────

  /// Deletes a member by id. Returns number of rows deleted.
  Future<int> deleteMember(int id) async {
    final db = await database;
    return await db.delete(
      'members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns the total number of members in the database.
  Future<int> getMemberCount() async {
    final db = await database;
    final result =
    await db.rawQuery('SELECT COUNT(*) as count FROM members');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ─── Close ────────────────────────────────────────────────────────────────

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}