import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di/app_dependencies.dart';
import 'features/notes/presentation/bloc/notes_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final AppDependencies dependencies;

  dependencies = await AppDependencies.initialize(
    onSyncCompleted: () {
      dependencies.notesBloc.add(const NotesListReloaded());
    },
  );

  runApp(OfflineNotesApp(dependencies: dependencies));
}
