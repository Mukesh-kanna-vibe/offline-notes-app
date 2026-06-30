import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/notes/notes_bloc.dart';
import 'data/database_helper.dart';
import 'data/notes_local_datasource.dart';
import 'repositories/notes_repository.dart';
import 'screens/notes_list_screen.dart';
import 'services/api_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbHelper = DatabaseHelper.instance;
  final localDataSource = NotesLocalDataSource(dbHelper);
  final repository = NotesRepository(localDataSource);
  final apiService = ApiService();
  final connectivityService = ConnectivityService();
  final syncService = SyncService(
    repository: repository,
    apiService: apiService,
    connectivityService: connectivityService,
  );

  runApp(OfflineNotesApp(
    repository: repository,
    syncService: syncService,
    connectivityService: connectivityService,
  ));
}

class OfflineNotesApp extends StatelessWidget {
  const OfflineNotesApp({
    super.key,
    required this.repository,
    required this.syncService,
    required this.connectivityService,
  });

  final NotesRepository repository;
  final SyncService syncService;
  final ConnectivityService connectivityService;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotesBloc(
        repository: repository,
        syncService: syncService,
        connectivityService: connectivityService,
      ),
      child: MaterialApp(
        title: 'Offline Notes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: false),
        ),
        home: const NotesListScreen(),
      ),
    );
  }
}
