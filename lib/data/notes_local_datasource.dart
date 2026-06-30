import 'package:sqflite/sqflite.dart';

import '../models/note.dart';
import '../models/pending_operation.dart';
import 'database_helper.dart';

class NotesLocalDataSource {
  NotesLocalDataSource(this._dbHelper);

  final DatabaseHelper _dbHelper;

  Future<List<Note>> getAllNotes() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'notes',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'local_updated_at DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<Note?> getNote(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Note.fromMap(rows.first);
  }

  Future<void> upsertNote(Note note) async {
    final db = await _dbHelper.database;
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteNotePermanently(String id) async {
    final db = await _dbHelper.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PendingOperation>> getPendingOperations() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'pending_operations',
      orderBy: 'created_at ASC',
    );
    return rows.map(PendingOperation.fromMap).toList();
  }

  Future<PendingOperation?> getPendingOperationForNote(String noteId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'pending_operations',
      where: 'note_id = ?',
      whereArgs: [noteId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PendingOperation.fromMap(rows.first);
  }

  Future<void> enqueueOperation(PendingOperation operation) async {
    final db = await _dbHelper.database;
    await removePendingOperationsForNote(operation.noteId);
    await db.insert('pending_operations', {
      'note_id': operation.noteId,
      'type': operation.type.name,
      'created_at': operation.createdAt.toIso8601String(),
      'force_push': operation.forcePush ? 1 : 0,
    });
  }

  Future<void> removePendingOperation(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'pending_operations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removePendingOperationsForNote(String noteId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'pending_operations',
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
  }
}
