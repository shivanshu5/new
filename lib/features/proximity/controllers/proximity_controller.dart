import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/proximity_service.dart';

final proximityControllerProvider =
    StateNotifierProvider<ProximityController, bool>((ref) {
  return ProximityController(ref.read(proximityServiceProvider));
});

class ProximityController extends StateNotifier<bool> {
  final ProximityService _service;

  ProximityController(this._service) : super(false);

  Future<void> requestPermissionsAndStartScanning(BuildContext context) async {
    // Request all required permissions together
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ].request();

    final allGranted = statuses.values
        .every((s) => s.isGranted || s.isLimited);

    if (!allGranted) {
      state = false;
      if (context.mounted) {
        _showPermissionDeniedBanner(context);
      }
      return;
    }

    await _service.startScanning();
    state = true;

    // Listen for crossed-paths events and surface banner
    _service.onCrossedPaths.listen((name) {
      if (context.mounted) {
        _showCrossedPathsBanner(context, name);
      }
    });
  }

  void stopScanning() {
    _service.stopScanning();
    state = false;
  }

  void _showCrossedPathsBanner(BuildContext context, String name) {
    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(MaterialBanner(
        backgroundColor: Colors.deepPurpleAccent.withOpacity(0.95),
        content: Row(children: [
          const Text('⚡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'You just crossed paths with $name!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('DISMISS', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ));

    Future.delayed(const Duration(seconds: 4), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }

  void _showPermissionDeniedBanner(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Bluetooth & Location permissions required for proximity detection.'),
      duration: Duration(seconds: 4),
    ));
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
