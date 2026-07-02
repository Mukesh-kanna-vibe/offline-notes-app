import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:offline_notes/core/network/network_info.dart';
import 'package:offline_notes/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:offline_notes/features/notes/data/datasources/notes_remote_datasource.dart';
import 'package:offline_notes/features/notes/data/datasources/sync_queue_local_datasource.dart';
import 'package:offline_notes/features/notes/data/models/note_model.dart';
import 'package:offline_notes/features/notes/data/repositories/notes_repository_impl.dart';
import 'package:offline_notes/features/notes/domain/entities/note_entities.dart';

class MockNotesLocalDataSource extends Mock implements NotesLocalDataSource {}

class MockSyncQueueLocalDataSource extends Mock
    implements SyncQueueLocalDataSource {}

class MockNotesRemoteDataSource extends Mock implements NotesRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockNotesLocalDataSource localDataSource;
  late MockSyncQueueLocalDataSource syncQueueDataSource;
  late MockNotesRemoteDataSource remoteDataSource;
  late MockNetworkInfo networkInfo;
  late NotesRepositoryImpl repository;

  const noteId = 'local-1';
  const serverId = 'server-1';

  final fallbackNote = NoteModel(
    id: 'fallback',
    title: 'Fallback',
    body: 'Fallback',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    syncStatus: SyncStatus.pending,
  );

  setUpAll(() {
    registerFallbackValue(fallbackNote);
  });

  setUp(() {
    localDataSource = MockNotesLocalDataSource();
    syncQueueDataSource = MockSyncQueueLocalDataSource();
    remoteDataSource = MockNotesRemoteDataSource();
    networkInfo = MockNetworkInfo();

    repository = NotesRepositoryImpl(
      localDataSource: localDataSource,
      syncQueueDataSource: syncQueueDataSource,
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
    );

    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => remoteDataSource.fetchNotes()).thenAnswer((_) async => []);
  });

  group('syncNotes conflict detection', () {
    test(
      'marks conflict and skips upload when local and remote changed after last sync',
      () async {
        final lastSyncedAt = DateTime.utc(2026, 1, 10, 9);
        final localPending = NoteModel(
          id: noteId,
          title: 'Local title',
          body: 'Local body',
          createdAt: DateTime.utc(2026, 1, 1, 9),
          updatedAt: DateTime.utc(2026, 1, 12, 9),
          syncStatus: SyncStatus.pending,
          remoteUpdatedAt: lastSyncedAt,
          serverId: serverId,
          syncBaseTitle: 'Original title',
          syncBaseBody: 'Original body',
        );
        final remoteLatest = NoteModel(
          id: serverId,
          title: 'Remote title',
          body: 'Remote body',
          createdAt: DateTime.utc(2026, 1, 1, 9),
          updatedAt: DateTime.utc(2026, 1, 11, 9),
          syncStatus: SyncStatus.synced,
          remoteUpdatedAt: DateTime.utc(2026, 1, 11, 9),
          serverId: serverId,
        );
        final queueItem = SyncQueueItemModel(
          id: 'queue-1',
          noteId: noteId,
          operationType: OperationType.update,
          payload: localPending.toRemoteJson(apiId: serverId),
          retryCount: 0,
          createdAt: DateTime.utc(2026, 1, 12, 9),
        );

        var queueReads = 0;
        when(() => syncQueueDataSource.getPendingOperations()).thenAnswer((_) async {
          queueReads++;
          return queueReads == 1 ? [queueItem] : [];
        });
        when(() => localDataSource.getNoteById(noteId))
            .thenAnswer((_) async => localPending);
        when(() => remoteDataSource.fetchNoteById(serverId))
            .thenAnswer((_) async => remoteLatest);
        when(() => localDataSource.updateNote(any()))
            .thenAnswer((_) async {});
        when(() => syncQueueDataSource.removeById(queueItem.id))
            .thenAnswer((_) async {});
        when(() => syncQueueDataSource.removeByNoteId(noteId))
            .thenAnswer((_) async {});

        await repository.syncNotes();

        verify(() => remoteDataSource.fetchNoteById(serverId)).called(2);
        verifyNever(() => remoteDataSource.fetchNotes());
        verifyNever(
          () => remoteDataSource.updateNote(localPending, apiId: serverId),
        );

        final captured =
            verify(() => localDataSource.updateNote(captureAny())).captured.single
                as NoteModel;
        expect(captured.syncStatus, SyncStatus.conflict);
        expect(captured.conflictLocalTitle, localPending.title);
        expect(captured.conflictLocalBody, localPending.body);
        expect(captured.conflictLocalUpdatedAt, localPending.updatedAt);
        expect(captured.conflictRemoteTitle, remoteLatest.title);
        expect(captured.conflictRemoteBody, remoteLatest.body);
        expect(captured.conflictRemoteUpdatedAt, remoteLatest.updatedAt);

        verify(() => syncQueueDataSource.removeById(queueItem.id)).called(1);
      },
    );

    test('uploads automatically when remote has not changed since last sync', () async {
      final lastSyncedAt = DateTime.utc(2026, 2, 10, 9);
      final localPending = NoteModel(
        id: noteId,
        title: 'Local title',
        body: 'Local body',
        createdAt: DateTime.utc(2026, 2, 1, 9),
        updatedAt: DateTime.utc(2026, 2, 11, 9),
        syncStatus: SyncStatus.pending,
        remoteUpdatedAt: lastSyncedAt,
        serverId: serverId,
        syncBaseTitle: 'Old remote title',
        syncBaseBody: 'Old remote body',
      );
      final remoteLatest = NoteModel(
        id: serverId,
        title: 'Old remote title',
        body: 'Old remote body',
        createdAt: DateTime.utc(2026, 2, 1, 9),
        updatedAt: lastSyncedAt,
        syncStatus: SyncStatus.synced,
        remoteUpdatedAt: lastSyncedAt,
        serverId: serverId,
      );
      final remoteUpdated = NoteModel(
        id: serverId,
        title: localPending.title,
        body: localPending.body,
        createdAt: localPending.createdAt,
        updatedAt: DateTime.utc(2026, 2, 11, 10),
        syncStatus: SyncStatus.synced,
        remoteUpdatedAt: DateTime.utc(2026, 2, 11, 10),
        serverId: serverId,
      );
      final queueItem = SyncQueueItemModel(
        id: 'queue-2',
        noteId: noteId,
        operationType: OperationType.update,
        payload: localPending.toRemoteJson(apiId: serverId),
        retryCount: 0,
        createdAt: DateTime.utc(2026, 2, 11, 9),
      );

      var queueReads = 0;
      when(() => syncQueueDataSource.getPendingOperations()).thenAnswer((_) async {
        queueReads++;
        return queueReads == 1 ? [queueItem] : [];
      });
      when(() => localDataSource.getNoteById(noteId))
          .thenAnswer((_) async => localPending);
      when(() => remoteDataSource.fetchNoteById(serverId))
          .thenAnswer((_) async => remoteLatest);
      when(
        () => remoteDataSource.updateNote(localPending, apiId: serverId),
      ).thenAnswer((_) async => remoteUpdated);
      when(() => localDataSource.updateNote(any()))
          .thenAnswer((_) async {});
        when(() => syncQueueDataSource.removeById(queueItem.id))
            .thenAnswer((_) async {});
        when(() => syncQueueDataSource.removeByNoteId(noteId))
            .thenAnswer((_) async {});

        await repository.syncNotes();

        verify(() => remoteDataSource.fetchNoteById(serverId)).called(1);
      verify(
        () => remoteDataSource.updateNote(localPending, apiId: serverId),
      ).called(1);

      final captured =
          verify(() => localDataSource.updateNote(captureAny())).captured.single
              as NoteModel;
      expect(captured.syncStatus, SyncStatus.synced);
      expect(captured.remoteUpdatedAt, remoteUpdated.updatedAt);
      expect(captured.serverId, serverId);
    });

    test(
      'uses timestamp fallback when sync baseline matches local pending content',
      () async {
        final lastSyncedAt = DateTime.utc(2026, 4, 1, 9);
        final localPending = NoteModel(
          id: noteId,
          title: 'Mobile title',
          body: 'Mobile body',
          createdAt: DateTime.utc(2026, 4, 1, 8),
          updatedAt: DateTime.utc(2026, 4, 2, 9),
          syncStatus: SyncStatus.pending,
          remoteUpdatedAt: lastSyncedAt,
          serverId: serverId,
          syncBaseTitle: 'Mobile title',
          syncBaseBody: 'Mobile body',
        );
        final remoteLatest = NoteModel(
          id: serverId,
          title: 'MockAPI title',
          body: 'MockAPI body',
          createdAt: localPending.createdAt,
          updatedAt: DateTime.utc(2026, 4, 2, 8),
          syncStatus: SyncStatus.synced,
          remoteUpdatedAt: DateTime.utc(2026, 4, 2, 8),
          serverId: serverId,
        );
        final queueItem = SyncQueueItemModel(
          id: 'queue-4',
          noteId: noteId,
          operationType: OperationType.update,
          payload: localPending.toRemoteJson(apiId: serverId),
          retryCount: 0,
          createdAt: DateTime.utc(2026, 4, 2, 9),
        );

        var queueReads = 0;
        when(() => syncQueueDataSource.getPendingOperations()).thenAnswer((_) async {
          queueReads++;
          return queueReads == 1 ? [queueItem] : [];
        });
        when(() => localDataSource.getNoteById(noteId))
            .thenAnswer((_) async => localPending);
        when(() => remoteDataSource.fetchNoteById(serverId))
            .thenAnswer((_) async => remoteLatest);
        when(() => localDataSource.updateNote(any()))
            .thenAnswer((_) async {});
        when(() => syncQueueDataSource.removeById(queueItem.id))
            .thenAnswer((_) async {});
        when(() => syncQueueDataSource.removeByNoteId(noteId))
            .thenAnswer((_) async {});

        await repository.syncNotes();

        verify(() => remoteDataSource.fetchNoteById(serverId)).called(2);
        verifyNever(() => remoteDataSource.fetchNotes());

        final captured = verify(() => localDataSource.updateNote(captureAny()))
            .captured
            .cast<NoteModel>()
            .where((note) => note.syncStatus == SyncStatus.conflict)
            .toList();
        expect(captured, isNotEmpty);
      },
    );
  });

  group('resolveConflict', () {
    test('keep local force-pushes to server and marks note synced', () async {
      final conflictNote = NoteModel(
        id: noteId,
        title: 'Local title',
        body: 'Local body',
        createdAt: DateTime.utc(2026, 5, 1, 8),
        updatedAt: DateTime.utc(2026, 5, 2, 9),
        syncStatus: SyncStatus.conflict,
        remoteUpdatedAt: DateTime.utc(2026, 5, 1, 9),
        serverId: serverId,
        conflictLocalTitle: 'Local title',
        conflictLocalBody: 'Local body',
        conflictLocalUpdatedAt: DateTime.utc(2026, 5, 2, 9),
        conflictRemoteTitle: 'Remote title',
        conflictRemoteBody: 'Remote body',
        conflictRemoteUpdatedAt: DateTime.utc(2026, 5, 2, 8),
      );
      final remoteUpdated = NoteModel(
        id: serverId,
        title: conflictNote.title,
        body: conflictNote.body,
        createdAt: conflictNote.createdAt,
        updatedAt: DateTime.utc(2026, 5, 2, 10),
        syncStatus: SyncStatus.synced,
        remoteUpdatedAt: DateTime.utc(2026, 5, 2, 10),
        serverId: serverId,
      );

      var stored = conflictNote;
      when(() => localDataSource.getNoteById(noteId))
          .thenAnswer((_) async => stored);
      when(() => syncQueueDataSource.removeByNoteId(noteId))
          .thenAnswer((_) async {});
      when(
        () => remoteDataSource.updateNote(any(), apiId: serverId),
      ).thenAnswer((_) async => remoteUpdated);
      when(() => localDataSource.updateNote(any())).thenAnswer((invocation) async {
        stored = invocation.positionalArguments[0] as NoteModel;
      });

      final result = await repository.resolveConflict(
        noteId: noteId,
        choice: ConflictResolutionChoice.keepLocal,
      );

      verifyNever(() => remoteDataSource.fetchNoteById(serverId));
      verify(
        () => remoteDataSource.updateNote(any(), apiId: serverId),
      ).called(1);
      verify(() => syncQueueDataSource.removeByNoteId(noteId)).called(1);

      expect(stored.syncStatus, SyncStatus.synced);
      expect(stored.conflictLocalTitle, isNull);
      expect(stored.remoteUpdatedAt, remoteUpdated.updatedAt);
      expect(result.syncStatus, SyncStatus.synced);
      expect(result.title, 'Local title');
    });

    test('loads conflict details from server when snapshots are missing', () async {
      final conflictNote = NoteModel(
        id: noteId,
        title: 'Local title',
        body: 'Local body',
        createdAt: DateTime.utc(2026, 6, 1, 8),
        updatedAt: DateTime.utc(2026, 6, 2, 9),
        syncStatus: SyncStatus.conflict,
        remoteUpdatedAt: DateTime.utc(2026, 6, 1, 9),
        serverId: serverId,
      );
      final remoteLatest = NoteModel(
        id: serverId,
        title: 'Remote title',
        body: 'Remote body',
        createdAt: conflictNote.createdAt,
        updatedAt: DateTime.utc(2026, 6, 2, 8),
        syncStatus: SyncStatus.synced,
        remoteUpdatedAt: DateTime.utc(2026, 6, 2, 8),
        serverId: serverId,
      );

      when(() => localDataSource.getNoteById(noteId))
          .thenAnswer((_) async => conflictNote);
      when(() => remoteDataSource.fetchNoteById(serverId))
          .thenAnswer((_) async => remoteLatest);
      when(() => localDataSource.updateNote(any())).thenAnswer((_) async {});
      when(() => syncQueueDataSource.removeByNoteId(noteId))
          .thenAnswer((_) async {});

      final result = await repository.getConflict(noteId);

      expect(result, isNotNull);
      expect(result!.localNote.title, 'Local title');
      expect(result.remoteNote.title, 'Remote title');
      verify(() => remoteDataSource.fetchNoteById(serverId)).called(1);
    });
  });
}
