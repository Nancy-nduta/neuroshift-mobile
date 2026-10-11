import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:neuroshift_mobile/models/sensor_status.dart';
import 'package:neuroshift_mobile/models/signal_reading.dart';
import 'package:neuroshift_mobile/services/signal_processing/dft_processor.dart';
import 'package:neuroshift_mobile/services/signal_processing/eeg_band_analyzer.dart';
import 'package:neuroshift_mobile/services/signal_processing/ppg_heart_rate_estimator.dart';

void main() {
  group('DFT & EEG Band Processing Tests', () {
    test('Calculates PSD correctly on 10 Hz synthetic sine wave (Alpha band)', () {
      const samplingRate = 256.0;
      const numSamples = 256;
      final signal = List<double>.generate(numSamples, (i) {
        final t = i / samplingRate;
        return 50.0 * math.sin(2.0 * math.pi * 10.0 * t); // 10 Hz Alpha
      });

      const dft = DftProcessor();
      final psd = dft.computePsd(signal: signal, samplingRate: samplingRate);

      final alphaPower = psd.integrateBandPower(8.0, 13.0);
      final betaPower = psd.integrateBandPower(13.0, 30.0);

      expect(alphaPower, greaterThan(betaPower));
      expect(alphaPower, greaterThan(100.0));
    });

    test('EegBandAnalyzer classifies dominant alpha as Calm mind state', () {
      const samplingRate = 256.0;
      final alphaSignal = List<double>.generate(256, (i) {
        final t = i / samplingRate;
        return 40.0 * math.sin(2.0 * math.pi * 10.0 * t); // 10 Hz pure alpha
      });

      const analyzer = EegBandAnalyzer();
      final result = analyzer.analyzeWindow(alphaSignal);

      expect(result, isNotNull);
      expect(result!.state, equals(MindState.calm));
    });
  });

  group('PPG Heart Rate Estimator Tests', () {
    test('Detects pulse peaks from rhythmic optical samples', () {
      final estimator = PpgHeartRateEstimator(samplingRateHz: 64.0);
      final startTime = DateTime.now();

      // Simulate ~60 BPM (1 beat per second = 64 samples per beat)
      HeartMetrics? lastMetrics;
      for (int i = 0; i < 64 * 6; i++) {
        final t = i / 64.0;
        final timestamp = startTime.add(Duration(milliseconds: (t * 1000).toInt()));
        // Synthetic pulse wave + DC baseline
        final pulse = 50000.0 + 1500.0 * math.pow(math.max(0.0, math.sin(2 * math.pi * 1.0 * t)), 8);
        lastMetrics = estimator.processSample(pulse.toDouble(), timestamp);
      }

      expect(lastMetrics, isNotNull);
      expect(lastMetrics!.bpm, isNotNull);
      expect(lastMetrics.bpm!, inInclusiveRange(50, 75));
    });
  });

  group('Horseshoe Fit Model Tests', () {
    test('Computes overall fit percentage properly across 5 Muse 2 sensors', () {
      const fitReady = HorseshoeFit(
        tp9: FitQuality.good,
        af7: FitQuality.good,
        fpz: FitQuality.good,
        af8: FitQuality.good,
        tp10: FitQuality.good,
        stabilityScore: 1.0,
        isStable: true,
      );
      expect(fitReady.overallFitPercentage, equals(100.0));
      expect(fitReady.isAllGood, isTrue);
      expect(fitReady.isReadyForSession, isTrue);

      const fitStabilizing = HorseshoeFit(
        tp9: FitQuality.good,
        af7: FitQuality.good,
        fpz: FitQuality.good,
        af8: FitQuality.good,
        tp10: FitQuality.good,
        stabilityScore: 0.5,
        isStable: false,
      );
      expect(fitStabilizing.isAllGood, isTrue);
      expect(fitStabilizing.isReadyForSession, isFalse);

      const fitPartial = HorseshoeFit(
        tp9: FitQuality.good,
        af7: FitQuality.adjust,
        fpz: FitQuality.adjust,
        af8: FitQuality.none,
        tp10: FitQuality.poor,
      );
      expect(fitPartial.overallFitPercentage, equals(40.0));
      expect(fitPartial.isAllGood, isFalse);
      expect(fitPartial.isReadyForSession, isFalse);
    });
  });
}
