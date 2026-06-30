import 'package:equatable/equatable.dart';

import '../../models/note.dart';

abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

class NotesLoadRequested extends NotesEvent {
  const NotesLoadRequested();
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
    required this.note,
    required this.title,
    required this.body,
  });

  final Note note;
  final String title;
  final String body;

  @override
  List<Object?> get props => [note, title, body];
}

class NoteDeleteRequested extends NotesEvent {
  const NoteDeleteRequested(this.note);

  final Note note;

  @override
  List<Object?> get props => [note];
}

class NotesSyncRequested extends NotesEvent {
  const NotesSyncRequested();
}

class ConflictResolveKeepLocal extends NotesEvent {
  const ConflictResolveKeepLocal(this.note);

  final Note note;

  @override
  List<Object?> get props => [note];
}

class ConflictResolveKeepServer extends NotesEvent {
  const ConflictResolveKeepServer(this.note);

  final Note note;

  @override
  List<Object?> get props => [note];
}

class ConflictResolveMerge extends NotesEvent {
  const ConflictResolveMerge({
    required this.note,
    required this.title,
    required this.body,
  });

  final Note note;
  final String title;
  final String body;

  @override
  List<Object?> get props => [note, title, body];
}

class ConnectivityChanged extends NotesEvent {
  const ConnectivityChanged(this.isOnline);

  final bool isOnline;

  @override
  List<Object?> get props => [isOnline];
}
