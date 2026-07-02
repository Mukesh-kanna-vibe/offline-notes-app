import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/db_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../datasources/database_helper.dart';
import '../models/note_model.dart';

class SyncQueueLocalDataSource {
  SyncQueueLocalDataSource(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  Future<List<SyncQueueItemModel>> getPendingOperations() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        DbConstants.syncQueueTable,
        orderBy: '${DbConstants.colQueueCreatedAt} ASC',
      );
      return result.map(SyncQueueItemModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to read sync queue: $error');
    }
  }

  Future<void> enqueue(SyncQueueItemModel item) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        DbConstants.syncQueueTable,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error) {
      throw CacheException('Failed to enqueue operation: $error');
    }
  }

  Future<void> removeById(String id) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        DbConstants.syncQueueTable,
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
      );
    } catch (error) {
      throw CacheException('Failed to remove queue item: $error');
    }
  }

  Future<void> removeByNoteId(String noteId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        DbConstants.syncQueueTable,
        where: '${DbConstants.colNoteId} = ?',
        whereArgs: [noteId],
      );
    } catch (error) {
      throw CacheException('Failed to clear queue for note: $error');
    }
  }

  Future<void> updateQueueItem(SyncQueueItemModel item) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        DbConstants.syncQueueTable,
        item.toMap(),
        where: '${DbConstants.colId} = ?',
        whereArgs: [item.id],
      );
    } catch (error) {
      throw CacheException('Failed to update queue item: $error');
    }
  }

  Future<SyncQueueItemModel?> getLatestOperationForNote(String noteId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        DbConstants.syncQueueTable,
        where: '${DbConstants.colNoteId} = ?',
        whereArgs: [noteId],
        orderBy: '${DbConstants.colQueueCreatedAt} DESC',
        limit: 1,
      );
      if (result.isEmpty) return null;
      return SyncQueueItemModel.fromMap(result.first);
    } catch (error) {
      throw CacheException('Failed to read queue item: $error');
    }
  }
}
