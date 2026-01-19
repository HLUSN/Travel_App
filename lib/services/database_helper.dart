import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/trip.dart';
import '../models/destination.dart';
import '../models/notification.dart';
import '../models/review.dart';

// Web-specific import
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as sqflite_web;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const int _dbVersion = 2;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize database factory for web
    if (kIsWeb) {
      databaseFactory = sqflite_web.databaseFactoryFfiWeb;
    }

    String path = join(await getDatabasesPath(), 'travel_app.db');
    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrate(db, oldVersion, newVersion);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Users table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // Trips table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Destinations table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS destinations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        rating REAL NOT NULL,
        tripId INTEGER,
        FOREIGN KEY (tripId) REFERENCES trips (id)
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Reviews table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        comment TEXT NOT NULL,
        rating INTEGER NOT NULL,
        destinationId INTEGER,
        FOREIGN KEY (destinationId) REFERENCES destinations (id)
      )
    ''');
  }

  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createTables(db);

      final columns = await db.rawQuery('PRAGMA table_info(notifications)');
      Map<String, Object?>? userIdColumn;
      for (final column in columns) {
        if (column['name'] == 'userId') {
          userIdColumn = column;
          break;
        }
      }

      final userIdType = (userIdColumn?['type'] as String?)?.toUpperCase();
      if (userIdType != null && userIdType != 'INTEGER') {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS notifications_migration (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            message TEXT NOT NULL,
            type TEXT NOT NULL,
            userId INTEGER,
            FOREIGN KEY (userId) REFERENCES users (id)
          )
        ''');

        await db.execute('''
          INSERT INTO notifications_migration (id, message, type, userId)
          SELECT id, message, type,
                 CASE
                   WHEN userId IS NULL OR TRIM(userId) = '' THEN NULL
                   ELSE CAST(userId AS INTEGER)
                 END
          FROM notifications
        ''');

        await db.execute('DROP TABLE IF EXISTS notifications');
        await db.execute(
          'ALTER TABLE notifications_migration RENAME TO notifications',
        );
      }
    }
  }

  // User CRUD operations
  Future<int> insertUser(Users user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<Users>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => Users.fromMap(maps[i]));
  }

  Future<Users?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return Users.fromMap(maps.first);
    }
    return null;
  }

  // Authentication method
  Future<Users?> authenticateUser(String email, String password) async {
    final user = await getUserByEmail(email);
    if (user != null && user.login(password)) {
      return user;
    }
    return null;
  }

  // Trip CRUD operations
  Future<int> insertTrip(Trip trip) async {
    final db = await database;
    return await db.insert('trips', trip.toMap());
  }

  Future<List<Trip>> getTrips() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('trips');
    return List.generate(maps.length, (i) => Trip.fromMap(maps[i]));
  }

  Future<List<Trip>> getTripsByUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'trips',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Trip.fromMap(maps[i]));
  }

  Future<void> updateTrip(Trip trip) async {
    final db = await database;
    await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<void> deleteTrip(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete associated destinations first to avoid foreign key constraint errors
      await txn.delete('destinations', where: 'tripId = ?', whereArgs: [id]);
      await txn.delete('trips', where: 'id = ?', whereArgs: [id]);
    });
  }

  // Destination CRUD operations
  Future<int> insertDestination(Destination destination) async {
    final db = await database;
    return await db.insert('destinations', destination.toMap());
  }

  Future<List<Destination>> getDestinations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('destinations');
    return List.generate(maps.length, (i) => Destination.fromMap(maps[i]));
  }

  Future<List<Destination>> getDestinationsByTrip(int tripId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'destinations',
      where: 'tripId = ?',
      whereArgs: [tripId],
    );
    return List.generate(maps.length, (i) => Destination.fromMap(maps[i]));
  }

  Future<void> updateDestination(Destination destination) async {
    final db = await database;
    await db.update(
      'destinations',
      destination.toMap(),
      where: 'id = ?',
      whereArgs: [destination.id],
    );
  }

  Future<void> deleteDestination(int id) async {
    final db = await database;
    await db.delete('destinations', where: 'id = ?', whereArgs: [id]);
  }

  // Notification CRUD operations
  Future<int> insertNotification(AppNotification notification) async {
    final db = await database;
    return await db.insert('notifications', notification.toMap());
  }

  Future<List<AppNotification>> getNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notifications');
    return List.generate(maps.length, (i) => AppNotification.fromMap(maps[i]));
  }

  Future<List<AppNotification>> getNotificationsByUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => AppNotification.fromMap(maps[i]));
  }

  // Review CRUD operations
  Future<int> insertReview(Review review) async {
    final db = await database;
    return await db.insert('reviews', review.toMap());
  }

  Future<List<Review>> getReviews() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('reviews');
    return List.generate(maps.length, (i) => Review.fromMap(maps[i]));
  }

  Future<List<Review>> getReviewsByDestination(int destinationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reviews',
      where: 'destinationId = ?',
      whereArgs: [destinationId],
    );
    return List.generate(maps.length, (i) => Review.fromMap(maps[i]));
  }

  Future<void> updateReview(Review review) async {
    final db = await database;
    await db.update(
      'reviews',
      review.toMap(),
      where: 'id = ?',
      whereArgs: [review.id],
    );
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
