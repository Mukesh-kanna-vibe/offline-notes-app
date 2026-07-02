import 'package:equatable/equatable.dart';

import '../../domain/entities/note_entities.dart';

enum NotesStatus {
  initial,
  loading,
  success,
  empty,
  failure,
}

class NotesState extends Equatable {
  const NotesState({
    this.status = NotesStatus.initial,
    this.notes = const [],
    this.searchQuery = '',
    this.sortOption = NoteSortOption.createdAtDesc,
    this.errorMessage,
    this.conflictData,
    this.isResolvingConflict = false,
    this.pendingConflictNoteId,
    this.lastResolvedConflictNoteId,
    this.isSavingNote = false,
    this.isSyncing = false,
  });

  final NotesStatus status;
  final List<Note> notes;
  final String searchQuery;
  final NoteSortOption sortOption;
  final String? errorMessage;
  final ConflictData? conflictData;
  final bool isResolvingConflict;
  final String? pendingConflictNoteId;
  final String? lastResolvedConflictNoteId;
  final bool isSavingNote;
  final bool isSyncing;

  bool get hasNotes => notes.isNotEmpty;

  int get pendingCount =>
      notes.where((note) => note.syncStatus == SyncStatus.pending).length;

  int get conflictCount =>
      notes.where((note) => note.syncStatus == SyncStatus.conflict).length;

  NotesState copyWith({
    NotesStatus? status,
    List<Note>? notes,
    String? searchQuery,
    NoteSortOption? sortOption,
    String? errorMessage,
    ConflictData? conflictData,
    bool? isResolvingConflict,
    String? pendingConflictNoteId,
    String? lastResolvedConflictNoteId,
    bool? isSavingNote,
    bool? isSyncing,
    bool clearError = false,
    bool clearConflictData = false,
    bool clearPendingConflict = false,
  }) {
    return NotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? this.sortOption,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      conflictData:
          clearConflictData ? null : (conflictData ?? this.conflictData),
      isResolvingConflict: isResolvingConflict ?? this.isResolvingConflict,
      pendingConflictNoteId: clearPendingConflict
          ? null
          : (pendingConflictNoteId ?? this.pendingConflictNoteId),
      lastResolvedConflictNoteId:
          lastResolvedConflictNoteId ?? this.lastResolvedConflictNoteId,
      isSavingNote: isSavingNote ?? this.isSavingNote,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notes,
        searchQuery,
        sortOption,
        errorMessage,
        conflictData,
        isResolvingConflict,
        pendingConflictNoteId,
        lastResolvedConflictNoteId,
        isSavingNote,
        isSyncing,
      ];
}
