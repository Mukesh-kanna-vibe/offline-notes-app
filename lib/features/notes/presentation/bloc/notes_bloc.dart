import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/note_entities.dart';
import '../../domain/repositories/notes_repository.dart';
import 'notes_event.dart';
import 'notes_state.dart';

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc({
    required this._notesRepository,
    NotesState? initialState,
  }) : super(initialState ?? const NotesState()) {
    on<NotesStarted>(_onStarted);
    on<NotesRefreshed>(_onRefreshed);
    on<NotesListReloaded>(_onListReloaded);
    on<NotesSearchChanged>(_onSearchChanged);
    on<NotesSortChanged>(_onSortChanged);
    on<NoteCreateRequested>(_onCreateRequested);
    on<NoteUpdateRequested>(_onUpdateRequested);
    on<NoteDeleteRequested>(_onDeleteRequested);
    on<LoadConflict>(_onLoadConflict);
    on<ConflictDetected>(_onConflictDetected);
    on<NoteConflictResolutionRequested>(_onConflictResolutionRequested);
    on<ConflictResolved>(_onConflictResolved);
    on<ConflictNavigationHandled>(_onConflictNavigationHandled);
    on<ConflictPageClosed>(_onConflictPageClosed);
    on<NotesErrorDismissed>(_onErrorDismissed);
  }

  final NotesRepository _notesRepository;

  Future<void> _onStarted(
    NotesStarted event,
    Emitter<NotesState> emit,
  ) async {
    await _loadNotes(emit);
  }

  Future<void> _onRefreshed(
    NotesRefreshed event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(isSyncing: true, clearError: true));
    try {
      await _notesRepository.syncNotes();
      await _loadNotes(emit);
    } catch (error) {
      if (!emit.isDone) {
        emit(
          state.copyWith(
            isSyncing: false,
            errorMessage: _mapError(error),
          ),
        );
      }
    }
  }

  Future<void> _onListReloaded(
    NotesListReloaded event,
    Emitter<NotesState> emit,
  ) async {
    await _loadNotes(emit);
  }

  Future<void> _onSearchChanged(
    NotesSearchChanged event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    await _loadNotes(emit);
  }

  Future<void> _onSortChanged(
    NotesSortChanged event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(sortOption: event.sortOption));
    await _loadNotes(emit);
  }

  Future<void> _onCreateRequested(
    NoteCreateRequested event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(isSavingNote: true, clearError: true));
    try {
      await _notesRepository.createNote(
        title: event.title,
        body: event.body,
      );
      await _loadNotes(emit);
    } catch (error) {
      if (!emit.isDone) {
        emit(
          state.copyWith(
            isSavingNote: false,
            errorMessage: _mapError(error),
          ),
        );
      }
    }
  }

  Future<void> _onUpdateRequested(
    NoteUpdateRequested event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _notesRepository.updateNote(
        id: event.id,
        title: event.title,
        body: event.body,
      );
      await _loadNotes(emit);
    } catch (error) {
      if (!emit.isDone) {
        emit(state.copyWith(errorMessage: _mapError(error)));
      }
    }
  }

  Future<void> _onDeleteRequested(
    NoteDeleteRequested event,
    Emitter<NotesState> emit,
  ) async {
    try {
      await _notesRepository.deleteNote(event.id);
      await _loadNotes(emit);
    } catch (error) {
      if (!emit.isDone) {
        emit(state.copyWith(errorMessage: _mapError(error)));
      }
    }
  }

  Future<void> _onLoadConflict(
    LoadConflict event,
    Emitter<NotesState> emit,
  ) async {
    emit(
      state.copyWith(
        isResolvingConflict: true,
        clearError: true,
        clearConflictData: true,
      ),
    );
    try {
      final conflictData = await _notesRepository.getConflict(event.noteId);
      if (emit.isDone) return;
      emit(
        state.copyWith(
          conflictData: conflictData,
          isResolvingConflict: false,
          errorMessage: conflictData == null
              ? 'Unable to load conflict details for this note.'
              : null,
        ),
      );
    } catch (error) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          isResolvingConflict: false,
          errorMessage: _mapError(error),
        ),
      );
    }
  }

  Future<void> _onConflictDetected(
    ConflictDetected event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(pendingConflictNoteId: event.noteId));
  }

  Future<void> _onConflictResolutionRequested(
    NoteConflictResolutionRequested event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(isResolvingConflict: true, clearError: true));
    try {
      await _notesRepository.resolveConflict(
        noteId: event.noteId,
        choice: event.choice,
        mergedTitle: event.mergedTitle,
        mergedBody: event.mergedBody,
      );
      if (emit.isDone) return;
      emit(
        state.copyWith(
          isResolvingConflict: false,
          clearConflictData: true,
          lastResolvedConflictNoteId: event.noteId,
        ),
      );
      add(ConflictResolved(event.noteId));
      await _loadNotes(emit);
    } catch (error) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          isResolvingConflict: false,
          errorMessage: _mapError(error),
        ),
      );
    }
  }

  Future<void> _onConflictResolved(
    ConflictResolved event,
    Emitter<NotesState> emit,
  ) async {
    emit(
      state.copyWith(
        clearPendingConflict: true,
        lastResolvedConflictNoteId: event.noteId,
      ),
    );
  }

  Future<void> _onConflictNavigationHandled(
    ConflictNavigationHandled event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(clearPendingConflict: true));
  }

  Future<void> _onConflictPageClosed(
    ConflictPageClosed event,
    Emitter<NotesState> emit,
  ) async {
    if (state.lastResolvedConflictNoteId == event.noteId) {
      return;
    }

    await _notesRepository.ensureConflictStatusPersisted(event.noteId);
    await _loadNotes(emit);
  }

  Future<void> _onErrorDismissed(
    NotesErrorDismissed event,
    Emitter<NotesState> emit,
  ) async {
    emit(state.copyWith(clearError: true));
  }

  Future<void> _loadNotes(Emitter<NotesState> emit) async {
    final searchQuery = state.searchQuery;
    final sortOption = state.sortOption;
    final previousConflictIds = state.notes
        .where((note) => note.syncStatus == SyncStatus.conflict)
        .map((note) => note.id)
        .toSet();

    try {
      final notes = await _notesRepository
          .getNotes(
            searchQuery: searchQuery,
            sortOption: sortOption,
          )
          .timeout(const Duration(seconds: 5));

      if (emit.isDone) return;

      final conflictNotes =
          notes.where((note) => note.syncStatus == SyncStatus.conflict);
      String? newlyDetectedConflictId;
      for (final note in conflictNotes) {
        if (!previousConflictIds.contains(note.id)) {
          newlyDetectedConflictId = note.id;
          break;
        }
      }

      emit(
        NotesState(
          status: notes.isEmpty ? NotesStatus.empty : NotesStatus.success,
          notes: notes,
          searchQuery: searchQuery,
          sortOption: sortOption,
          conflictData: state.conflictData,
          isResolvingConflict: state.isResolvingConflict,
          pendingConflictNoteId:
              newlyDetectedConflictId ?? state.pendingConflictNoteId,
          lastResolvedConflictNoteId: state.lastResolvedConflictNoteId,
          isSavingNote: false,
          isSyncing: false,
        ),
      );

      if (newlyDetectedConflictId != null) {
        add(ConflictDetected(newlyDetectedConflictId));
      }
    } catch (error) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: NotesStatus.failure,
          errorMessage: _mapError(error),
          isSavingNote: false,
          isSyncing: false,
        ),
      );
    }
  }

  String _mapError(Object error) {
    if (error is AppException) return error.message;
    return 'Something went wrong. Please try again.';
  }
}
