import 'package:uuid/uuid.dart';

import '../data/notes_local_datasource.dart';
import '../models/note.dart';
import '../models/pending_operation.dart';
import '../models/sync_status.dart';

class NotesRepository {
  NotesRepository(this._localDataSource);

  final NotesLocalDataSource _localDataSource;
  final _uuid = const Uuid();

  Future<List<Note>> getAllNotes() => _localDataSource.getAllNotes();

  Future<Note?> getNote(String id) => _localDataSource.getNote(id);

  Future<PendingOperation?> getPendingOperationForNote(String noteId) {
    return _localDataSource.getPendingOperationForNote(noteId);
  }

  Future<Note> createNote({required String title, required String body}) async {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: title,
      body: body,
      localUpdatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    await _localDataSource.upsertNote(note);
    await _enqueueOperation(note.id, OperationType.create);
    return note;
  }

  Future<Note> updateNote(
    Note note, {
    required String title,
    required String body,
  }) async {
    final updated = note.copyWith(
      title: title,
      body: body,
      localUpdatedAt: DateTime.now(),
      syncStatus: note.syncStatus == SyncStatus.conflict
          ? SyncStatus.conflict
          : SyncStatus.pending,
    );

    await _localDataSource.upsertNote(updated);

    if (note.syncStatus != SyncStatus.conflict) {
      final existingOp = await _localDataSource.getPendingOperationForNote(note.id);
      if (existingOp?.type != OperationType.create) {
        await _enqueueOperation(note.id, OperationType.update);
      }
    }

    return updated;
  }

  Future<void> deleteNote(Note note) async {
    final deleted = note.copyWith(
      isDeleted: true,
      localUpdatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );
    await _localDataSource.upsertNote(deleted);

    final existingOp = await _localDataSource.getPendingOperationForNote(note.id);
    if (existingOp?.type == OperationType.create) {
      await _localDataSource.removePendingOperationsForNote(note.id);
      await _localDataSource.deleteNotePermanently(note.id);
    } else {
      await _localDataSource.removePendingOperationsForNote(note.id);
      await _enqueueOperation(note.id, OperationType.delete);
    }
  }

  Future<void> resolveConflictKeepLocal(Note note) async {
    final resolved = note.copyWith(
      syncStatus: SyncStatus.pending,
      clearServerConflict: true,
      localUpdatedAt: DateTime.now(),
    );
    await _localDataSource.upsertNote(resolved);
    await _localDataSource.removePendingOperationsForNote(note.id);
    await _enqueueOperation(note.id, OperationType.update, forcePush: true);
  }

  Future<void> resolveConflictKeepServer(Note note) async {
    final serverTitle = note.serverTitle ?? note.title;
    final serverBody = note.serverBody ?? note.body;
    final serverUpdatedAt =
        note.serverVersionAtConflict ?? note.serverUpdatedAt ?? DateTime.now();
    final resolved = note.copyWith(
      title: serverTitle,
      body: serverBody,
      localUpdatedAt: serverUpdatedAt,
      serverUpdatedAt: serverUpdatedAt,
      syncedTitle: serverTitle,
      syncedBody: serverBody,
      syncStatus: SyncStatus.synced,
      clearServerConflict: true,
    );
    await _localDataSource.upsertNote(resolved);
    await _localDataSource.removePendingOperationsForNote(note.id);
  }

  Future<void> resolveConflictMerge(
    Note note, {
    required String title,
    required String body,
  }) async {
    final resolved = note.copyWith(
      title: title,
      body: body,
      localUpdatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
      clearServerConflict: true,
    );
    await _localDataSource.upsertNote(resolved);
    await _localDataSource.removePendingOperationsForNote(note.id);
    await _enqueueOperation(note.id, OperationType.update, forcePush: true);
  }

  Future<void> saveNoteFromSync(Note note) async {
    await _localDataSource.upsertNote(note);
  }

  Future<List<PendingOperation>> getPendingOperations() {
    return _localDataSource.getPendingOperations();
  }

  Future<void> removePendingOperation(PendingOperation operation) {
    return _localDataSource.removePendingOperation(operation.id);
  }

  Future<void> deleteNotePermanently(String id) {
    return _localDataSource.deleteNotePermanently(id);
  }

  Future<void> _enqueueOperation(
    String noteId,
    OperationType type, {
    bool forcePush = false,
  }) async {
    await _localDataSource.enqueueOperation(
      PendingOperation(
        id: 0,
        noteId: noteId,
        type: type,
        createdAt: DateTime.now(),
        forcePush: forcePush,
      ),
    );
  }
}
