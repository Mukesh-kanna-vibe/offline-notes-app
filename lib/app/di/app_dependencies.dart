import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../core/network/network_info.dart';
import '../../features/notes/data/datasources/database_helper.dart';
import '../../features/notes/data/datasources/notes_local_datasource.dart';
import '../../features/notes/data/datasources/notes_remote_datasource.dart';
import '../../features/notes/data/datasources/sync_queue_local_datasource.dart';
import '../../features/notes/data/repositories/notes_repository_impl.dart';
import '../../features/notes/domain/entities/note_entities.dart';
import '../../features/notes/domain/repositories/notes_repository.dart';
import '../../features/notes/presentation/bloc/notes_bloc.dart';
import '../../features/notes/presentation/bloc/notes_event.dart';
import '../../features/notes/presentation/bloc/notes_state.dart';
import '../../services/connectivity_service.dart';

/// Central dependency container for manual constructor injection.
class AppDependencies {
  AppDependencies._({
    required this.notesRepository,
    required this.notesBloc,
    required this.connectivityService,
    required this.networkInfo,
  });

  final NotesRepository notesRepository;
  final NotesBloc notesBloc;
  final ConnectivityService connectivityService;
  final NetworkInfo networkInfo;

  static Future<AppDependencies> initialize({
    void Function()? onSyncCompleted,
  }) async {
    final databaseHelper = DatabaseHelper.instance;

    await databaseHelper.database;

    final apiClient = ApiClient();
    final networkInfo = NetworkInfoImpl(Connectivity());

    final localDataSource = NotesLocalDataSource(databaseHelper);
    final syncQueueDataSource = SyncQueueLocalDataSource(databaseHelper);
    final remoteDataSource = NotesRemoteDataSource(apiClient);

    NotesBloc? notesBlocRef;

    final notesRepository = NotesRepositoryImpl(
      localDataSource: localDataSource,
      syncQueueDataSource: syncQueueDataSource,
      remoteDataSource: remoteDataSource,
      networkInfo: networkInfo,
      onSyncCompleted: () {
        notesBlocRef?.add(const NotesListReloaded());
      },
      onConflictDetected: (noteId) {
        notesBlocRef?.add(ConflictDetected(noteId));
      },
    );

    // Load local notes before UI opens — avoids infinite loading spinner.
    List<Note> initialNotes = [];
    try {
      initialNotes = await notesRepository.getNotes();
    } catch (_) {
      initialNotes = [];
    }
    final initialState = NotesState(
      status: initialNotes.isEmpty ? NotesStatus.empty : NotesStatus.success,
      notes: initialNotes,
    );

    final notesBloc = NotesBloc(
      notesRepository: notesRepository,
      initialState: initialState,
    );
    notesBlocRef = notesBloc;

    final connectivityService = ConnectivityService(
      networkInfo: networkInfo,
      notesRepository: notesRepository,
      onSyncCompleted: onSyncCompleted,
    );

    // Delay sync so UI renders first with local data.
    unawaited(
      Future<void>.delayed(const Duration(seconds: 1), () {
        connectivityService.start();
      }),
    );

    return AppDependencies._(
      notesRepository: notesRepository,
      notesBloc: notesBloc,
      connectivityService: connectivityService,
      networkInfo: networkInfo,
    );
  }

  Future<void> dispose() async {
    await connectivityService.dispose();
    await notesBloc.close();
    await DatabaseHelper.instance.close();
  }
}

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}

class AppBlocProvider extends StatelessWidget {
  const AppBlocProvider({
    super.key,
    required this.dependencies,
    required this.child,
  });

  final AppDependencies dependencies;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotesBloc>.value(
      value: dependencies.notesBloc,
      child: child,
    );
  }
}
