import 'package:flutter_test/flutter_test.dart';
import 'package:offline_notes/features/notes/domain/entities/note_entities.dart';

void main() {
  group('Note entity', () {
    test('copyWith preserves unchanged fields', () {
      final note = Note(
        id: '1',
        title: 'Title',
        body: 'Body',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
        syncStatus: SyncStatus.pending,
      );

      final updated = note.copyWith(title: 'Updated');

      expect(updated.title, 'Updated');
      expect(updated.body, 'Body');
      expect(updated.syncStatus, SyncStatus.pending);
    });
  });

  group('SyncStatus', () {
    test('labels match assignment requirements', () {
      expect(SyncStatus.synced.label, 'Synced');
      expect(SyncStatus.pending.label, 'Pending Sync');
      expect(SyncStatus.conflict.label, 'Conflict');
    });
  });

  group('ConflictResolutionChoice', () {
    test('includes merge option', () {
      expect(
        ConflictResolutionChoice.values,
        contains(ConflictResolutionChoice.merge),
      );
    });
  });
}
