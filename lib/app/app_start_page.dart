import 'package:flutter/material.dart';

import '../core/storage/onboarding_storage.dart';
import '../features/notes/presentation/pages/notes_list_page.dart';
import '../features/onboarding/presentation/pages/landing_page.dart';
import 'theme/app_theme.dart';

class AppStartPage extends StatefulWidget {
  const AppStartPage({super.key});

  @override
  State<AppStartPage> createState() => _AppStartPageState();
}

class _AppStartPageState extends State<AppStartPage> {
  bool? _hasCompletedLanding;

  @override
  void initState() {
    super.initState();
    _loadLandingState();
  }

  Future<void> _loadLandingState() async {
    final completed = await OnboardingStorage.hasCompletedFirstLaunch();
    if (mounted) {
      setState(() => _hasCompletedLanding = completed);
    }
  }

  Future<void> _completeLanding() async {
    await OnboardingStorage.markFirstLaunchComplete();
    if (mounted) {
      setState(() => _hasCompletedLanding = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasCompletedLanding == null) {
      return const Scaffold(
        backgroundColor: AppTheme.pageBackground,
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.inkMuted,
            ),
          ),
        ),
      );
    }

    if (!_hasCompletedLanding!) {
      return LandingPage(onGetStarted: _completeLanding);
    }

    return const NotesListPage();
  }
}
