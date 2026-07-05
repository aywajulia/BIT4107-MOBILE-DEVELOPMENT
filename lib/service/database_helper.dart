/// database_helper.dart
/// Location: lib/service/database_helper.dart
library;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import '../model/meal_entry.dart';
import '../model/dashboard_models.dart';

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
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
        createdAt TEXT,
        profileImage TEXT
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
        loggedAt TEXT,
        loggedDate TEXT,
        quantity REAL,
        source TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE activities(
        id TEXT PRIMARY KEY,
        name TEXT,
        caloriesBurned INTEGER,
        durationMinutes INTEGER,
        loggedAt TEXT,
        distance REAL,
        pace REAL,
        route TEXT
      )
    ''');

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
    }
    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE activities ADD COLUMN distance REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE activities ADD COLUMN pace REAL'); } catch (_) {}
    }
    if (oldVersion < 6) {
      try { await db.execute('ALTER TABLE activities ADD COLUMN route TEXT'); } catch (_) {}
    }
  }

  // Users
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

  // Meals
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

  // Activities
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

  // Custom Foods
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

  Future<int> deleteCustomFood(int id) async {
    final db = await database;
    return await db.delete('custom_foods', where: 'id = ?', whereArgs: [id]);
  }

  // Delete Account
  Future<void> deleteUser(String uid) async {
    final db = await database;
    await db.delete('users', where: 'uid = ?', whereArgs: [uid]);
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('meals');
    await db.delete('activities');
    await db.delete('custom_foods');
  }
}