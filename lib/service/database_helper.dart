/// database_helper.dart
/// Main SQLite helper – version 5 includes distance/pace for activities
/// and the custom_foods table with full CRUD.

library;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../model/meal_entry.dart';
import '../model/dashboard_model.dart';

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
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ─── Users table ────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT UNIQUE,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        height TEXT,
        weight TEXT,
        createdAt TEXT,
        profileImage TEXT
      )
    ''');

    // ─── Meals table ──────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE meals(
        id TEXT PRIMARY KEY,
        name TEXT,
        mealType TEXT,
        calories INTEGER,
        protein REAL,
        carbs REAL,
        fat REAL,
        loggedAt TEXT,
        loggedDate TEXT,
        quantity REAL,
        source TEXT
      )
    ''');

    // ─── Activities table (with distance/pace) ─────────────────────
    await db.execute('''
      CREATE TABLE activities(
        id TEXT PRIMARY KEY,
        name TEXT,
        caloriesBurned INTEGER,
        durationMinutes INTEGER,
        loggedAt TEXT,
        distance REAL,
        pace REAL
      )
    ''');

    // ─── Custom Foods table ──────────────────────────────────────────
    await db.execute('''
      CREATE TABLE custom_foods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        caloriesPer100g INTEGER NOT NULL,
        protein REAL,
        carbs REAL,
        fat REAL,
        category TEXT,
        createdAt TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try { await db.execute('ALTER TABLE users ADD COLUMN profileImage TEXT'); } catch (_) {}
    }
    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE meals ADD COLUMN loggedDate TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE meals ADD COLUMN quantity REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE meals ADD COLUMN source TEXT'); } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_foods(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          caloriesPer100g INTEGER NOT NULL,
          protein REAL,
          carbs REAL,
          fat REAL,
          category TEXT,
          createdAt TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE activities ADD COLUMN distance REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE activities ADD COLUMN pace REAL'); } catch (_) {}
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // USERS
  // ──────────────────────────────────────────────────────────────────

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserByUid(String uid) async {
    final db = await database;
    final result = await db.query('users', where: 'uid = ?', whereArgs: [uid]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUser(String uid, Map<String, dynamic> updates) async {
    final db = await database;
    return await db.update('users', updates, where: 'uid = ?', whereArgs: [uid]);
  }

  // ──────────────────────────────────────────────────────────────────
  // MEALS
  // ──────────────────────────────────────────────────────────────────

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

  // ──────────────────────────────────────────────────────────────────
  // ACTIVITIES
  // ──────────────────────────────────────────────────────────────────

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

  // ──────────────────────────────────────────────────────────────────
  // CUSTOM FOODS
  // ──────────────────────────────────────────────────────────────────

  Future<int> insertCustomFood(Map<String, dynamic> food) async {
    final db = await database;
    return await db.insert('custom_foods', food);
  }

  Future<List<Map<String, dynamic>>> getAllCustomFoods() async {
    final db = await database;
    return await db.query('custom_foods', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> searchCustomFoods(String query) async {
    final db = await database;
    return await db.query(
      'custom_foods',
      where: 'LOWER(name) LIKE ?',
      whereArgs: ['%${query.toLowerCase()}%'],
      orderBy: 'name ASC',
    );
  }

  Future<Map<String, dynamic>?> getCustomFoodById(int id) async {
    final db = await database;
    final result = await db.query('custom_foods', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> deleteCustomFood(int id) async {
    final db = await database;
    return await db.delete('custom_foods', where: 'id = ?', whereArgs: [id]);
  }
}