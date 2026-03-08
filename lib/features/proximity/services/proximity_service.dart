import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';
import '../../../core/constants/app_constants.dart';

final proximityServiceProvider = Provider<ProximityService>((ref) {
  return ProximityService(FirebaseFunctions.instance, FirebaseFirestore.instance);
});

class ProximityService {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  final Map<String, List<int>> _rssiHistory = {};
  final Map<String, DateTime> _lastTriggered = {};

  final _crossedPathsController = StreamController<String>.broadcast();
  Stream<String> get onCrossedPaths => _crossedPathsController.stream;

  StreamSubscription? _scanSubscription;

  ProximityService(this._functions, this._firestore);

  Future<void> startScanning() async {
    if (FlutterBluePlus.isScanningNow) return;

    await FlutterBluePlus.startScan(
      continuousUpdates: true,
      androidScanMode: AndroidScanMode.lowPower,
    );

    _scanSubscription = FlutterBluePlus.scanResults.listen(_onScanResults);
  }

  Future<void> stopScanning() async {
    await _scanSubscription?.cancel();
    await FlutterBluePlus.stopScan();
  }

  void _onScanResults(List<ScanResult> results) {
    for (final r in results) {
      _processResult(r);
    }
  }

  void _processResult(ScanResult result) {
    final deviceId = result.device.remoteId.toString();

    // Maintain sliding RSSI window
    final history = _rssiHistory.putIfAbsent(deviceId, () => []);
    if (history.length >= AppConstants.rssiSmoothingWindow) {
      history.removeAt(0);
    }
    history.add(result.rssi);

    final avgRssi = history.reduce((a, b) => a + b) / history.length;
    final distance = _estimateDistance(avgRssi);

    if (distance <= AppConstants.proximityTriggerMeters) {
      _maybeTrigger(deviceId);
    }
  }

  double _estimateDistance(double rssi) {
    // Log-distance path loss model
    const txPower = AppConstants.txPowerDefault;
    if (rssi == 0) return double.infinity;
    final ratio = rssi / txPower;
    if (ratio < 1.0) return pow(ratio, 10).toDouble();
    return (0.89976) * pow(ratio, 7.7095) + 0.111;
  }

  Future<void> _maybeTrigger(String anonId) async {
    final now = DateTime.now();
    final last = _lastTriggered[anonId];

    if (last != null &&
        now.difference(last).inMinutes < AppConstants.proximityDebounceMinutes) {
      return;
    }

    _lastTriggered[anonId] = now;

    try {
      final callable = _functions.httpsCallable('logProximity');
      final response = await callable.call({'anonId': anonId});

      if (response.data?['status'] == 'match_found') {
        _crossedPathsController.add(response.data['name'] as String);
      }
    } catch (e) {
      // Silent fail - proximity is best-effort
    }
  }

  void dispose() {
    _scanSubscription?.cancel();
    _crossedPathsController.close();
  }
}
