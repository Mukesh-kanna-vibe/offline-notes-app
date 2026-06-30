import 'package:dio/dio.dart';

import '../models/note.dart';
import '../models/pending_operation.dart';
import '../models/sync_status.dart';
import '../repositories/notes_repository.dart';
import 'api_service.dart';
import 'connectivity_service.dart';

class SyncService {
  SyncService({
    required NotesRepository repository,
    required ApiService apiService,
    required ConnectivityService connectivityService,
  })  : _repository = repository,
        _apiService = apiService,
        _connectivityService = connectivityService;

  final NotesRepository _repository;
  final ApiService _apiService;
  final ConnectivityService _connectivityService;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<void> init({required void Function() onSyncComplete}) async {
    _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        sync(onComplete: onSyncComplete);
      }
    });

    if (await _connectivityService.isOnline()) {
      await sync(onComplete: onSyncComplete);
    }
  }

  Future<void> sync({void Function()? onComplete}) async {
    if (_isSyncing) return;
    if (!await _connectivityService.isOnline()) return;

    _isSyncing = true;
    try {
      await _pullRemoteChanges();
      await _pushPendingChanges();
    } finally {
      _isSyncing = false;
      onComplete?.call();
    }
  }

  Future<void> _pullRemoteChanges() async {
    final remoteNotes = await _apiService.fetchNotes();

    for (final remote in remoteNotes) {
      final local = await _repository.getNote(remote.id);

      if (local == null) {
        await _repository.saveNoteFromSync(remote);
        continue;
      }

      if (local.isDeleted) continue;

      if (local.syncStatus == SyncStatus.pending) {
        final pendingOp = await _repository.getPendingOperationForNote(local.id);
        if (pendingOp?.forcePush == true) {
          continue;
        }
        if (_hasConflict(local, remote)) {
          await _markConflict(local, remote);
        }
        continue;
      }

      if (local.syncStatus == SyncStatus.conflict) continue;

      if (_remoteIsNewer(local, remote)) {
        await _repository.saveNoteFromSync(local.asSyncedFromRemote(remote));
      }
    }
  }

  bool _hasConflict(Note local, Note remote) {
    final baselineTitle = local.syncedTitle;
    final baselineBody = local.syncedBody;

    if (baselineTitle == null || baselineBody == null) {
      if (local.serverUpdatedAt == null) return false;
      final hasLocalChanges =
          local.localUpdatedAt.isAfter(local.serverUpdatedAt!);
      final hasRemoteChanges =
          remote.serverUpdatedAt!.isAfter(local.serverUpdatedAt!);
      return hasLocalChanges && hasRemoteChanges;
    }

    final hasLocalChanges = local.title != baselineTitle ||
        local.body != baselineBody ||
        local.localUpdatedAt.isAfter(local.serverUpdatedAt ?? local.localUpdatedAt);

    final hasRemoteChanges = remote.title != baselineTitle ||
        remote.body != baselineBody ||
        (local.serverUpdatedAt != null &&
            remote.serverUpdatedAt!.isAfter(local.serverUpdatedAt!));

    return hasLocalChanges && hasRemoteChanges;
  }

  bool _remoteIsNewer(Note local, Note remote) {
    if (local.serverUpdatedAt == null) return true;
    return remote.serverUpdatedAt!.isAfter(local.serverUpdatedAt!);
  }

  Future<void> _pushPendingChanges() async {
    final operations = await _repository.getPendingOperations();

    for (final operation in operations) {
      final note = await _repository.getNote(operation.noteId);
      if (note == null) {
        await _repository.removePendingOperation(operation);
        continue;
      }

      if (note.syncStatus == SyncStatus.conflict) continue;

      try {
        switch (operation.type) {
          case OperationType.create:
            final created = await _apiService.createNote(note);
            await _repository.saveNoteFromSync(
              note.asSyncedAfterPush(created.serverUpdatedAt!),
            );
          case OperationType.update:
            final updated = await _apiService.updateNote(note);
            await _repository.saveNoteFromSync(
              note.asSyncedAfterPush(updated.serverUpdatedAt!),
            );
          case OperationType.delete:
            await _apiService.deleteNote(note.id);
            await _repository.deleteNotePermanently(note.id);
        }
        await _repository.removePendingOperation(operation);
      } on DioException catch (error) {
        assert(() {
          // ignore: avoid_print
          print('Sync failed for ${operation.noteId}: ${error.message}');
          return true;
        }());
      } catch (error) {
        assert(() {
          // ignore: avoid_print
          print('Sync failed for ${operation.noteId}: $error');
          return true;
        }());
      }
    }
  }

  Future<void> _markConflict(Note local, Note remote) async {
    await _repository.saveNoteFromSync(
      local.copyWith(
        syncStatus: SyncStatus.conflict,
        serverTitle: remote.title,
        serverBody: remote.body,
        serverVersionAtConflict: remote.serverUpdatedAt,
      ),
    );
  }
}
