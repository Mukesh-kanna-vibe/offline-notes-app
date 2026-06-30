import 'dart:io';

class ApiConfig {
  /// Emulator default: `10.0.2.2`. Physical device: pass your Mac's LAN IP via
  /// `--dart-define=API_HOST=10.80.48.31`
  static const String _host = String.fromEnvironment(
    'API_HOST',
    defaultValue: '10.0.2.2',
  );

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://$_host:3000';
    }
    return 'http://localhost:3000';
  }

  static String get notesEndpoint => '$baseUrl/notes';
}
