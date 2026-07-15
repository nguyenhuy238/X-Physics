import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around `connectivity_plus` so the rest of the offline
/// module depends on a small interface instead of the package directly.
///
/// `checkConnectivity()` / `onConnectivityChanged` only report the type of
/// network interface (wifi/mobile/none); they do not guarantee real
/// internet reachability. That is an accepted simplification for this MVP.
///
/// Every call here is defensive on purpose: in `flutter_test` widget tests
/// there is no platform channel implementation for `connectivity_plus`, and
/// `AppState` (which uses this class) is constructed in dozens of existing
/// tests via `FakeAppState`. A `MissingPluginException` here must never
/// crash those tests, so failures are swallowed and treated as "online" —
/// the same as if this feature did not exist.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> isOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _hasConnection(results);
    } catch (_) {
      return true;
    }
  }

  /// Emits `true`/`false` on every connectivity transition. Errors from the
  /// underlying platform channel (e.g. missing plugin in tests) are
  /// swallowed rather than propagated, so the stream simply stays idle
  /// instead of crashing listeners.
  Stream<bool> get onStatusChange => _connectivity.onConnectivityChanged
      .map(_hasConnection)
      .handleError((Object error, StackTrace stackTrace) {});

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
