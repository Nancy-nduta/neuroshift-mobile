enum MindState { calm, neutral, active }

class SignalReading {
  final double delta;
  final double theta;
  final double alpha;
  final double beta;
  final double gamma;

  final int? heartRateBpm;
  final double? hrvRmssd;
  final double stillnessScore; // 0 to 100%
  final MindState mindState;
  final int calmPoints; // Birds / reward moments accumulated
  final DateTime timestamp;

  const SignalReading({
    this.delta = 0.0,
    this.theta = 0.0,
    this.alpha = 0.0,
    this.beta = 0.0,
    this.gamma = 0.0,
    this.heartRateBpm,
    this.hrvRmssd,
    this.stillnessScore = 100.0,
    this.mindState = MindState.neutral,
    this.calmPoints = 0,
    required this.timestamp,
  });

  /// Factory for an empty reading before signal influx begins
  factory SignalReading.idle([DateTime? now]) {
    return SignalReading(
      timestamp: now ?? DateTime.now(),
      stillnessScore: 100.0,
      mindState: MindState.neutral,
    );
  }
}
