import 'package:flutter/material.dart';

import 'app_start_page.dart';
import 'di/app_dependencies.dart';
import 'theme/app_theme.dart';

class OfflineNotesApp extends StatelessWidget {
  const OfflineNotesApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: dependencies,
      child: AppBlocProvider(
        dependencies: dependencies,
        child: MaterialApp(
          title: 'Notes',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.light,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const AppStartPage(),
        ),
      ),
    );
  }
}
