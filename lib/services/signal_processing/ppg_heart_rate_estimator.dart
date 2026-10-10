import 'dart:math' as math;

class HeartMetrics {
  final int? bpm;
  final double? rmssd;
  final bool isPulseDetected;

  const HeartMetrics({
    this.bpm,
    this.rmssd,
    this.isPulseDetected = false,
  });
}

class PpgHeartRateEstimator {
  final double samplingRateHz;
  final double minBpm;
  final double maxBpm;

  final List<double> _rawBuffer = [];
  final List<double> _acBuffer = [];
  final List<double> _intervalsMs = [];
  DateTime? _lastPeakTime;
  int? _latestBpm;
  double? _latestRmssd;
  double _runningPeakAmplitude = 100.0;

  PpgHeartRateEstimator({
    this.samplingRateHz = 64.0,
    this.minBpm = 40.0,
    this.maxBpm = 200.0,
  });

  int get minRefractoryMs => (60000.0 / maxBpm).round(); // ~300ms
  int get maxIntervalMs => (60000.0 / minBpm).round();   // ~1500ms

  void reset() {
    _rawBuffer.clear();
    _acBuffer.clear();
    _intervalsMs.clear();
    _lastPeakTime = null;
    _latestBpm = null;
    _latestRmssd = null;
    _runningPeakAmplitude = 100.0;
  }

  HeartMetrics processSample(double rawPpg, DateTime timestamp) {
    // Optical bounds: lift check or saturation check
    if (rawPpg < 1000.0 || rawPpg > 16000000.0) {
      return HeartMetrics(bpm: _latestBpm, rmssd: _latestRmssd, isPulseDetected: false);
    }

    _rawBuffer.add(rawPpg);
    if (_rawBuffer.length > (samplingRateHz * 4).toInt()) {
      _rawBuffer.removeAt(0);
    }

    if (_rawBuffer.length < (samplingRateHz * 1.5).toInt()) {
      return HeartMetrics(bpm: null, rmssd: null, isPulseDetected: false);
    }

    // Baseline subtract (DC removal)
    final mean = _rawBuffer.reduce((a, b) => a + b) / _rawBuffer.length;
    final ac = rawPpg - mean;
    _acBuffer.add(ac);
    if (_acBuffer.length > 20) {
      _acBuffer.removeAt(0);
    }

    bool pulseDetected = false;

    // Peak detection with refractory period
    if (_acBuffer.length >= 3) {
      final prev = _acBuffer[_acBuffer.length - 2];
      final current = _acBuffer.last;
      final threshold = math.max(20.0, _runningPeakAmplitude * 0.4);

      if (prev > threshold && prev > current) {
        if (_lastPeakTime != null) {
          final diffMs = timestamp.difference(_lastPeakTime!).inMilliseconds.toDouble();
          if (diffMs >= minRefractoryMs && diffMs <= maxIntervalMs) {
            pulseDetected = true;
            _intervalsMs.add(diffMs);
            if (_intervalsMs.length > 10) {
              _intervalsMs.removeAt(0);
            }

            _runningPeakAmplitude = _runningPeakAmplitude * 0.8 + prev * 0.2;

            // Compute BPM from rolling median/mean of intervals
            final meanInterval = _intervalsMs.reduce((a, b) => a + b) / _intervalsMs.length;
            _latestBpm = (60000.0 / meanInterval).round().clamp(40, 200);

            // Compute RMSSD if we have at least 3 intervals
            if (_intervalsMs.length >= 3) {
              double sumDiffSq = 0.0;
              for (int i = 0; i < _intervalsMs.length - 1; i++) {
                final diff = _intervalsMs[i + 1] - _intervalsMs[i];
                sumDiffSq += diff * diff;
              }
              _latestRmssd = math.sqrt(sumDiffSq / (_intervalsMs.length - 1));
            }
          }
        }
        _lastPeakTime = timestamp;
      }
    }

    return HeartMetrics(
      bpm: _latestBpm,
      rmssd: _latestRmssd,
      isPulseDetected: pulseDetected,
    );
  }
}
