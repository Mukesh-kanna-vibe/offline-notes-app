import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/notes_repository.dart';
import '../../services/connectivity_service.dart';
import '../../services/sync_service.dart';
import 'notes_event.dart';
import 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc({
    required NotesRepository repository,
    required SyncService syncService,
    required ConnectivityService connectivityService,
  })  : _repository = repository,
        _syncService = syncService,
        _connectivityService = connectivityService,
        super(const NotesState()) {
    on<NotesLoadRequested>(_onLoadRequested);
    on<NoteCreateRequested>(_onCreateRequested);
    on<NoteUpdateRequested>(_onUpdateRequested);
    on<NoteDeleteRequested>(_onDeleteRequested);
    on<NotesSyncRequested>(_onSyncRequested);
    on<ConflictResolveKeepLocal>(_onResolveKeepLocal);
    on<ConflictResolveKeepServer>(_onResolveKeepServer);
    on<ConflictResolveMerge>(_onResolveMerge);
    on<ConnectivityChanged>(_onConnectivityChanged);

    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((isOnline) {
      add(ConnectivityChanged(isOnline));
    });

    unawaited(_bootstrap());
  }

  final NotesRepository _repository;
  final SyncService _syncService;
  final ConnectivityService _connectivityService;
  late final StreamSubscription<bool> _connectivitySubscription;

  Future<void> _bootstrap() async {
    final isOnline = await _connectivityService.isOnline();
    add(ConnectivityChanged(isOnline));
    add(const NotesLoadRequested());

    await _syncService.init(
      onSyncComplete: () => add(const NotesLoadRequested()),
    );
  }

  Future<void> _onLoadRequested(
    NotesLoadRequested event,
    Emitter<NotesState> emit,
  ) async {
    try {
      final notes = await _repository.getAllNotes();
      emit(state.copyWith(
        status: NotesStatus.success,
        notes: notes,
        clearError: true,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: NotesStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> _onCreateRequested(
    NoteCreateRequested event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(status: NotesStatus.loading, clearError: true));
    try {
      await _repository.createNote(title: event.title, body: event.body);
      await _triggerSync(emit);
    } catch (error) {
      emit(state.copyWith(
        status: NotesStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> _onUpdateRequested(
    NoteUpdateRequested event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(status: NotesStatus.loading, clearError: true));
    try {
      await _repository.updateNote(
        event.note,
        title: event.title,
        body: event.body,
      );
      await _triggerSync(emit);
    } catch (error) {
      emit(state.copyWith(
        status: NotesStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> _onDeleteRequested(
    NoteDeleteRequested event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(status: NotesStatus.loading, clearError: true));
    try {
      await _repository.deleteNote(event.note);
      await _triggerSync(emit);
    } catch (error) {
      emit(state.copyWith(
        status: NotesStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> _onSyncRequested(
    NotesSyncRequested event,
    Emitter<NotesState> emit,
  ) async {
    if (!state.isOnline) return;

    emit(state.copyWith(isSyncing: true, clearError: true));
    try {
      await _syncService.sync(onComplete: () {});
      final notes = await _repository.getAllNotes();
      emit(state.copyWith(
        status: NotesStatus.success,
        notes: notes,
        isSyncing: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: NotesStatus.failure,
        isSyncing: false,
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> _onResolveKeepLocal(
    ConflictResolveKeepLocal event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(status: NotesStatus.loading, clearError: true));
    try {
      await _repository.resolveConflictKeepLocal(event.note);
      await _triggerSync(emit);
    } catch (error) {
      emit(state.copyWith(
        status: NotesStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> _onResolveKeepServer(
    ConflictResolveKeepServer event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(status: NotesStatus.loading, clearError: true));
    try {
      await _repository.resolveConflictKeepServer(event.note);
      final notes = await _repository.getAllNotes();
      emit(state.copyWith(
        status: NotesStatus.success,
        notes: notes,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: NotesStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> _onResolveMerge(
    ConflictResolveMerge event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(status: NotesStatus.loading, clearError: true));
    try {
      await _repository.resolveConflictMerge(
        event.note,
        title: event.title,
        body: event.body,
      );
      await _triggerSync(emit);
    } catch (error) {
      emit(state.copyWith(
        status: NotesStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }

  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(isOnline: event.isOnline));
    if (event.isOnline) {
      add(const NotesSyncRequested());
    }
  }

  Future<void> _triggerSync(Emitter<NotesState> emit) async {
    if (await _connectivityService.isOnline()) {
      emit(state.copyWith(isSyncing: true, clearError: true));
      await _syncService.sync(onComplete: () {});
    }

    final notes = await _repository.getAllNotes();
    emit(state.copyWith(
      status: NotesStatus.success,
      notes: notes,
      isSyncing: false,
    ));
  }

  @override
  Future<void> close() {
    _connectivitySubscription.cancel();
    return super.close();
  }
}
