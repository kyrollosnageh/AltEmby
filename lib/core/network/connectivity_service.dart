import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { wifi, mobile, ethernet, none }

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<NetworkStatus> get statusStream =>
      _connectivity.onConnectivityChanged.map(_mapResults);

  Future<NetworkStatus> get currentStatus async {
    final results = await _connectivity.checkConnectivity();
    return _mapResults(results);
  }

  NetworkStatus _mapResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return NetworkStatus.wifi;
    if (results.contains(ConnectivityResult.ethernet)) return NetworkStatus.ethernet;
    if (results.contains(ConnectivityResult.mobile)) return NetworkStatus.mobile;
    return NetworkStatus.none;
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});
