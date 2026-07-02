import 'package:equatable/equatable.dart';

import '../../domain/entities/note_entities.dart';

abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

class NotesStarted extends NotesEvent {
  const NotesStarted();
}

class NotesRefreshed extends NotesEvent {
  const NotesRefreshed();
}

class NotesListReloaded extends NotesEvent {
  const NotesListReloaded();
}

class NotesSearchChanged extends NotesEvent {
  const NotesSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class NotesSortChanged extends NotesEvent {
  const NotesSortChanged(this.sortOption);

  final NoteSortOption sortOption;

  @override
  List<Object?> get props => [sortOption];
}

class NoteCreateRequested extends NotesEvent {
  const NoteCreateRequested({required this.title, required this.body});

  final String title;
  final String body;

  @override
  List<Object?> get props => [title, body];
}

class NoteUpdateRequested extends NotesEvent {
  const NoteUpdateRequested({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final String body;

  @override
  List<Object?> get props => [id, title, body];
}

class NoteDeleteRequested extends NotesEvent {
  const NoteDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class LoadConflict extends NotesEvent {
  const LoadConflict(this.noteId);

  final String noteId;

  @override
  List<Object?> get props => [noteId];
}

class ConflictDetected extends NotesEvent {
  const ConflictDetected(this.noteId);

  final String noteId;

  @override
  List<Object?> get props => [noteId];
}

class ConflictResolved extends NotesEvent {
  const ConflictResolved(this.noteId);

  final String noteId;

  @override
  List<Object?> get props => [noteId];
}

class NoteConflictResolutionRequested extends NotesEvent {
  const NoteConflictResolutionRequested({
    required this.noteId,
    required this.choice,
    this.mergedTitle,
    this.mergedBody,
  });

  final String noteId;
  final ConflictResolutionChoice choice;
  final String? mergedTitle;
  final String? mergedBody;

  @override
  List<Object?> get props => [noteId, choice, mergedTitle, mergedBody];
}

class NotesErrorDismissed extends NotesEvent {
  const NotesErrorDismissed();
}

class ConflictNavigationHandled extends NotesEvent {
  const ConflictNavigationHandled();
}

class ConflictPageClosed extends NotesEvent {
  const ConflictPageClosed(this.noteId);

  final String noteId;

  @override
  List<Object?> get props => [noteId];
}
