import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/image_analysis.dart';

/// Local SQLite cache of image history. This mirrors the backend's Postgres
/// table so the History screen can render instantly from disk and still work
/// (read-only, for previously-synced items) when the device is offline.
///
/// Schema intentionally matches the shape given in the project spec:
///   image_history(id, image_path, image_thumbnail, description,
///                 detected_objects, user_questions, confidence_score,
///                 created_at, updated_at)
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_image_analyst.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE image_history (
            id TEXT PRIMARY KEY,
            image_thumbnail TEXT,
            description TEXT,
            detected_objects TEXT,
            detected_text TEXT,
            user_questions TEXT,
            confidence_score REAL,
            confidence_band TEXT,
            is_demo_mode INTEGER DEFAULT 0,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
      },
    );
  }

  Future<void> upsert(ImageAnalysis analysis) async {
    final db = await database;
    final map = analysis.toDbMap();
    map['updated_at'] = DateTime.now().toIso8601String();
    await db.insert('image_history', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ImageAnalysis>> getAll() async {
    final db = await database;
    final rows = await db.query('image_history', orderBy: 'created_at DESC');
    return rows.map(ImageAnalysis.fromDbMap).toList();
  }

  Future<void> delete(String id) async {
    final db = await database;
    await db.delete('image_history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('image_history');
  }
}
