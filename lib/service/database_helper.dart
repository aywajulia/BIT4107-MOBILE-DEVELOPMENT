/// database_helper.dart
/// Main SQLite helper for Shredded Squad.
/// Manages all local data persistence.
/// Tables:
///   - users:          authentication, profile, profileImage
///   - meals:          extended with mealType, quantity, source, loggedDate
///   - activities:     workout logs with caloriesBurned, duration
///   - custom_foods:   user‑defined local foods (East African / custom)
/// Version history:
///   v1 – initial (users, meals, activities)
///   v2 – added profileImage to users
///   v3 – added loggedDate, quantity, source to meals + custom_foods table
///   v4 – (current) ensures all columns exist and handles upgrades cleanly

library;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../model/meal_entry.dart';        // extended MealEntry
import '../model/dashboard_model.dart';  // ActivityEntry, StepData

class DatabaseHelper {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // ─── Initialise ─────────────────────────────────────────────────────────────

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final fullPath = path.join(dbPath, 'shredded_squad.db');

    return await openDatabase(
      fullPath,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Called when the database is created from scratch (first run).
  Future<void> _onCreate(Database db, int version) async {
    // ─── Users table (includes profileImage) ──────────────────────────────
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

    // ─── Meals table (extended) ──────────────────────────────────────────
    await db.execute('''
      CREATE TABLE meals(
        id TEXT PRIMARY KEY,
        name TEXT,
        mealType TEXT,          -- 'breakfast', 'lunch', 'dinner', 'snack'
        calories INTEGER,
        protein REAL,
        carbs REAL,
        fat REAL,
        loggedAt TEXT,          -- full timestamp
        loggedDate TEXT,        -- YYYY-MM-DD for grouping
        quantity REAL,          -- grams consumed
        source TEXT             -- 'api' or 'custom'
      )
    ''');

    // ─── Activities table ─────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE activities(
        id TEXT PRIMARY KEY,
        name TEXT,
        caloriesBurned INTEGER,
        durationMinutes INTEGER,
        loggedAt TEXT
      )
    ''');

    // ─── Custom Foods table ──────────────────────────────────────────────
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
  /// Called when upgrading from an older version to a newer one.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add profileImage column to users (originally added in v2)
      try {
        await db.execute('ALTER TABLE users ADD COLUMN profileImage TEXT');
      } catch (_) {} // column already exists
    }
    if (oldVersion < 3) {
      // Add extended columns to meals (v3)
      try {
        await db.execute('ALTER TABLE meals ADD COLUMN loggedDate TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE meals ADD COLUMN quantity REAL');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE meals ADD COLUMN source TEXT');
      } catch (_) {}
      // Create custom_foods table (v3)
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
  }
  // USERS (CRUD)
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
    return result.isNotEmpty ? result.first : null;
  }
  Future<Map<String, dynamic>?> getUserByUid(String uid) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    return result.isNotEmpty ? result.first : null;
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
   // MEALS (extended CRUD)
    Future<void> insertMeal(MealEntry meal) async {
    final db = await database;
    await db.insert('meals', meal.toMap());
  }
  Future<List<MealEntry>> getAllMeals() async {
    final db = await database;
    final result = await db.query('meals', orderBy: 'loggedAt DESC');
    return result.map((map) => MealEntry.fromMap(map)).toList();
  }
  Future<List<MealEntry>> getMealsByDate(String date) async {
    final db = await database;
    final result = await db.query(
      'meals',
      where: 'loggedDate = ?',
      whereArgs: [date],
      orderBy: 'loggedAt ASC',
    );
    return result.map((map) => MealEntry.fromMap(map)).toList();
  }
  Future<List<MealEntry>> getMealsBetween(DateTime start, DateTime end) async {
    final db = await database;
    final startKey = start.toIso8601String().split('T').first;
    final endKey = end.toIso8601String().split('T').first;
    final result = await db.query(
      'meals',
      where: 'loggedDate >= ? AND loggedDate <= ?',
      whereArgs: [startKey, endKey],
      orderBy: 'loggedAt DESC',
    );
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
   // ACTIVITIES (CRUD)
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
    // CUSTOM FOODS (CRUD)
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
    final result = await db.query(
      'custom_foods',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }
  Future<int> deleteCustomFood(int id) async {
    final db = await database;
    return await db.delete(
      'custom_foods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  /// Delete all custom foods (use with caution).
  Future<void> deleteAllCustomFoods() async {
    final db = await database;
    await db.delete('custom_foods');
  }
}