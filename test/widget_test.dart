import 'package:flutter_test/flutter_test.dart';

import 'package:offline_notes/data/database_helper.dart';
import 'package:offline_notes/data/notes_local_datasource.dart';
import 'package:offline_notes/main.dart';
import 'package:offline_notes/repositories/notes_repository.dart';
import 'package:offline_notes/services/api_service.dart';
import 'package:offline_notes/services/connectivity_service.dart';
import 'package:offline_notes/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows offline notes title', (WidgetTester tester) async {
    final repository = NotesRepository(
      NotesLocalDataSource(DatabaseHelper.instance),
    );
    final syncService = SyncService(
      repository: repository,
      apiService: ApiService(),
      connectivityService: ConnectivityService(),
    );

    await tester.pumpWidget(
      OfflineNotesApp(
        repository: repository,
        syncService: syncService,
        connectivityService: ConnectivityService(),
      ),
    );

    await tester.pump();

    expect(find.text('Offline Notes'), findsOneWidget);
  });
}
