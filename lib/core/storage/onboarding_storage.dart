import 'package:shared_preferences/shared_preferences.dart';

abstract final class OnboardingStorage {
  static const _firstLaunchKey = 'first_launch_completed';

  /// Whether the user has finished onboarding (not first launch).
  static Future<bool> hasCompletedFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ??
        prefs.getBool('landing_completed') ??
        false;
  }

  /// Persists that onboarding was completed — skips on future launches.
  static Future<void> markFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, true);
  }
}
