/// database_helper.dart
/// Location: lib/database_helper.dart
///
/// Main SQLite helper for Users, Meals, and Activities.
library;

import 'package:sqflite/sqflite.dart'; // ignore: library_prefixes
import 'package:path/path.dart' as path;
import 'dashboard_model.dart';   // ✅ Fixed: was 'dashboard_model.dart' (plural)

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, 'shredded_squad.db');

    return await openDatabase(
      fullPath,
      version: 2,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT UNIQUE,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        height TEXT,
        weight TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE meals(
        id TEXT PRIMARY KEY,
        name TEXT,
        mealType TEXT,
        calories INTEGER,
        protein REAL,
        carbs REAL,
        fat REAL,
        loggedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE activities(
        id TEXT PRIMARY KEY,
        name TEXT,
        caloriesBurned INTEGER,
        durationMinutes INTEGER,
        loggedAt TEXT
      )
    ''');
  }

  // ──────────────────────────────────────────────
  // USERS
  // ──────────────────────────────────────────────

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<Map<String, dynamic>?> getUserByUid(String uid) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<int> updateUser(String uid, Map<String, dynamic> updates) async {
    final db = await database;
    return await db.update(
      'users',
      updates,
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  // ──────────────────────────────────────────────
  // MEALS
  // ──────────────────────────────────────────────

  Future<void> insertMeal(MealEntry meal) async {
    final db = await database;
    await db.insert('meals', meal.toMap());
  }

  Future<List<MealEntry>> getAllMeals() async {
    final db = await database;
    final result = await db.query('meals', orderBy: 'loggedAt DESC');
    return result.map((map) => MealEntry.fromMap(map)).toList();
  }

  Future<void> deleteMeal(String id) async {
    final db = await database;
    await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllMeals() async {
    final db = await database;
    await db.delete('meals');
  }

  // ──────────────────────────────────────────────
  // ACTIVITIES
  // ──────────────────────────────────────────────

  Future<void> insertActivity(ActivityEntry activity) async {
    final db = await database;
    await db.insert('activities', activity.toMap());
  }

  Future<List<ActivityEntry>> getAllActivities() async {
    final db = await database;
    final result = await db.query('activities', orderBy: 'loggedAt DESC');
    return result.map((map) => ActivityEntry.fromMap(map)).toList();
  }

  Future<void> deleteActivity(String id) async {
    final db = await database;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllActivities() async {
    final db = await database;
    await db.delete('activities');
  }
}