import 'package:flutter/material.dart';
import '../core/theme/muse_colors.dart';

enum ConnectionStateEnum {
  disconnected,
  scanning,
  connecting,
  connected,
  streaming,
  error,
}

enum FitQuality { good, adjust, poor, none }

extension FitQualityExt on FitQuality {
  Color get color {
    switch (this) {
      case FitQuality.good:
        return MuseColors.fitGood;
      case FitQuality.adjust:
        return MuseColors.fitAdjust;
      case FitQuality.poor:
        return MuseColors.fitPoor;
      case FitQuality.none:
        return MuseColors.fitDisconnected;
    }
  }

  String get label {
    switch (this) {
      case FitQuality.good:
        return 'Solid Fit';
      case FitQuality.adjust:
        return 'Adjust Fit';
      case FitQuality.poor:
        return 'Poor Fit';
      case FitQuality.none:
        return 'Disconnected';
    }
  }
}

class HorseshoeFit {
  final FitQuality tp9;  // Left Ear Mastoid
  final FitQuality af7;  // Left Forehead (EEG)
  final FitQuality fpz;  // Center Forehead (Reference EEG & Optical Pulse/PPG)
  final FitQuality af8;  // Right Forehead (EEG)
  final FitQuality tp10; // Right Ear Mastoid
  final double stabilityScore; // 0.0 to 1.0 (0% to 100%)
  final bool isStable;

  const HorseshoeFit({
    this.tp9 = FitQuality.none,
    this.af7 = FitQuality.none,
    this.fpz = FitQuality.none,
    this.af8 = FitQuality.none,
    this.tp10 = FitQuality.none,
    this.stabilityScore = 0.0,
    this.isStable = false,
  });

  /// All 5 physical Muse 2 sensors make solid contact with skin (all green).
  bool get isAllGood =>
      tp9 == FitQuality.good &&
      af7 == FitQuality.good &&
      fpz == FitQuality.good &&
      af8 == FitQuality.good &&
      tp10 == FitQuality.good;

  /// Ready to record clean, artifact-free EEG and PPG readings once all sensors
  /// have maintained a solid green fit and stabilized continuously.
  bool get isReadyForSession => isAllGood && isStable;

  /// Combined fit percentage across the 5 Muse 2 sensors (20% each).
  double get overallFitPercentage {
    int score = 0;
    for (final q in [tp9, af7, fpz, af8, tp10]) {
      if (q == FitQuality.good) score += 20;
      if (q == FitQuality.adjust) score += 10;
    }
    return score.toDouble();
  }

  HorseshoeFit copyWith({
    FitQuality? tp9,
    FitQuality? af7,
    FitQuality? fpz,
    FitQuality? af8,
    FitQuality? tp10,
    double? stabilityScore,
    bool? isStable,
  }) {
    return HorseshoeFit(
      tp9: tp9 ?? this.tp9,
      af7: af7 ?? this.af7,
      fpz: fpz ?? this.fpz,
      af8: af8 ?? this.af8,
      tp10: tp10 ?? this.tp10,
      stabilityScore: stabilityScore ?? this.stabilityScore,
      isStable: isStable ?? this.isStable,
    );
  }
}

class HeadbandStatus {
  final ConnectionStateEnum connectionState;
  final String? deviceName;
  final String? deviceId;
  final int? batteryPercent;
  final HorseshoeFit fit;
  final String? errorMessage;
  final int packetsReceived;
  final int? heartRateBpm;
  final double stillnessScore;

  const HeadbandStatus({
    this.connectionState = ConnectionStateEnum.disconnected,
    this.deviceName,
    this.deviceId,
    this.batteryPercent,
    this.fit = const HorseshoeFit(),
    this.errorMessage,
    this.packetsReceived = 0,
    this.heartRateBpm,
    this.stillnessScore = 100.0,
  });

  bool get isConnected =>
      connectionState == ConnectionStateEnum.connected ||
      connectionState == ConnectionStateEnum.streaming;

  bool get isStreaming => connectionState == ConnectionStateEnum.streaming;

  HeadbandStatus copyWith({
    ConnectionStateEnum? connectionState,
    String? deviceName,
    String? deviceId,
    int? batteryPercent,
    HorseshoeFit? fit,
    String? errorMessage,
    int? packetsReceived,
    int? heartRateBpm,
    double? stillnessScore,
  }) {
    return HeadbandStatus(
      connectionState: connectionState ?? this.connectionState,
      deviceName: deviceName ?? this.deviceName,
      deviceId: deviceId ?? this.deviceId,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      fit: fit ?? this.fit,
      errorMessage: errorMessage ?? this.errorMessage,
      packetsReceived: packetsReceived ?? this.packetsReceived,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      stillnessScore: stillnessScore ?? this.stillnessScore,
    );
  }
}
