import '../entities/note_entities.dart';

/// Domain contract — presentation depends on this, never on Dio or SQLite.
abstract class NotesRepository {
  Future<List<Note>> getNotes({
    String? searchQuery,
    NoteSortOption sortOption = NoteSortOption.createdAtDesc,
    bool includeDeleted = false,
  });

  Future<Note?> getNoteById(String id);

  Future<Note> createNote({
    required String title,
    required String body,
  });

  Future<Note> updateNote({
    required String id,
    required String title,
    required String body,
  });

  Future<void> deleteNote(String id);

  Future<void> syncNotes();

  Future<List<Note>> getConflictedNotes();

  Future<ConflictData?> getConflict(String noteId);

  Future<Note> resolveConflict({
    required String noteId,
    required ConflictResolutionChoice choice,
    String? mergedTitle,
    String? mergedBody,
  });

  Future<void> ensureConflictStatusPersisted(String noteId);

  Stream<List<Note>> watchNotes({
    String? searchQuery,
    NoteSortOption sortOption = NoteSortOption.createdAtDesc,
  });
}
