import 'dart:async';

import '../core/network/network_info.dart';
import '../features/notes/domain/repositories/notes_repository.dart';

/// Listens for connectivity changes and triggers automatic synchronization.
class ConnectivityService {
  ConnectivityService({
    required NetworkInfo networkInfo,
    required NotesRepository notesRepository,
    this.onSyncCompleted,
  })  : _networkInfo = networkInfo,
        _notesRepository = notesRepository;

  final NetworkInfo _networkInfo;
  final NotesRepository _notesRepository;
  final void Function()? onSyncCompleted;

  StreamSubscription<bool>? _subscription;

  /// Starts listening — sync runs in background without blocking the UI.
  Future<void> start() async {
    await _subscription?.cancel();
    _subscription = _networkInfo.onConnectivityChanged.listen(
      (isConnected) {
        if (isConnected) {
          unawaited(_triggerSync());
        }
      },
    );

    if (await _networkInfo.isConnected) {
      unawaited(_triggerSync());
    }
  }

  Future<void> _triggerSync() async {
    try {
      await _notesRepository.syncNotes();
      onSyncCompleted?.call();
    } catch (_) {
      // Sync failures are retried automatically on next connectivity event.
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
