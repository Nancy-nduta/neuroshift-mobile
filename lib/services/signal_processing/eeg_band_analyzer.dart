import 'dart:math' as math;

import '../../models/signal_reading.dart';
import 'dft_processor.dart';

class EegBandFrequencies {
  static const double deltaMin = 0.5;
  static const double deltaMax = 4.0;

  static const double thetaMin = 4.0;
  static const double thetaMax = 8.0;

  static const double alphaMin = 8.0;
  static const double alphaMax = 13.0;

  static const double betaMin = 13.0;
  static const double betaMax = 30.0;

  static const double gammaMin = 30.0;
  static const double gammaMax = 45.0;
}

class BandPowers {
  final double delta;
  final double theta;
  final double alpha;
  final double beta;
  final double gamma;
  final double totalPower;
  final MindState state;

  const BandPowers({
    required this.delta,
    required this.theta,
    required this.alpha,
    required this.beta,
    required this.gamma,
    required this.totalPower,
    required this.state,
  });
}

class EegBandAnalyzer {
  final DftProcessor _dftProcessor;
  final double defaultSamplingRate;
  final int minWindowSamples;

  const EegBandAnalyzer({
    DftProcessor? dftProcessor,
    this.defaultSamplingRate = 256.0,
    this.minWindowSamples = 128,
  }) : _dftProcessor = dftProcessor ?? const DftProcessor();

  BandPowers? analyzeWindow(List<double> samples, {double? samplingRate}) {
    final effectiveSamplingRate = samplingRate ?? defaultSamplingRate;
    if (samples.length < minWindowSamples || effectiveSamplingRate <= 0) {
      return null;
    }

    final psd = _dftProcessor.computePsd(
      signal: samples,
      samplingRate: effectiveSamplingRate,
      applyHannWindow: true,
    );

    final rawDelta = psd.integrateBandPower(EegBandFrequencies.deltaMin, EegBandFrequencies.deltaMax);
    final rawTheta = psd.integrateBandPower(EegBandFrequencies.thetaMin, EegBandFrequencies.thetaMax);
    final rawAlpha = psd.integrateBandPower(EegBandFrequencies.alphaMin, EegBandFrequencies.alphaMax);
    final rawBeta = psd.integrateBandPower(EegBandFrequencies.betaMin, EegBandFrequencies.betaMax);
    final rawGamma = psd.integrateBandPower(EegBandFrequencies.gammaMin, EegBandFrequencies.gammaMax);

    // Convert spectral power density to physical RMS microvolt amplitudes (µV_RMS)
    final delta = math.sqrt(math.max(0.0, rawDelta));
    final theta = math.sqrt(math.max(0.0, rawTheta));
    final alpha = math.sqrt(math.max(0.0, rawAlpha));
    final beta = math.sqrt(math.max(0.0, rawBeta));
    final gamma = math.sqrt(math.max(0.0, rawGamma));

    final totalPower = delta + theta + alpha + beta + gamma;

    // Authentic Muse 2 Neurofeedback MindState Classification:
    // Focuses on the active cognitive band (4–30 Hz: Theta + Alpha + Beta)
    // to prevent slow ocular drift / delta DC baseline from masking alpha surges.
    final cognitivePower = theta + alpha + beta;
    MindState state = MindState.neutral;

    if (cognitivePower > 0.001) {
      final alphaRatio = alpha / (beta + 0.0001);
      final alphaRel = alpha / cognitivePower;
      final betaRel = beta / cognitivePower;

      // Calm: Alpha rhythm dominance over beta (parasympathetic relaxation / eyes closed)
      if (alphaRatio >= 1.15 || (alphaRel >= 0.40 && betaRel <= 0.32)) {
        state = MindState.calm;
      }
      // Active: Beta rhythm dominance over alpha (active thinking / restlessness / stress)
      else if (alphaRatio <= 0.85 || (betaRel >= 0.38 && alphaRel <= 0.32)) {
        state = MindState.active;
      }
      // Neutral: Calm alertness / balanced baseline
      else {
        state = MindState.neutral;
      }
    }

    return BandPowers(
      delta: delta,
      theta: theta,
      alpha: alpha,
      beta: beta,
      gamma: gamma,
      totalPower: totalPower,
      state: state,
    );
  }
}
