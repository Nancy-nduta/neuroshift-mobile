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

    final delta = psd.integrateBandPower(EegBandFrequencies.deltaMin, EegBandFrequencies.deltaMax);
    final theta = psd.integrateBandPower(EegBandFrequencies.thetaMin, EegBandFrequencies.thetaMax);
    final alpha = psd.integrateBandPower(EegBandFrequencies.alphaMin, EegBandFrequencies.alphaMax);
    final beta = psd.integrateBandPower(EegBandFrequencies.betaMin, EegBandFrequencies.betaMax);
    final gamma = psd.integrateBandPower(EegBandFrequencies.gammaMin, EegBandFrequencies.gammaMax);

    final totalPower = delta + theta + alpha + beta + gamma;

    // Muse 2 MindState evaluation:
    // Calm: Elevated relative Alpha + Theta, low Beta.
    // Active: Elevated relative Beta + Gamma.
    // Neutral: Balanced cognitive baseline.
    MindState state = MindState.neutral;
    if (totalPower > 0.0001) {
      final alphaRel = alpha / totalPower;
      final betaRel = beta / totalPower;
      final thetaRel = theta / totalPower;

      if ((alphaRel + thetaRel * 0.5) > 0.45 && betaRel < 0.25) {
        state = MindState.calm;
      } else if (betaRel > 0.35 || (betaRel + (gamma / totalPower)) > 0.45) {
        state = MindState.active;
      } else {
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
