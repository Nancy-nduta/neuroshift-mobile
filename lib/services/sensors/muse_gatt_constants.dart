/// Bluetooth Low Energy (BLE) GATT UUID definitions for InteraXon Muse 2 headbands.
abstract final class MuseGattConstants {
  /// Primary Muse 2 GATT Service UUID.
  static const String serviceUuid = '0000fe8d-0000-1000-8000-00805f9b34fb';

  /// Serial control command write/notify characteristic.
  static const String controlCharUuid = '273e0001-4c4d-454d-96be-f03bac821358';

  // ==================== EEG CHARACTERISTICS ====================
  /// Left ear mastoid EEG electrode (TP9).
  static const String eegTp9Uuid = '273e0003-4c4d-454d-96be-f03bac821358';

  /// Left forehead EEG electrode (AF7).
  static const String eegAf7Uuid = '273e0004-4c4d-454d-96be-f03bac821358';

  /// Right forehead EEG electrode (AF8).
  static const String eegAf8Uuid = '273e0005-4c4d-454d-96be-f03bac821358';

  /// Right ear mastoid EEG electrode (TP10).
  static const String eegTp10Uuid = '273e0006-4c4d-454d-96be-f03bac821358';

  /// Auxiliary channel (Right AUX).
  static const String eegRightAuxUuid = '273e0007-4c4d-454d-96be-f03bac821358';

  // ==================== PPG OPTICAL CHARACTERISTICS ====================
  /// Ambient light sensor.
  static const String ppgAmbientUuid = '273e000f-4c4d-454d-96be-f03bac821358';

  /// Infrared (IR) photoplethysmography channel (blood pulse).
  static const String ppgIrUuid = '273e0010-4c4d-454d-96be-f03bac821358';

  /// Red photoplethysmography channel.
  static const String ppgRedUuid = '273e0011-4c4d-454d-96be-f03bac821358';

  // ==================== MOTION & STATUS CHARACTERISTICS ====================
  /// Accelerometer (3-axis X, Y, Z head motion).
  static const String accelerometerUuid = '273e000a-4c4d-454d-96be-f03bac821358';

  /// Gyroscope (rotation rate).
  static const String gyroscopeUuid = '273e0009-4c4d-454d-96be-f03bac821358';

  /// Telemetry / Battery status characteristic.
  static const String batteryUuid = '273e000b-4c4d-454d-96be-f03bac821358';

  /// Headband contact fit / horseshoe status indicator characteristic.
  static const String horseshoeStatusUuid = '273e000e-4c4d-454d-96be-f03bac821358';
}
