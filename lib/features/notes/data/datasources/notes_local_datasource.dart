import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/db_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/note_entities.dart';
import '../datasources/database_helper.dart';
import '../models/note_model.dart';

class NotesLocalDataSource {
  NotesLocalDataSource(this._databaseHelper);

  final DatabaseHelper _databaseHelper;

  Future<List<NoteModel>> getNotes({
    String? searchQuery,
    NoteSortOption sortOption = NoteSortOption.createdAtDesc,
    bool includeDeleted = false,
  }) async {
    try {
      final db = await _databaseHelper.database;
      final whereClauses = <String>[];
      final whereArgs = <Object?>[];

      if (!includeDeleted) {
        whereClauses.add('${DbConstants.colIsDeleted} = ?');
        whereArgs.add(0);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        whereClauses.add(
          '(${DbConstants.colTitle} LIKE ? OR ${DbConstants.colBody} LIKE ?)',
        );
        final term = '%${searchQuery.trim()}%';
        whereArgs.addAll([term, term]);
      }

      final result = await db.query(
        DbConstants.notesTable,
        where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        orderBy: _orderByClause(sortOption),
      );

      return result.map(NoteModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to read notes: $error');
    }
  }

  Stream<List<NoteModel>> watchNotes({
    String? searchQuery,
    NoteSortOption sortOption = NoteSortOption.createdAtDesc,
  }) async* {
    while (true) {
      yield await getNotes(
        searchQuery: searchQuery,
        sortOption: sortOption,
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<NoteModel?> getNoteById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        DbConstants.notesTable,
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return NoteModel.fromMap(result.first);
    } catch (error) {
      throw CacheException('Failed to read note: $error');
    }
  }

  Future<NoteModel?> getNoteByServerId(String serverId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        DbConstants.notesTable,
        where: '${DbConstants.colServerId} = ?',
        whereArgs: [serverId],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return NoteModel.fromMap(result.first);
    } catch (error) {
      throw CacheException('Failed to read note by server id: $error');
    }
  }

  Future<void> insertNote(NoteModel note) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        DbConstants.notesTable,
        note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error) {
      throw CacheException('Failed to insert note: $error');
    }
  }

  Future<void> updateNote(NoteModel note) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        DbConstants.notesTable,
        note.toMap(),
        where: '${DbConstants.colId} = ?',
        whereArgs: [note.id],
      );
    } catch (error) {
      throw CacheException('Failed to update note: $error');
    }
  }

  Future<void> deleteNotePermanently(String id) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        DbConstants.notesTable,
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
      );
    } catch (error) {
      throw CacheException('Failed to delete note: $error');
    }
  }

  Future<List<NoteModel>> getConflictedNotes() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        DbConstants.notesTable,
        where: '${DbConstants.colSyncStatus} = ? AND ${DbConstants.colIsDeleted} = ?',
        whereArgs: [SyncStatus.conflict.name, 0],
        orderBy: '${DbConstants.colUpdatedAt} DESC',
      );
      return result.map(NoteModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to read conflicted notes: $error');
    }
  }

  String _pendingFirstClause() {
    return '''
CASE ${DbConstants.colSyncStatus}
  WHEN '${SyncStatus.conflict.name}' THEN 0
  WHEN '${SyncStatus.pending.name}' THEN 1
  ELSE 2
END ASC''';
  }

  String _orderByClause(NoteSortOption sortOption) {
    final pendingFirst = _pendingFirstClause();

    switch (sortOption) {
      case NoteSortOption.updatedAtDesc:
        return '$pendingFirst, ${DbConstants.colUpdatedAt} DESC, ${DbConstants.colCreatedAt} DESC';
      case NoteSortOption.updatedAtAsc:
        return '$pendingFirst, ${DbConstants.colUpdatedAt} ASC, ${DbConstants.colCreatedAt} ASC';
      case NoteSortOption.titleAsc:
        return '$pendingFirst, ${DbConstants.colTitle} COLLATE NOCASE ASC';
      case NoteSortOption.titleDesc:
        return '$pendingFirst, ${DbConstants.colTitle} COLLATE NOCASE DESC';
      case NoteSortOption.createdAtDesc:
        return '$pendingFirst, ${DbConstants.colCreatedAt} DESC, ${DbConstants.colUpdatedAt} DESC';
    }
  }
}
