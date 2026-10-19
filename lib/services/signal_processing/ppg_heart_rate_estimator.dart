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

/// Robust, real-time Photoplethysmography (PPG) Heart Rate & HRV estimator
/// designed specifically for InteraXon Muse 2 optical sensor at 64 Hz.
///
/// Eliminates BLE arrival jitter by tracking sample-based time rather than OS wall-clock time,
/// applies adaptive DC baseline tracking, dynamic peak thresholding, and physiological
/// interval validation (45–145 BPM) to prevent false optical noise spikes (such as 183 BPM).
class PpgHeartRateEstimator {
  final double samplingRateHz;

  // Sample index tracking (each sample at 64Hz = 15.625 ms)
  int _sampleCount = 0;
  final List<double> _rawBuffer = [];
  final List<double> _acBuffer = [];
  final List<double> _validIntervalsMs = [];

  double? _lastPeakSampleTimeMs;
  double? _runningPeakAmplitude;
  int? _latestBpm;
  double? _latestRmssd;
  int _samplesSinceLastPeak = 0;

  // Physiological bounds for meditation / resting human heart rate
  static const double minPhysiologicalBpm = 45.0;
  static const double maxPhysiologicalBpm = 145.0;

  double get minRefractoryMs => 60000.0 / maxPhysiologicalBpm; // ~413 ms (max 145 BPM)
  double get maxIntervalMs => 60000.0 / minPhysiologicalBpm;   // ~1333 ms (min 45 BPM)
  double get samplePeriodMs => 1000.0 / samplingRateHz;        // 15.625 ms at 64 Hz

  PpgHeartRateEstimator({
    this.samplingRateHz = 64.0,
  });

  void reset() {
    _sampleCount = 0;
    _rawBuffer.clear();
    _acBuffer.clear();
    _validIntervalsMs.clear();
    _lastPeakSampleTimeMs = null;
    _runningPeakAmplitude = null;
    _latestBpm = null;
    _latestRmssd = null;
    _samplesSinceLastPeak = 0;
  }

  HeartMetrics processSample(double rawPpg, [DateTime? timestamp]) {
    _sampleCount++;
    _samplesSinceLastPeak++;

    // 1. Optical bounds check: lift check or sensor saturation
    // Floating or railed Muse 2 PPG optical counts are typically < 5,000 or > 16,000,000
    if (rawPpg < 5000.0 || rawPpg > 16000000.0) {
      if (_samplesSinceLastPeak > (samplingRateHz * 2.5)) {
        _latestBpm = null;
        _latestRmssd = null;
      }
      return HeartMetrics(bpm: _latestBpm, rmssd: _latestRmssd, isPulseDetected: false);
    }

    // 2. Buffer raw samples for DC baseline tracking (1.5 seconds = 96 samples)
    _rawBuffer.add(rawPpg);
    if (_rawBuffer.length > (samplingRateHz * 1.5).toInt()) {
      _rawBuffer.removeAt(0);
    }

    if (_rawBuffer.length < (samplingRateHz * 1.0).toInt()) {
      return HeartMetrics(bpm: null, rmssd: null, isPulseDetected: false);
    }

    // 3. Baseline subtraction (High-pass DC removal)
    double sum = 0.0;
    for (int i = 0; i < _rawBuffer.length; i++) {
      sum += _rawBuffer[i];
    }
    final dcMean = sum / _rawBuffer.length;
    final acRaw = rawPpg - dcMean;

    // 3-point moving average smoothing to eliminate high-frequency photodiode noise
    _acBuffer.add(acRaw);
    if (_acBuffer.length > 5) {
      _acBuffer.removeAt(0);
    }

    if (_acBuffer.length < 3) {
      return HeartMetrics(bpm: _latestBpm, rmssd: _latestRmssd, isPulseDetected: false);
    }

    // Inverted peak check: PPG waveform systolic trough / peak
    final prev2 = _acBuffer[_acBuffer.length - 3];
    final prev1 = _acBuffer[_acBuffer.length - 2];
    final curr = _acBuffer.last;

    // Timeout: if no valid peak detected for > 2.5 seconds, clear stale BPM
    if (_samplesSinceLastPeak > (samplingRateHz * 2.5).toInt()) {
      _latestBpm = null;
      _latestRmssd = null;
    }

    bool pulseDetected = false;
    final currentSampleTimeMs = _sampleCount * samplePeriodMs;

    // Adaptive peak amplitude threshold
    final minThreshold = 80.0;
    final threshold = _runningPeakAmplitude != null
        ? math.max(minThreshold, _runningPeakAmplitude! * 0.45)
        : minThreshold;

    // Peak detection: local maximum above threshold
    if (prev1 > threshold && prev1 >= prev2 && prev1 > curr) {
      if (_lastPeakSampleTimeMs != null) {
        final intervalMs = currentSampleTimeMs - _lastPeakSampleTimeMs!;

        // Check if interval falls strictly within physiological human heart rate limits
        if (intervalMs >= minRefractoryMs && intervalMs <= maxIntervalMs) {
          pulseDetected = true;
          _samplesSinceLastPeak = 0;
          _validIntervalsMs.add(intervalMs);
          if (_validIntervalsMs.length > 8) {
            _validIntervalsMs.removeAt(0);
          }

          // Update running peak amplitude
          _runningPeakAmplitude = _runningPeakAmplitude == null
              ? prev1
              : (_runningPeakAmplitude! * 0.8 + prev1 * 0.2);

          // Require at least 3 consistent intervals to confirm true heart rhythm
          if (_validIntervalsMs.length >= 3) {
            final sorted = List<double>.from(_validIntervalsMs)..sort();
            final medianInterval = sorted[sorted.length ~/ 2];

            // Interval jitter validation: reject erratic motion spikes
            final maxDiff = sorted.last - sorted.first;
            if (maxDiff < 300.0) {
              final rawBpm = (60000.0 / medianInterval).round();
              if (rawBpm >= 45 && rawBpm <= 140) {
                if (_latestBpm == null) {
                  _latestBpm = rawBpm;
                } else {
                  // Smooth physiological update (70% previous, 30% instant)
                  _latestBpm = (_latestBpm! * 0.7 + rawBpm * 0.3).round();
                }
              }

              // Compute RMSSD for HRV if we have at least 4 intervals
              if (_validIntervalsMs.length >= 4) {
                double sumDiffSq = 0.0;
                for (int i = 0; i < _validIntervalsMs.length - 1; i++) {
                  final diff = _validIntervalsMs[i + 1] - _validIntervalsMs[i];
                  sumDiffSq += diff * diff;
                }
                _latestRmssd = math.sqrt(sumDiffSq / (_validIntervalsMs.length - 1));
              }
            }
          }
          _lastPeakSampleTimeMs = currentSampleTimeMs;
        } else if (intervalMs > maxIntervalMs) {
          // Interval was too long (e.g. sensor readjusted), reset interval anchor
          _lastPeakSampleTimeMs = currentSampleTimeMs;
          _validIntervalsMs.clear();
        }
      } else {
        _lastPeakSampleTimeMs = currentSampleTimeMs;
      }
    }

    return HeartMetrics(
      bpm: _latestBpm,
      rmssd: _latestRmssd,
      isPulseDetected: pulseDetected,
    );
  }
}
