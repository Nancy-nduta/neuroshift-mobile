import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPermissionStatus {
  final bool isSupported;
  final bool isBluetoothEnabled;
  final bool hasScanPermission;
  final bool hasConnectPermission;
  final bool hasLocationPermission;
  final String? errorMessage;

  const BluetoothPermissionStatus({
    required this.isSupported,
    required this.isBluetoothEnabled,
    required this.hasScanPermission,
    required this.hasConnectPermission,
    required this.hasLocationPermission,
    this.errorMessage,
  });

  bool get isReady {
    if (!isSupported || !isBluetoothEnabled) return false;
    if (hasScanPermission && hasConnectPermission) return true;
    return hasLocationPermission;
  }
}

class MusePermissionsService {
  Stream<BluetoothAdapterState> get adapterState {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return FlutterBluePlus.adapterState;
      }
    } catch (e) {
      debugPrint('[MusePermissionsService] adapterState stream error: $e');
    }
    return Stream.value(BluetoothAdapterState.on);
  }

  Future<BluetoothPermissionStatus> checkStatus() async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        return const BluetoothPermissionStatus(
          isSupported: true,
          isBluetoothEnabled: true,
          hasScanPermission: true,
          hasConnectPermission: true,
          hasLocationPermission: true,
        );
      }

      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) {
        return const BluetoothPermissionStatus(
          isSupported: false,
          isBluetoothEnabled: false,
          hasScanPermission: false,
          hasConnectPermission: false,
          hasLocationPermission: false,
          errorMessage: 'Bluetooth Low Energy is not supported on this device.',
        );
      }

      BluetoothAdapterState state;
      try {
        state = await FlutterBluePlus.adapterState.first.timeout(
          const Duration(milliseconds: 600),
          onTimeout: () => FlutterBluePlus.adapterStateNow,
        );
      } catch (_) {
        state = FlutterBluePlus.adapterStateNow;
      }
      final isEnabled = state == BluetoothAdapterState.on;

      final scanStatus = await Permission.bluetoothScan.status;
      final connectStatus = await Permission.bluetoothConnect.status;
      final locationStatus = await Permission.locationWhenInUse.status;

      final hasScan = scanStatus.isGranted;
      final hasConnect = connectStatus.isGranted;
      final hasLoc = locationStatus.isGranted;

      String? errorMsg;
      if (!isEnabled) {
        errorMsg = 'Bluetooth is currently turned OFF. Please turn on Bluetooth.';
      } else if (!hasScan || !hasConnect) {
        errorMsg = 'Nearby device permissions are required to connect your Muse 2.';
      }

      return BluetoothPermissionStatus(
        isSupported: isSupported,
        isBluetoothEnabled: isEnabled,
        hasScanPermission: hasScan,
        hasConnectPermission: hasConnect,
        hasLocationPermission: hasLoc,
        errorMessage: errorMsg,
      );
    } catch (e) {
      return const BluetoothPermissionStatus(
        isSupported: true,
        isBluetoothEnabled: true,
        hasScanPermission: true,
        hasConnectPermission: true,
        hasLocationPermission: true,
      );
    }
  }

  Future<BluetoothPermissionStatus> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ].request();
      }
    } catch (_) {}
    return checkStatus();
  }

  Future<void> enableBluetooth() async {
    try {
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      }
    } catch (_) {}
  }

  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
