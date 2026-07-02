import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/db_constants.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DbConstants.databaseName);

    return openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS ${DbConstants.syncQueueTable}');
      await db.execute('DROP TABLE IF EXISTS ${DbConstants.notesTable}');
      await _onCreate(db, newVersion);
      return;
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE ${DbConstants.notesTable} '
        'ADD COLUMN ${DbConstants.colServerId} TEXT',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE ${DbConstants.notesTable} '
        'ADD COLUMN ${DbConstants.colConflictLocalTitle} TEXT',
      );
      await db.execute(
        'ALTER TABLE ${DbConstants.notesTable} '
        'ADD COLUMN ${DbConstants.colConflictLocalBody} TEXT',
      );
      await db.execute(
        'ALTER TABLE ${DbConstants.notesTable} '
        'ADD COLUMN ${DbConstants.colConflictLocalUpdatedAt} TEXT',
      );
      await db.execute(
        'ALTER TABLE ${DbConstants.notesTable} '
        'ADD COLUMN ${DbConstants.colConflictRemoteTitle} TEXT',
      );
      await db.execute(
        'ALTER TABLE ${DbConstants.notesTable} '
        'ADD COLUMN ${DbConstants.colConflictRemoteBody} TEXT',
      );
      await db.execute(
        'ALTER TABLE ${DbConstants.notesTable} '
        'ADD COLUMN ${DbConstants.colConflictRemoteUpdatedAt} TEXT',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE ${DbConstants.notesTable} '
        'ADD COLUMN ${DbConstants.colSyncBaseTitle} TEXT',
      );
      await db.execute(
        'ALTER TABLE ${DbConstants.notesTable} '
        'ADD COLUMN ${DbConstants.colSyncBaseBody} TEXT',
      );
      await db.execute(
        'ALTER TABLE ${DbConstants.notesTable} '
        'ADD COLUMN ${DbConstants.colSyncBaseIsDeleted} INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('''
        UPDATE ${DbConstants.notesTable}
        SET ${DbConstants.colSyncBaseTitle} = ${DbConstants.colTitle},
            ${DbConstants.colSyncBaseBody} = ${DbConstants.colBody},
            ${DbConstants.colSyncBaseIsDeleted} = ${DbConstants.colIsDeleted}
        WHERE ${DbConstants.colSyncBaseTitle} IS NULL
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.notesTable} (
        ${DbConstants.colId} TEXT PRIMARY KEY,
        ${DbConstants.colTitle} TEXT NOT NULL,
        ${DbConstants.colBody} TEXT NOT NULL,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        ${DbConstants.colUpdatedAt} TEXT NOT NULL,
        ${DbConstants.colSyncStatus} TEXT NOT NULL,
        ${DbConstants.colIsDeleted} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colRemoteUpdatedAt} TEXT,
        ${DbConstants.colServerId} TEXT,
        ${DbConstants.colConflictLocalTitle} TEXT,
        ${DbConstants.colConflictLocalBody} TEXT,
        ${DbConstants.colConflictLocalUpdatedAt} TEXT,
        ${DbConstants.colConflictRemoteTitle} TEXT,
        ${DbConstants.colConflictRemoteBody} TEXT,
        ${DbConstants.colConflictRemoteUpdatedAt} TEXT,
        ${DbConstants.colSyncBaseTitle} TEXT,
        ${DbConstants.colSyncBaseBody} TEXT,
        ${DbConstants.colSyncBaseIsDeleted} INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.syncQueueTable} (
        ${DbConstants.colId} TEXT PRIMARY KEY,
        ${DbConstants.colNoteId} TEXT NOT NULL,
        ${DbConstants.colOperationType} TEXT NOT NULL,
        ${DbConstants.colPayload} TEXT NOT NULL,
        ${DbConstants.colRetryCount} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colQueueCreatedAt} TEXT NOT NULL,
        ${DbConstants.colLastAttemptAt} TEXT,
        ${DbConstants.colErrorMessage} TEXT,
        FOREIGN KEY (${DbConstants.colNoteId})
          REFERENCES ${DbConstants.notesTable} (${DbConstants.colId})
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_notes_updated_at
      ON ${DbConstants.notesTable} (${DbConstants.colUpdatedAt})
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_queue_created_at
      ON ${DbConstants.syncQueueTable} (${DbConstants.colQueueCreatedAt})
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
