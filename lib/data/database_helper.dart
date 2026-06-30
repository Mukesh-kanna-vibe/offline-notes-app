import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'offline_notes.db';
  static const _dbVersion = 3;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        local_updated_at TEXT NOT NULL,
        server_updated_at TEXT,
        sync_status TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        synced_title TEXT,
        synced_body TEXT,
        server_title TEXT,
        server_body TEXT,
        server_version_at_conflict TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_id TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        force_push INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN synced_title TEXT');
      await db.execute('ALTER TABLE notes ADD COLUMN synced_body TEXT');
      await db.execute('''
        UPDATE notes
        SET synced_title = title, synced_body = body
        WHERE sync_status = 'synced'
      ''');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE pending_operations ADD COLUMN force_push INTEGER NOT NULL DEFAULT 0',
      );
    }
  }
}
