import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_isOnline);
  }

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return _isOnline(result);
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );
  }
}
