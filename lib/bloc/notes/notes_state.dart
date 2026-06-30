import 'package:equatable/equatable.dart';

import '../../models/note.dart';

enum NotesStatus { initial, loading, success, failure }

class NotesState extends Equatable {
  const NotesState({
    this.status = NotesStatus.initial,
    this.notes = const [],
    this.isOnline = false,
    this.isSyncing = false,
    this.errorMessage,
  });

  final NotesStatus status;
  final List<Note> notes;
  final bool isOnline;
  final bool isSyncing;
  final String? errorMessage;

  NotesState copyWith({
    NotesStatus? status,
    List<Note>? notes,
    bool? isOnline,
    bool? isSyncing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, notes, isOnline, isSyncing, errorMessage];
}
