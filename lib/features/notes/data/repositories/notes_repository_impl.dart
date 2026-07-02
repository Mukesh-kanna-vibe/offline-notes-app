import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/note_entities.dart';
import '../../domain/repositories/notes_repository.dart';
import '../datasources/notes_local_datasource.dart';
import '../datasources/notes_remote_datasource.dart';
import '../datasources/sync_queue_local_datasource.dart';
import '../models/note_model.dart';

class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl({
    required NotesLocalDataSource localDataSource,
    required SyncQueueLocalDataSource syncQueueDataSource,
    required NotesRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    this.onSyncCompleted,
    this.onConflictDetected,
    Uuid? uuid,
  })  : _localDataSource = localDataSource,
        _syncQueueDataSource = syncQueueDataSource,
        _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo,
        _uuid = uuid ?? const Uuid();

  final NotesLocalDataSource _localDataSource;
  final SyncQueueLocalDataSource _syncQueueDataSource;
  final NotesRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final Uuid _uuid;
  final void Function()? onSyncCompleted;
  final void Function(String noteId)? onConflictDetected;

  Future<void>? _syncFuture;

  @override
  Future<List<Note>> getNotes({
    String? searchQuery,
    NoteSortOption sortOption = NoteSortOption.createdAtDesc,
    bool includeDeleted = false,
  }) async {
    final notes = await _localDataSource.getNotes(
      searchQuery: searchQuery,
      sortOption: sortOption,
      includeDeleted: includeDeleted,
    );
    return notes.map((note) => note.toEntity()).toList();
  }

  @override
  Future<void> ensureConflictStatusPersisted(String noteId) async {
    final local = await _localDataSource.getNoteById(noteId);
    if (local == null) {
      return;
    }

    if (local.syncStatus == SyncStatus.conflict) {
      return;
    }

    if (local.isInConflictState) {
      await _localDataSource.updateNote(
        local.copyWith(syncStatus: SyncStatus.conflict),
      );
      return;
    }

    if (local.syncStatus != SyncStatus.pending || local.serverId == null) {
      return;
    }

    if (!await _networkInfo.isConnected) {
      return;
    }

    try {
      final remote = await _remoteDataSource.fetchNoteById(local.serverId!);
      if (_notesDiffer(local, remote)) {
        await _markConflict(local, remote);
      }
    } on AppException {
      // Leave note unchanged when remote cannot be loaded.
    }
  }

  @override
  Stream<List<Note>> watchNotes({
    String? searchQuery,
    NoteSortOption sortOption = NoteSortOption.createdAtDesc,
  }) {
    return _localDataSource
        .watchNotes(searchQuery: searchQuery, sortOption: sortOption)
        .map((notes) => notes.map((note) => note.toEntity()).toList());
  }

  @override
  Future<Note?> getNoteById(String id) async {
    final note = await _localDataSource.getNoteById(id);
    return note?.toEntity();
  }

  @override
  Future<Note> createNote({
    required String title,
    required String body,
  }) async {
    final now = DateTime.now().toUtc();
    final note = NoteModel(
      id: _uuid.v4(),
      title: title.trim(),
      body: body.trim(),
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    await _localDataSource.insertNote(note);
    await _enqueueOperation(
      noteId: note.id,
      operationType: OperationType.create,
      payload: note.toRemoteJson(),
    );

    if (await _networkInfo.isConnected) {
      await syncNotes();
    }

    final saved = await _localDataSource.getNoteById(note.id);
    return (saved ?? note).toEntity();
  }

  @override
  Future<Note> updateNote({
    required String id,
    required String title,
    required String body,
  }) async {
    final existing = await _localDataSource.getNoteById(id);
    if (existing == null) {
      throw const CacheException('Note not found');
    }

    final updated = _applyPendingLocalChange(
      existing,
      title: title.trim(),
      body: body.trim(),
    );

    await _localDataSource.updateNote(updated);
    await _enqueueOperation(
      noteId: updated.id,
      operationType: OperationType.update,
      payload: updated.toRemoteJson(),
    );

    if (await _networkInfo.isConnected) {
      await syncNotes();
    }

    final saved = await _localDataSource.getNoteById(updated.id);
    return (saved ?? updated).toEntity();
  }

  @override
  Future<void> deleteNote(String id) async {
    final existing = await _localDataSource.getNoteById(id);
    if (existing == null) {
      throw const CacheException('Note not found');
    }

    final deleted = _applyPendingLocalChange(
      existing,
      isDeleted: true,
    );

    await _localDataSource.updateNote(deleted);
    await _enqueueOperation(
      noteId: deleted.id,
      operationType: OperationType.delete,
      payload: deleted.toRemoteJson(),
    );

    if (await _networkInfo.isConnected) {
      await syncNotes();
    }
  }

  @override
  Future<List<Note>> getConflictedNotes() async {
    final notes = await _localDataSource.getConflictedNotes();
    return notes.map((note) => note.toEntity()).toList();
  }

  @override
  Future<ConflictData?> getConflict(String noteId) async {
    final local = await _localDataSource.getNoteById(noteId);
    if (local == null) {
      return null;
    }

    final localNote = _buildConflictLocalNote(local);

    if (await _networkInfo.isConnected && local.serverId != null) {
      try {
        final remote = await _remoteDataSource.fetchNoteById(local.serverId!);
        final differs = _notesDiffer(local, remote);
        if (!differs && !_looksLikeConflictNote(local)) {
          return null;
        }

        if (local.syncStatus != SyncStatus.conflict || !local.hasConflictSnapshot) {
          await _markConflict(local, remote);
        }

        return ConflictData(
          localNote: localNote,
          remoteNote: remote.copyWith(id: local.id).toEntity(),
        );
      } on AppException {
        // Fall through to stored/offline data below.
      }
    }

    final stored = local.toConflictData();
    if (stored != null) {
      return stored;
    }

    if (!_looksLikeConflictNote(local)) {
      return null;
    }

    return ConflictData(
      localNote: localNote,
      remoteNote: Note(
        id: local.id,
        title: local.conflictRemoteTitle ?? 'Remote version unavailable',
        body: local.conflictRemoteBody ??
            (await _networkInfo.isConnected
                ? 'Could not load the server copy. Try again.'
                : 'Connect to the internet to load the server copy.'),
        createdAt: local.createdAt,
        updatedAt: local.conflictRemoteUpdatedAt ??
            local.remoteUpdatedAt ??
            local.updatedAt,
        syncStatus: SyncStatus.synced,
        serverId: local.serverId,
      ),
    );
  }

  bool _notesDiffer(NoteModel local, NoteModel remote) {
    return local.title.trim() != remote.title.trim() ||
        local.body.trim() != remote.body.trim() ||
        local.isDeleted != remote.isDeleted;
  }

  bool _looksLikeConflictNote(NoteModel local) {
    return local.isInConflictState;
  }

  Note _buildConflictLocalNote(NoteModel local) {
    return Note(
      id: local.id,
      title: local.conflictLocalTitle ?? local.title,
      body: local.conflictLocalBody ?? local.body,
      createdAt: local.createdAt,
      updatedAt: local.conflictLocalUpdatedAt ?? local.updatedAt,
      syncStatus: SyncStatus.conflict,
      remoteUpdatedAt: local.remoteUpdatedAt,
      serverId: local.serverId,
    );
  }

  @override
  Future<Note> resolveConflict({
    required String noteId,
    required ConflictResolutionChoice choice,
    String? mergedTitle,
    String? mergedBody,
  }) async {
    final local = await _localDataSource.getNoteById(noteId);
    if (local == null) {
      throw const CacheException('Note not found');
    }

    if (choice == ConflictResolutionChoice.keepLocal) {
      final resolved = local.copyWith(
        updatedAt: DateTime.now().toUtc(),
        clearConflictSnapshots: true,
      );
      await _localDataSource.updateNote(resolved);
      await _syncQueueDataSource.removeByNoteId(noteId);

      if (await _networkInfo.isConnected) {
        final synced = await _pushResolvedNoteToServer(resolved);
        return synced.toEntity();
      }

      final pending = resolved.copyWith(syncStatus: SyncStatus.pending);
      await _localDataSource.updateNote(pending);
      await _enqueueOperation(
        noteId: noteId,
        operationType: pending.serverId == null
            ? OperationType.create
            : OperationType.update,
        payload: pending.toRemoteJson(apiId: pending.serverId),
        forceOverwrite: true,
      );
      final saved = await _localDataSource.getNoteById(noteId);
      return (saved ?? pending).toEntity();
    }

    if (choice == ConflictResolutionChoice.merge) {
      final title = mergedTitle?.trim();
      final body = mergedBody?.trim();
      if (title == null ||
          title.isEmpty ||
          body == null ||
          body.isEmpty) {
        throw const CacheException('Merged title and body are required');
      }

      final resolved = local.copyWith(
        title: title,
        body: body,
        updatedAt: DateTime.now().toUtc(),
        clearConflictSnapshots: true,
      );
      await _localDataSource.updateNote(resolved);
      await _syncQueueDataSource.removeByNoteId(noteId);

      if (await _networkInfo.isConnected) {
        final synced = await _pushResolvedNoteToServer(resolved);
        return synced.toEntity();
      }

      final pending = resolved.copyWith(syncStatus: SyncStatus.pending);
      await _localDataSource.updateNote(pending);
      await _enqueueOperation(
        noteId: noteId,
        operationType: pending.serverId == null
            ? OperationType.create
            : OperationType.update,
        payload: pending.toRemoteJson(apiId: pending.serverId),
        forceOverwrite: true,
      );
      final saved = await _localDataSource.getNoteById(noteId);
      return (saved ?? pending).toEntity();
    }

    if (!await _networkInfo.isConnected) {
      throw const NetworkException('Internet required to keep remote version');
    }

    final apiId = local.serverId;
    if (apiId == null) {
      throw const NetworkException('Remote note not found for conflict resolution');
    }

    final remote = await _remoteDataSource.fetchNoteById(apiId);
    final resolved = local.copyWith(
      title: remote.title,
      body: remote.body,
      updatedAt: remote.updatedAt,
      syncStatus: SyncStatus.synced,
      remoteUpdatedAt: remote.updatedAt,
      serverId: apiId,
      clearConflictSnapshots: true,
    );
    await _localDataSource.updateNote(resolved.withSyncBaseFrom(remote));
    await _syncQueueDataSource.removeByNoteId(noteId);
    return resolved.toEntity();
  }

  @override
  Future<void> syncNotes() async {
    if (!await _networkInfo.isConnected) return;

    while (true) {
      if (_syncFuture != null) {
        await _syncFuture;
      } else {
        _syncFuture = _runSync();
        try {
          await _syncFuture;
        } finally {
          _syncFuture = null;
        }
      }

      final queue = await _syncQueueDataSource.getPendingOperations();
      final hasRetryable = queue.any(
        (item) => item.retryCount < ApiConstants.maxRetryAttempts,
      );
      if (!hasRetryable) return;
    }
  }

  Future<void> _runSync() async {
    try {
      final conflictDetected = await _pushPendingChanges();
      if (!conflictDetected) {
        await _pullRemoteChanges();
      }
      onSyncCompleted?.call();
    } catch (_) {
      // Retry on next connectivity event or user action.
    }
  }

  NoteModel _applyPendingLocalChange(
    NoteModel existing, {
    String? title,
    String? body,
    bool? isDeleted,
  }) {
    final now = DateTime.now().toUtc();
    final captureBaseline = existing.syncStatus == SyncStatus.synced;

    return existing.copyWith(
      title: title,
      body: body,
      isDeleted: isDeleted,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
      syncBaseTitle: captureBaseline
          ? existing.title
          : (existing.syncBaseTitle ?? existing.title),
      syncBaseBody:
          captureBaseline ? existing.body : (existing.syncBaseBody ?? existing.body),
      syncBaseIsDeleted: captureBaseline
          ? existing.isDeleted
          : (existing.syncBaseIsDeleted ?? existing.isDeleted),
    );
  }

  Future<bool> _pushPendingChanges() async {
    final queue = await _syncQueueDataSource.getPendingOperations();
    var conflictDetected = false;

    for (final item in queue) {
      if (item.retryCount >= ApiConstants.maxRetryAttempts) {
        continue;
      }

      try {
        final note = await _localDataSource.getNoteById(item.noteId);
        if (note?.syncStatus == SyncStatus.conflict) {
          await _syncQueueDataSource.removeById(item.id);
          continue;
        }

        await _processQueueItem(item);
        await _syncQueueDataSource.removeById(item.id);
      } on ConflictException catch (error) {
        conflictDetected = true;
        final note = await _localDataSource.getNoteById(error.noteId);
        if (note != null && note.syncStatus != SyncStatus.conflict) {
          final remote = await _fetchRemoteForNote(note);
          if (remote != null) {
            await _markConflict(note, remote);
          } else {
            await _localDataSource.updateNote(
              note.copyWith(
                syncStatus: SyncStatus.conflict,
                conflictLocalTitle: note.title,
                conflictLocalBody: note.body,
                conflictLocalUpdatedAt: note.updatedAt,
              ),
            );
            onConflictDetected?.call(note.id);
          }
        }
        await _syncQueueDataSource.removeById(item.id);
        break;
      } on AppException catch (error) {
        await _syncQueueDataSource.updateQueueItem(
          item.copyWith(
            retryCount: item.retryCount + 1,
            lastAttemptAt: DateTime.now().toUtc(),
            errorMessage: error.message,
          ),
        );
      } catch (error) {
        await _syncQueueDataSource.updateQueueItem(
          item.copyWith(
            retryCount: item.retryCount + 1,
            lastAttemptAt: DateTime.now().toUtc(),
            errorMessage: error.toString(),
          ),
        );
      }
    }

    return conflictDetected;
  }

  Future<void> _processQueueItem(SyncQueueItemModel item) async {
    final note = await _localDataSource.getNoteById(item.noteId);
    if (note == null) {
      return;
    }

    final forceOverwrite =
        item.payload[ApiConstants.forceOverwritePayloadKey] == true;

    switch (item.operationType) {
      case OperationType.create:
        await _createOnServer(note);
      case OperationType.update:
        if (note.serverId == null) {
          await _createOnServer(note);
        } else {
          if (!forceOverwrite) {
            final remote = await _fetchLatestRemoteBeforeSync(note);
            await _ensureNoConflict(localNote: note, remoteNote: remote);
          }
          final updated = await _remoteDataSource.updateNote(
            note,
            apiId: note.serverId!,
          );
          await _markNoteSynced(note, updated);
        }
      case OperationType.delete:
        if (note.serverId != null) {
          if (!forceOverwrite) {
            final remote = await _fetchLatestRemoteBeforeSync(note);
            await _ensureNoConflict(localNote: note, remoteNote: remote);
          }
          await _remoteDataSource.deleteNote(note.serverId!);
        }
        await _localDataSource.deleteNotePermanently(note.id);
    }
  }

  Future<NoteModel> _pushResolvedNoteToServer(NoteModel note) async {
    if (note.serverId == null) {
      await _createOnServer(note);
    } else {
      final updated = await _remoteDataSource.updateNote(
        note,
        apiId: note.serverId!,
      );
      await _markNoteSynced(note, updated);
    }

    final saved = await _localDataSource.getNoteById(note.id);
    return saved ?? note;
  }

  Future<bool> _noteHasForceOverwriteQueued(String noteId) async {
    final item = await _syncQueueDataSource.getLatestOperationForNote(noteId);
    if (item == null) return false;
    return item.payload[ApiConstants.forceOverwritePayloadKey] == true;
  }

  Future<void> _createOnServer(NoteModel note) async {
    final created = await _remoteDataSource.createNote(note);
    await _markNoteSynced(
      note,
      created,
      serverId: created.id,
    );
  }

  Future<void> _markNoteSynced(
    NoteModel local,
    NoteModel remote, {
    String? serverId,
  }) async {
    await _localDataSource.updateNote(
      local
          .copyWith(
            serverId: serverId ?? remote.serverId ?? remote.id,
            syncStatus: SyncStatus.synced,
            remoteUpdatedAt: remote.updatedAt,
          )
          .withSyncBaseFrom(remote),
    );
  }

  Future<void> _ensureNoConflict({
    required NoteModel localNote,
    required NoteModel remoteNote,
  }) async {
    if (_hasConflict(local: localNote, remote: remoteNote)) {
      throw ConflictException(localNote.id);
    }
  }

  bool _hasConflict({
    required NoteModel local,
    required NoteModel remote,
  }) {
    if (local.syncStatus != SyncStatus.pending) return false;
    if (local.serverId == null) return false;

    final contentDiffers =
        local.title.trim() != remote.title.trim() ||
        local.body.trim() != remote.body.trim() ||
        local.isDeleted != remote.isDeleted;

    if (!contentDiffers) return false;

    final baseTitle = local.syncBaseTitle;
    final baseBody = local.syncBaseBody;
    final hasBase = baseTitle != null && baseBody != null;
    final baseDeleted = local.syncBaseIsDeleted ?? local.isDeleted;
    final baseMatchesLocal = hasBase &&
        baseTitle.trim() == local.title.trim() &&
        baseBody.trim() == local.body.trim() &&
        baseDeleted == local.isDeleted;

    if (hasBase && !baseMatchesLocal) {
      final localChanged =
          local.title.trim() != baseTitle.trim() ||
          local.body.trim() != baseBody.trim() ||
          local.isDeleted != baseDeleted;

      final remoteChanged =
          remote.title.trim() != baseTitle.trim() ||
          remote.body.trim() != baseBody.trim() ||
          remote.isDeleted != baseDeleted;

      return localChanged && remoteChanged;
    }

    final lastSyncedAt = local.remoteUpdatedAt;
    if (lastSyncedAt == null) return true;

    final remoteChanged = remote.updatedAt.isAfter(lastSyncedAt);
    final localChanged = local.updatedAt.isAfter(lastSyncedAt);

    return remoteChanged && localChanged;
  }

  Future<NoteModel> _fetchLatestRemoteBeforeSync(NoteModel localNote) async {
    final apiId = localNote.serverId;
    if (apiId == null) {
      throw const CacheException('Server id missing for remote sync');
    }
    return _remoteDataSource.fetchNoteById(apiId);
  }

  Future<NoteModel?> _fetchRemoteForNote(NoteModel local) async {
    final apiId = local.serverId;
    if (apiId == null || !await _networkInfo.isConnected) return null;
    try {
      return await _remoteDataSource.fetchNoteById(apiId);
    } on AppException {
      return null;
    }
  }

  Future<void> _markConflict(NoteModel local, NoteModel remote) async {
    await _localDataSource.updateNote(
      local.copyWith(
        syncStatus: SyncStatus.conflict,
        conflictLocalTitle: local.title,
        conflictLocalBody: local.body,
        conflictLocalUpdatedAt: local.updatedAt,
        conflictRemoteTitle: remote.title,
        conflictRemoteBody: remote.body,
        conflictRemoteUpdatedAt: remote.updatedAt,
      ),
    );
    await _syncQueueDataSource.removeByNoteId(local.id);
    onConflictDetected?.call(local.id);
  }

  Future<NoteModel?> _findLocalForRemote(NoteModel remote) async {
    if (remote.serverId != null) {
      final byServerId =
          await _localDataSource.getNoteByServerId(remote.serverId!);
      if (byServerId != null) return byServerId;
    }
    return _localDataSource.getNoteById(remote.id);
  }

  Future<void> _pullRemoteChanges() async {
    final remoteNotes = await _remoteDataSource.fetchNotes();

    for (final remote in remoteNotes) {
      final local = await _findLocalForRemote(remote);

      if (local == null) {
        if (!remote.isDeleted) {
          await _localDataSource.insertNote(
            NoteModel(
              id: _uuid.v4(),
              title: remote.title,
              body: remote.body,
              createdAt: remote.createdAt,
              updatedAt: remote.updatedAt,
              syncStatus: SyncStatus.synced,
              remoteUpdatedAt: remote.updatedAt,
              serverId: remote.id,
              syncBaseTitle: remote.title,
              syncBaseBody: remote.body,
              syncBaseIsDeleted: remote.isDeleted,
            ),
          );
        }
        continue;
      }

      if (local.syncStatus == SyncStatus.pending) {
        final forceOverwrite = await _noteHasForceOverwriteQueued(local.id);
        if (!forceOverwrite && _hasConflict(local: local, remote: remote)) {
          await _markConflict(local, remote);
        }
        continue;
      }

      if (local.syncStatus == SyncStatus.conflict) {
        continue;
      }

      if (remote.isDeleted) {
        await _localDataSource.deleteNotePermanently(local.id);
        continue;
      }

      final lastKnownRemoteAt =
          local.remoteUpdatedAt ?? local.updatedAt;
      if (remote.updatedAt.isAfter(lastKnownRemoteAt)) {
        await _localDataSource.updateNote(
          local
              .copyWith(
                title: remote.title,
                body: remote.body,
                updatedAt: remote.updatedAt,
                syncStatus: SyncStatus.synced,
                remoteUpdatedAt: remote.updatedAt,
                serverId: remote.id,
              )
              .withSyncBaseFrom(remote),
        );
      }
    }
  }

  Future<void> _enqueueOperation({
    required String noteId,
    required OperationType operationType,
    required Map<String, dynamic> payload,
    bool forceOverwrite = false,
  }) async {
    final existing = await _syncQueueDataSource.getLatestOperationForNote(noteId);
    var resolvedOperation = operationType;
    final resolvedPayload = Map<String, dynamic>.from(payload);
    if (forceOverwrite) {
      resolvedPayload[ApiConstants.forceOverwritePayloadKey] = true;
    }

    if (existing != null) {
      if (existing.operationType == OperationType.create &&
          operationType == OperationType.delete) {
        await _syncQueueDataSource.removeByNoteId(noteId);
        await _localDataSource.deleteNotePermanently(noteId);
        return;
      }

      if (existing.operationType == OperationType.create &&
          operationType == OperationType.update) {
        // Never synced yet — keep as CREATE with latest data.
        resolvedOperation = OperationType.create;
      }

      await _syncQueueDataSource.removeById(existing.id);
    }

    await _syncQueueDataSource.enqueue(
      SyncQueueItemModel(
        id: _uuid.v4(),
        noteId: noteId,
        operationType: resolvedOperation,
        payload: resolvedPayload,
        retryCount: 0,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }
}
