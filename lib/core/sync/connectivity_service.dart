import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityService {
  Stream<bool> get isOnlineStream;

  Future<bool> get isOnline;
}

class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get isOnlineStream {
    return _connectivity.onConnectivityChanged.map(_hasConnection).distinct();
  }

  @override
  Future<bool> get isOnline async {
    return _hasConnection(await _connectivity.checkConnectivity());
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}

class ManualConnectivityService implements ConnectivityService {
  ManualConnectivityService({bool isOnline = true})
    : _controller = StreamController<bool>.broadcast(),
      _isOnline = isOnline;

  final StreamController<bool> _controller;
  bool _isOnline;

  void setOnline(bool value) {
    if (_isOnline == value) return;
    _isOnline = value;
    _controller.add(value);
  }

  @override
  Stream<bool> get isOnlineStream async* {
    yield _isOnline;
    yield* _controller.stream;
  }

  @override
  Future<bool> get isOnline async => _isOnline;

  Future<void> dispose() async {
    await _controller.close();
  }
}
